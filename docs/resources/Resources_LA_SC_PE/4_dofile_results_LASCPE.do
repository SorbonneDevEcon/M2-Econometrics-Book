clear mata
capture log close
clear
set more off

********************************************************************************
**************** DO-FILE REPLICATION RESULTS - ATWOOD (2022) *******************
********************************************************************************

*Packages*********
*ssc install estout, replace

**Directories*******
global home "C:\Users\elsap\Dropbox\replication_project_LA_SC_PE\resources" //change to your replication directory HERE

global tables  			"$home/output_replication/tables"
global figures 			"$home/output_replication/figures"  
global data    			"$home/data_replication" 
global logs   	 		"$home/logs_replication"


*Log**************
log using "$logs/Atwood_results_log.txt", replace


**# EVENT STUDY - FIGURE 3******************************************************

use "$data/inc_rate_ES.dta", clear

*create interaction term for year and Measles pre vaccine level in each state
local year "1 2 3 4 5 7 8 9 10 11 12 13 14 15 16 17 18"

foreach i of local year {
    gen exp_Mpre_`i' = _Texp_`i' * avg_12yr_measles_rate
}

*Regression Analysis

reg Measles exp_M* _Is* population _T* avg_12yr_measles_rate,  cluster(statefip) robust


*Saving Regression Output
regsave, ci pval

*Preparing Data for Graphing
*drop the uneeded coefficients and add in the 0s for the omitted year
drop in 18/87

set obs 18
replace var = "exp_Mpre_6" in 18
replace coef = 0 in 18
replace stderr = 0 in 18
replace N = 1108 in 18
replace ci_lower = 0 in 18
replace ci_upper = 0 in 18


*Time Variable Creation for Event Study Plotting

gen exp = .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 {
    local value = `=`i'-7'
    replace exp = `value' if var == "exp_Mpre_`i'"
}
sort exp


*Creating the Event Study Graph

scatter coef ci* exp if exp>-6 & exp<11, 	c(l l l) cmissing(y n n) ///
						msym(i i i) lcolor(gray gray gray) lpatter(solid dash dash) lwidth(thick medthick medthick) ///
						yline(0, lcolor(black)) xline(-1, lcolor(black)) ///
						subtitle("`sub' rate by year (per 100,000)", size(small) j(left) pos(11)) ylabel( , nogrid angle(horizontal) labsize(small)) ///
						xtitle("Years relative to measles vaccine availability", size(small)) xlabel(-5(5)10, labsize(small)) ///
						legend(off) ///
						graphregion(color(white)) 
						
						
graph export "$figures/Figure3_event_study.png", replace	



**# MAIN RESULTS - TABLE 2******************************************************

use "$data/main_dataset_acs_200017.dta", clear

set emptycells drop //drop all empty interactions cells


*****Regressions*********

eststo clear

foreach dep in cpi_incwage cpi_incwage_no0 ln_cpi_income poverty100 employed hrs_worked {

	local controls i.bpl i.birthyr i.ageblackfemale i.bpl_black i.bpl_female i.bpl_black_female black female

	* Run main specification and store results
    reg `dep' M12_exp_rate `controls' i.year, robust cluster(bplcohort)
    eststo col`dep'
	
	*Add outcome means' line
    quietly summarize `dep' if exposure == 0
    local dep_mean = r(mean)
    estadd scalar dep_mean = `dep_mean'
    
    * Store the coefficient of M12_exp_rate
    scalar beta_`dep' = _b[M12_exp_rate]
    
    * Perform calculation with the stored coefficient
    scalar result_`dep' = beta_`dep' * (unweight_avg_12_measles_rate / 100000) * 16
	
	* Add scalars to the eststo model
    estadd scalar unweight_avg_12_measles_rate = unweight_avg_12_measles_rate
    estadd scalar calculated_result = result_`dep'
}


esttab col* using "$tables/Table2_Main_results.tex", keep(M12_exp_rate) b(4) se(4) ///
label stats(r2 N dep_mean unweight_avg_12_measles_rate calculated_result, fmt(4 %9.0fc 4 0 4) ///
labels("R$^2$" "Observations" "Outcome mean for prevaccine cohorts" "Av. 12-y measles prevaccine incidence rate" "Outcome with av. measles incidence rate and full exposure")) replace 



**# ROBUSTNESS CHECKS - TABLE 5 PLACEBO TEST************************************
use "$data/placebo_dataset_acs196070.dta", clear

set emptycells drop

eststo clear

*Regressions loop over the 3 dependent variables:
foreach dep in employed labforcepart edu_years2 {
	local controls i.year rural ruralpost female femalepost blackpost blackfemale 	blackfemalepost i.age i.race i.statefip  famincome famincome2 famincome3

	reg `dep' M_post_rate_scale `controls' , cluster(statefip)
	eststo col`dep'
	
	* Store the coefficient of M_post_rate_scale
    scalar beta_`dep' = _b[M_post_rate_scale]
    
    * Perform calculation of the av. impact with the stored coefficient
    scalar result_`dep' = beta_`dep' * (unweight_avg_12_measles_rate / 100000) 
	
	* Add scalars to the eststo model
    estadd scalar calculated_result = result_`dep'
	}

*Table output:	
esttab col* using "$tables/Table5_placebo.tex", keep(M_post_rate_scale) b(4) se(4)  ///
label stats(r2 N calculated_result, fmt(4 %9.0fc 4) ///
labels("R$^2$" "Observations""Outcome with av. measles incidence rate post-vaccine availability")) replace 


log close