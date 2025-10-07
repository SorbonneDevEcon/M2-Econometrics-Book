*Reference: Dias, Mateus, and Luiz Felipe Fontes. 2024. "The Effects of a Large-Scale Mental Health Reform: Evidence from Brazil." American Economic Journal: Economic Policy, 16 (3): 257–89.

*Link to the article: https://www.aeaweb.org/articles?id=10.1257/pol.20220246

*Link to the original replication package: https://www.openicpsr.org/openicpsr/project/195122/version/V1/view

*Replication file prepared by: Adam Guerfa, Léonie Patin, Juliana Torres Cortes

*Academic year: 2024/2025

*****************************************************************************************************
*									       Replication exercise 	            				    *
*									              Do File 	             	                 		*
*	      Reproducing tables A2, Figure 5 (panel A) and ... (probably we need to chose the most important outcomes)
*****************************************************************************************************

***************************************************************************************
*********   A/ Generate the data from original replication file               *********
***************************************************************************************

*download and save the original dataset "final_dataset.dta" from https://www.openicpsr.org/openicpsr/project/195122/version/V1/view

clear all
set more off

*set directory
cd "/Users/julianatorres/Desktop/M2 EDD/STATA SEMINAR/REPLICATION PROJECT"


*open the dataset
use "final_dataset.dta", clear


***************************************************************************************
*********  A/ Replication do-file for the replication exercise               *********
***************************************************************************************

**GLOBALS
*we set up GLOBALS in order to know where to store our results and where to go to use the dataset we created
global replication "/Users/julianatorres/Desktop/M2 EDD/STATA SEMINAR/REPLICATION PROJECT/data_and_dofiles" 
global results "${replication}/results_replication"
global data_final "${replication}/dataset_replication"
global data_original "${replication}/dataset_original"
global adofile "${replication}/stata-programs"

adopath ++ "${adofile}" 

**PACKAGES FOR ALL REPLICATION PROJECT
ssc install did_multiplegt
ssc install Ftools
ssc install Moremata
ssc install Reghdfe
ssc install Outreg2
ssc install coefplot
ssc install grstyle


*********SETUP*******************
use "${data_final}/dataset_vf", clear 

g caps_implemented = year if caps==1
recode caps_implemented (.=9999)
bys id_muni: egen year_caps_implemented = min(caps_implemented)
drop caps_implemented
tab year_caps_implemented
* we created a variable that gives us the year that a CAPS was implemented for the first time in each municipality 

egen pop_m =rowtotal(pop_m_10to19 pop_m_20to29 pop_m_30to39 pop_m_40to49 pop_m_50to59 pop_m_60to69 pop_m_70to79)
egen pop_f =rowtotal(pop_f_10to19 pop_f_20to29 pop_f_30to39 pop_f_40to49 pop_f_50to59 pop_f_60to69 pop_f_70to79)
egen pop_tot_10to79=rowtotal(pop_m pop_f)


*we created variables for total population of men and women from 10 to 79 years old and the sum of total population of men and women of 10 to 79 years old

g fracpop_m =pop_m/pop_tot_10to79
egen pop_tot_10to19 = rowtotal (pop_f_10to19 pop_m_10to19)
egen pop_tot_40to49 = rowtotal (pop_f_40to49 pop_m_40to49)
egen pop_tot_70to79 = rowtotal (pop_f_70to79 pop_m_70to79)

g fracpop10to19 = pop_tot_10to19/pop_tot_10to79
g fracpop40to49 = pop_tot_40to49/pop_tot_10to79
g fracpop70to79 = pop_tot_70to79/pop_tot_10to79

save "${data_final}/dataset_vf", replace
*----------------------------------------------------------------------------------------------------

** CREATION OF TABLE A2 OF SUMMARY STATISTICS
/* Table A2

Descriptive Statistics — baseline year :2002

*/

matrix Q=J(41,4,.)

* hospital admissions
local i 2
foreach v in ha_by_md ha_schizo2 ha_mood ha_stress ha_substance ha_demencia ha_retardation ha_md{
local i `i'+1
sum `v' if year==2002
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002&year==2002
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999&year==2002
matrix Q[`i',4]=`r(mean)'
}
* mortality
local i `i'+2
foreach v in suicide overdose death_alcohol death_mental_health homicides {
local i `i'+1
sum `v' if year==2002
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002&year==2002
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999&year==2002
matrix Q[`i',4]=`r(mean)'
}

* ambulatory care
local i `i'+2

// procedures
preserve
keep if year_caps_implemented>2009
foreach v in op_by_psychiatrist op_by_psycho op_by_socialwork op_by_therap {
local i `i'+1
sum `v' if year==2008
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002&year==2008
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999&year==2008
matrix Q[`i',4]=`r(mean)'
}
restore

// drugs
foreach v in dispense_antipsychotics{
local i `i'+1
sum `v' if year==2002
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002&year==2002
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999&year==2002
matrix Q[`i',4]=`r(mean)'
}

* providers
local i `i'+2
foreach v in psychiatrist_tot psychologist_tot  socialworker_tot therapist_tot psychiatric_beds{
local i `i'+1
sum `v' if year==2006
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002&year==2006
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999&year==2006
matrix Q[`i',4]=`r(mean)'
}

* Some baseline covariates
local i `i'+2

// N
local i `i'+1
count if year==2010&year_caps_implemented!=2002
matrix Q[`i',2]=`r(N)'
count if year==2010&year_caps_implemented!=9999&year_caps_implemented!=2002
matrix Q[`i',3]=`r(N)'
count if year==2010&year_caps_implemented==9999&year_caps_implemented!=2002
matrix Q[`i',4]=`r(N)'

// Pop size, fraction of pop by gender and age, bolsa familia transfers, and gdp per capita
foreach v in pop_ fracpop_m fracpop10to19 fracpop40to49 fracpop70to79 log_pbf_pc loggdppc {
local i `i'+1
sum `v' 
matrix Q[`i',2]=`r(mean)'
sum `v' if year_caps_implemented!=9999&year_caps_implemented!=2002
matrix Q[`i',3]=`r(mean)'
sum `v' if year_caps_implemented==9999
matrix Q[`i',4]=`r(mean)'
}


* Saving table
clear 
set obs 41
svmat Q, n(main)
keep main*

tostring main1, replace
replace main1 = "" if main1=="."

replace main1 = "Hospitalizations (per 10,000 pop.)" in 2
replace main1 = "Mental and behavioral disorders" in 3
replace main1 = "Schizophrenia" in 4
replace main1 = "Depression/bipolarity" in 5
replace main1 = "Stress-related disorders" in 6
replace main1 = "Psychoactive substance abuse" in 7
replace main1 = "Mental retardation" in 8
replace main1 = "Dementia" in 9
replace main1 = "Others" in 10

replace main1 = "Mortality (per 10,000 pop.)" in 12
replace main1 = "Mental disorders" in 16
replace main1 = "Homicide" in 17
replace main1 = "Suicide" in 13
replace main1 = "Overdose " in 14
replace main1 = "Alcoholic and chronic liver disease " in 15

replace main1 = "Outpatient Care (per 10,000 pop.)" in 19
replace main1 = "By psychiatrists (2008)" in 20
replace main1 = "By psychologists (2008)" in 21
replace main1 = "By social workers (2008)" in 22
replace main1 = "By occupational therapists (2008)" in 23
replace main1 = "Antipsychotic drugs" in 24

replace main1 = "Mental Health Facilities (per 10,000 pop.)" in 26
replace main1 = "Psychiatrists (2006)" in 27
replace main1 = "Psychologists (2006)" in 28
replace main1 = "Social workers (2006)" in 29
replace main1 = "Occupational therapists (2006)" in 30
replace main1 = "Psychiatric beds (2006)" in 31

replace main1 = "Municipality Characteristics" in 33
replace main1 = "Number of municipalities" in 34
replace main1 = "Population" in 35
replace main1 = "Men" in 36
replace main1 = "Age 10--19" in 37
replace main1 = "Age 40--49" in 38
replace main1 = "Age 70--79" in 39
replace main1 = "PBF per capita" in  40
replace main1 = "GDP per capita" in 41


export excel using "${results}/statdes_table1912.xls", replace



***********************************************************************************************************************
*********   OUTCOME : FIGURE 5 PANEL B : EFFECT OF CAPS ON LONG STAY HOSPITAL ADMISSIONS PER 10.000 PEOPLE (EVENT STUDY)              
***********************************************************************************************************************


*Each table/figure can be reproduced independently. 

*******************************************************************************
*** 			                FIGURE 5 PANEL B  				                    ***
*******************************************************************************
******************************************************************************************************************************
******************************************************************************************************************************

use "${data_final}/dataset_vf", clear
/* 

Program to:

Compute treatment effects on all the primary and secondary outcomes studied in the paper

Produce the event study graph FIGURE 5 PANEL B displayed in the paper


*/
*Here we set up the program that we are going to run in order to use the did_multiplegt estimator from Chaise et D'Hautefeuille.

cap program drop did

program did, rclass

	args outcome group time treatment cluster dynamic placebo bootstrapreps textx texty ylow ydelta yup year  

	//--------------------------------------------------------------------
	// SET UP OF THE MATRIX THAT WILL STORE THE RESULTS
	//--------------------------------------------------------------------

	* number of rows of matrix that will store results
	local row= `placebo'+`dynamic'+1

	* number of columns (event-study, upper bound of CI, lower bound of CI, se, N, N of switchers)
	loc column 6

	* label
	local labelrow
	forvalues i=-`placebo'/`dynamic'{
		local labelrow: display "`labelrow' `i'"	
	}

	* Sequence of placebos starting at 1 and going up
	local placeboup
	forvalues i=1/`placebo'{
		local placeboup: display "`placeboup' `i'"	
	}

	* Sequence of placebos starting at 1 and going down
	local placebodown
	forvalues i=`placebo'(-1)1{
		local placebodown: display "`placebodown' `i'"	
	}
	*

	*Defining Controls
global X loggdppc log_pbf_pc pop_m_10to19 pop_m_20to29 pop_m_30to39 pop_m_40to49 pop_m_50to59 pop_m_60to69 pop_m_70to79 pop_f_10to19 pop_f_20to29 pop_f_30to39 pop_f_40to49 pop_f_50to59 pop_f_60to69 pop_f_70to79 mhpf02trend estab02trend popruraltrend analfabs_2000trend sharepobres2000trend theil2000trend lnsaudepctrend poptotaltrend temperaturetrend municipality_areatrend distance_to_capitaltrend altitude_100trend rainfalltrend lnpbfpctrend lnpibpctrend
	 

	//--------------------------------------------------------------------
	// CHAISE & D'HAUTEFEUILLE (AER, 2022) ESTIMATOR
	//--------------------------------------------------------------------
	*** In this part we set up the DiD estimator using the commands from package did_multiplegt from CHAISE & D'HAUTEFEUILLE (AER, 2022). 
	
	* Dta
	use "${data_final}/dataset_vf", clear
	

	* keeping what is relevant
	keep if year>=`year'
	keep `treatment' `group' `time' id_state `cluster' `outcome' ${X}  

	
	* generating the year (ano) in which the treatment starts 
	g `treatment'_implemented=year if `treatment'==1
	bys id_muni: egen year_`treatment'_implemented=min(`treatment'_implemented)
	g eventtime`treatment'=year- year_`treatment'_implemented
	drop year_`treatment'_implemented `treatment'_implemented

	
	* estimator

	did_multiplegt `outcome' `group' `time' `treatment',  trends_nonparam(id_state) controls(${X}) placebo(`placebo') dynamic(`dynamic') breps(`bootstrapreps') cluster(`cluster') covariances average_effect(simple) 

	di "cheguei aki?"
	* This is a checkpoint to see that there aren't any bugs or errors
	
	****In this part we build the matrix storing results	
	
	// Empty matrix to be filled
	matrix Q=J(`row',`column',.)

	// Label rows
	matrix rown Q =  `labelrow'  

	//Add effects, ci, se, n, n of switchers
	forvalues i=0/`dynamic'{ 
	local m "`i'+`placebo'+1"
	local row: display `m'
	matrix Q[`row',1]=`e(effect_`i')'
	matrix Q[`row',2]=`e(effect_`i')'+`e(se_effect_`i')'*1.96 
	matrix Q[`row',3]=`e(effect_`i')'-`e(se_effect_`i')'*1.96
	matrix Q[`row',4]=`e(se_effect_`i')'
	matrix Q[`row',5]=`e(N_effect_`i')'
	matrix Q[`row',6]=`e(N_switchers_effect_`i')'
	}

		
	//Add placebos, ci, se, n
	local up `placeboup' //xxixx
	local down `placebodown' //xxixx
	local n : word count `up'
	forvalues i = 1/`n' {
	 local u : word `i' of `up'
	 local d : word `i' of `down'
	matrix Q[`u',1]=`e(placebo_`d')'
	matrix Q[`u',2]=`e(placebo_`d')'+`e(se_placebo_`d')'*1.96
	matrix Q[`u',3]=`e(placebo_`d')'-`e(se_placebo_`d')'*1.96
	matrix Q[`u',4]=`e(se_placebo_`d')'
	matrix Q[`u',5]=`e(N_placebo_`d')'
	}
	

	* Build Variance-Covariance matrix for placebos
	matrix COVQp = J(`placebo',`placebo',.)
	matrix COVQp[1,1]=`e(se_placebo_1)'^2
	forvalues i = 2/`placebo' {
		matrix COVQp[`i',`i']=`e(se_placebo_`i')'^2
		forvalues j=1/`=`i'-1' {
			matrix COVQp[`i',`j']=`e(cov_placebo_`j'`i')'
			matrix COVQp[`j',`i']=`e(cov_placebo_`j'`i')'
		}
	}
	
		
	* Vector of placebo coef
	matrix Qp = J(`placebo',1,.)
	forvalues i=1/`placebo'{
		matrix Qp[`i',1]=`e(placebo_`i')'
	}
	

	* F test: all placebos=0
	matrix COVQp_inv=invsym(COVQp)
	matrix Qp_t=Qp'
	matrix U_g=Qp_t*COVQp_inv*Qp
	scalar statistic_joint=U_g[1,1]/`placebo'
	scalar p_joint=1-chi2(`placebo',U_g[1,1])

		
	*Build Variance-Covariance matrix for dynamic effects
	matrix COVQd = J(`dynamic',`dynamic',.)
	matrix COVQd[1,1]=`e(se_effect_1)'^2
	forvalues i = 2/`dynamic' {
		matrix COVQd[`i',`i']=`e(se_effect_`i')'^2
		forvalues j=1/`=`i'-1' {
			matrix COVQd[`i',`j']=`e(cov_effects_`j'`i')'
			matrix COVQd[`j',`i']=`e(cov_effects_`j'`i')'
		}
	}
	
	* Avg effects
	
	// long run dynamic
	scalar controls_effect = `e(effect_average)'  // point estimate
	scalar controls_effect_se = `e(se_effect_average)' // se
	
	// short run dynamic
	scalar controls_effect_short=(1/(3))*(e(effect_0)+e(effect_1)+e(effect_2)) // point estimate

	scalar controls_effect_short_se=sqrt((1/(3^2))*(COVQd[1,1]+COVQd[2,2]+COVQd[3,3]+2*COVQd[1,2]+2*COVQd[1,3]+2*COVQd[2,3]))  // se
	
	
	
	* Avg placebo effects
	scalar controls_placebo = 0
	forvalues i=1/`placebo' {
		scalar controls_placebo=controls_placebo+(`e(placebo_`i')')     // summing all placebos
	}
	
	
	scalar controls_placebo=controls_placebo/`placebo'  // point estimate
	
	mata : st_numscalar("controls_placebo_se", (1/(`placebo'^2))*sum(st_matrix("COVQp")))
	scalar controls_placebo_se=sqrt(controls_placebo_se) // se

	//-------------------------------------------------------------------------
	// SAVING RESULTS IN DTA
	//-------------------------------------------------------------------------

**** In this part, we store the results in a table format. Even though we do not replicate a table, it is necessary to go through this part in order to plug in mobilize the results in the table into the even study. The event study is visual support. This is how it is done by authors so we decided to follow their same methodology. 

	* event-study
	svmat Q, n(controls)
	rename controls1 controls_b   // point estimate
	rename controls2 controls_ciup // upper CI
	rename controls3 controls_cidw // lower CI
	rename controls4 controls_se	// SE
	rename controls5 controls_n		// N
	rename controls6 controls_nswitch	 // N of swithcers

	* long run avg dynamic
	gen controls_effect = scalar(controls_effect) in 1  // point estimate
	gen controls_effect_se = scalar(controls_effect_se) in 1 // SE
	
	* short run avg dynamic
	gen controls_effect_short = scalar(controls_effect_short) in 1  // point estimate
	gen controls_effect_short_se = scalar(controls_effect_short_se) in 1  // SE
	
	* avg placebo
	gen controls_placebo = scalar(controls_placebo) in 1 // point estimate
	gen controls_placebo_se = scalar(controls_placebo_se) in 1 // SE
	 
	* baseline mean
	summ `outcome' if eventtime`treatment' >= -`placebo' & eventtime`treatment' <= -1
	g mean_baseline = `r(mean)' in 1 // mean
	g se_mean_baseline = `r(sd)' in 1 // sd
	
	* f test: all placebos =0
	g f_test = statistic_joint in 1  // statistic
	g pvalue_f_test= p_joint in 1  // p value
	
	
	* saving dataset with the results
	keep controls* mean* se_mean_baseline  f_test pvalue_f_test
	keep if controls_b!=.
	save "${tables}/t`treatment'`outcome'r.dta", replace

	//-------------------------------------------------------------------------
	// GRAPH
	//-------------------------------------------------------------------------
*** here we export our results in a event study graph 
	
	local b: display  %4.3f controls_effect
	local se: display  %4.3f controls_effect_se
	local bpl: display  %4.3f controls_placebo
	local sepl: display  %4.3f controls_placebo_se	
	local meany: display  %4.2f mean_baseline
	local pftest: display  %4.2f pvalue_f_test
	
	coefplot (matrix(Q[,1]) , ci((Q[,2] Q[,3]))  pstyle(p1) msymbol(O)) ///
	,  yline(0, lcolor(red)) xline( `=`placebo'+1', lcolor(gs7) lpattern(dash)) vertical ytitle("Treatment Effect") xtitle("Time Since Treatment") ciopts(recast(rcap))  ///
	 text(`textx' `texty' "Average Treatment Effect:  `b' (`se')" "Average Placebo Effect:  `bpl' (`sepl')" "Baseline:  `meany'" " " "Joint significance of placebo effects: `pftest'" , place(e) just(left) size(small))  ylabel(`ylow'(`ydelta')`yup')
	graph export "${figures}\f`treatment'`outcome'r.pdf", as(pdf) replace 
	graph save Graph "${results}/f`treatment'`outcome'r.gph", replace 
	
	
	
end	

** REPLICATION OF MAIN OUTCOME: DIFF IN DIFF ESTIMATOR

/* Hospital admissions due to mental health disorders

FIGURE 5 PANEL B : IMPACT OF CAPS ON LONG STAY HOSPITAL ADMISSIONS BY MENTAL DISORDERS

*/
foreach youtcome in  longstay_ha_by_md {
	di "`youtcome'"
	qui did `youtcome' id_muni year ca id_muni 5 5 100 -1 1 -2 0.5 1 2002
}


*******************************************************************************
***                    	  Robustness: TABLE A8                              ***
*******************************************************************************

*This replicates Figure A8 


use "${data_final}/dataset_vf", clear


g treatment_year_psf=year if psf_imp==1
g treatment_year_caps=year if caps==1
bys id_muni: egen min_treatment_year_psf=min(treatment_year_psf)
bys id_muni: egen min_treatment_year_caps=min(treatment_year_caps)


drop if min_treatment_year_psf==2002
drop if min_treatment_year_caps==2002
duplicates drop id_muni, force


scatter min_treatment_year_psf min_treatment_year_caps  || lfit min_treatment_year_psf min_treatment_year_caps || lfit min_treatment_year_psf min_treatment_year_caps [aweight=poptotal], xlabel(2003(3)2016) ylabel(2003(3)2016) ytitle("PSF Adoption") xtitle("CAPS Adoption") title("") note("") legend(col(2) nobox region(lstyle(none))  order(2 "Linear fit" 3 "Linear fit with population weights") on)
graph export "${results}\psfcorrelation.pdf", as(pdf) name("Graph") replace

