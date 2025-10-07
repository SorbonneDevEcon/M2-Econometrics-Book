
* Reference: Derenoncourt, E. (2022). Can you move to opportunity? Evidence from the Great Migration. American Economic Review, 112(2), 369-408.

* Link to the published article: https://www.aeaweb.org/articles?id=10.1257/aer.20200002

* Link to the original replication package: https://www.openicpsr.org/openicpsr/project/147963/version/V1/view

* Replication file prepared by: Gaia BECHARA, Evely GEROULAKOS, Oleksandra POVSTIANA, Fatemeh RAZAVI

* Academic year: 2024/2025

* Replicating: Figure 2, Table 5 and 6 and Table 9


********************************************************************************
* Initialization and organization of the directories
********************************************************************************

* Clear all and set max matsize

capture log close
clear all
set more off

set maxvar 9000 




*installing necessary packages
*estout stores estimates and allows us to make regression tables

ssc install estout, replace

* binscatter allows us to visualize grouped data trends
ssc install binscatter, replace

*ivreg2 allows us to run instrumental variables regressions
ssc install ivreg2, replace

* Setting up directories

global XX "YOUR DIRECTORY GOES HERE"
global data "$XX/data"
global logs "$XX/logs"
global figtab "$XX/figtab"

*setting up necessary globals to be used in our analysis
global x_ols GM
global x_iv GM_hat2	
global baseline_controls frac_all_upm1940 mfg_lfshare1940  v2_blackmig3539_share1940 reg2 reg3 reg4




* in order to Automates the process of saving results in a uniform way and also Exports results into .txt files that can be easily imported into tables or figures in a LaTeX or Word document we use PrintEst program at the very beginning of our work.

capture program drop PrintEst
program PrintEst
	args est name txtb4 txtaftr decim
	di `est'
	di "`name'"
	tempname sample 
	cap mkdir $figtab/text
	file open `sample' using  "$figtab/text/`name'.txt", text write replace
	*local est_rounded = round(`est', 0`decim')
	local est_rounded : di %`decim'f `est'
	file write `sample'  `"`txtb4'`est_rounded'`txtaftr'"'
	file close `sample'
end



********************************************************************************
							* Descriptive statistics
********************************************************************************
* Figure 2: Quantiles of urban black share increases, 1940-1970
********************************************************************************


	use ${data}/GM_cz_final_dataset.dta, clear
	gen mylabel=cz_name+"                  " if regexm(cz_name, "Steubenville") | regexm(cz_name, "Milwaukee") ///
	| regexm(cz_name, "Washington") | regexm(cz_name, "Gary") | regexm(cz_name, "Detroit") 
	replace mylabel="Washington, D.C." if regexm(cz_name, "Washington")
	replace mylabel="Detroit, MI" if regexm(cz_name, "Detroit")
	replace mylabel="Gary, IN" if regexm(cz_name, "Gary")
	replace mylabel="Steubenville, OH" if regexm(cz_name, "Steubenville")
	replace mylabel="Milwaukee, WI" if regexm(cz_name, "Milwaukee")
	graph twoway (scatter bpopchange1940_1970 GM if mylabel!="", legend(off) mcolor(orange) msymbol(circle_hollow) ///
	msize(vlarge) mlabel(mylabel) mlabcolor(black) mlabposition(11) graphregion(color(white)) plotregion(ilcolor(white)) ///
	ylabel(,nogrid))  || (scatter bpopchange1940_1970 GM, xtitle("Percentile of urban Black pop increase 40-70") ///
	ytitle("Incr. in urban Black pop '40-70 as ppt of 1940 urban pop") legend(off) mcolor(green) graphregion(color(white)) plotregion(ilcolor(white))) 
	cd "$figtab"
	graph export bpopchange_percentiles.png, replace
	
* Point estimates cited in text & & saving using PrintEst
	
	* median 
		summ bpopchange1940_1970, d
		local p50_bpopchng4070 = `r(p50)'
		PrintEst `p50_bpopchng4070' "p50_bpopchng4070" "" " percentage points%" "3.1"
		
	*creating a new variable that is the percentile rank of black population change using xtile
		xtile pctbpopchange1940_1970 = bpopchange1940_1970, nq(100)
		
	*Pittsburgh
		summ bpopchange1940_1970 if cz_name=="Pittsburgh, PA"
		local pitt_bpopchng4070 = `r(mean)'
		PrintEst `pitt_bpopchng4070' "pitt_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Pittsburgh, PA"
		local pitt_pctbpopchng4070 = `r(mean)'
		PrintEst `pitt_pctbpopchng4070' "pitt_pctbpopchng4070" "" "rd percentile%" "2.0"
		
	*Detroit
		summ bpopchange1940_1970 if cz_name=="Detroit, MI"
		local detr_bpopchng4070 = `r(mean)'
		PrintEst `detr_bpopchng4070' "detr_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Detroit, MI"
		local detr_pctbpopchng4070 = `r(mean)'
		PrintEst `detr_pctbpopchng4070' "detr_pctbpopchng4070" "" "th percentile%" "2.0"
		
	*Salt Lake City
		summ bpopchange1940_1970 if cz_name=="Salt Lake City, UT"
		local slc_bpopchng4070 = `r(mean)'
		PrintEst `slc_bpopchng4070' "slc_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Salt Lake City, UT"
		local slc_pctbpopchng4070 = `r(mean)'
		PrintEst `slc_pctbpopchng4070' "slc_pctbpopchng4070" "" "th percentile%" "2.0"
		
	*Washington, DC
		summ bpopchange1940_1970 if cz_name=="Washington DC, DC"
		local wadc_bpopchng4070 = `r(mean)'
		PrintEst `wadc_bpopchng4070' "wadc_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Washington DC, DC"
		local wadc_pctbpopchng4070 = `r(mean)'
		PrintEst `wadc_pctbpopchng4070' "wadc_pctbpopchng4070" "" "th percentile%" "2.0"


******************************************************************************************
							* Results on upward mobility	
*******************************************************************************************
	* Table 5 and 6: Great Migration Impact on Black and White Families
*******************************************************************************************


* In this section we are replicating Tables 5 and 6 of the paper comparing upward mobility outcomes for Black and White households in Great Migration (GM) commuting zones (CZs).

* We loop through the two groups, "black" and "white," using the macro r. In each iteration, the macro race is set to the same group but with proper capitalization ("Black" or "White") for consistent formatting in outputs. 


use ${data}/GM_cz_final_dataset.dta, clear
	*capitalizing black and white 
	foreach r in "black" "white"{
		if "`r'" == "black" {
			local race "Black"
			}
			else {
				local race "White"
				}
	*Defining local outcomes 
	local outcomes kfr_`r'_pooled_p252015 kir_`r'_female_p252015 kir_`r'_male_p252015 kfr_`r'_pooled_p752015 kir_`r'_female_p752015 kir_`r'_male_p752015

* First Stage	
	*Note: outcomes here are irrelevant
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	qui sum GM
	local ols_SD=`r(sd)'
	* Rescale outcome in percentile ranks
	replace `y'=100*`y'
	reg $x_ols $x_iv   ${baseline_controls} if `y'!=.
	eststo `y'
	test $x_iv = 0
	estadd scalar fstat=`r(F)'
	}
	cd "$XX"
	esttab `outcomes' using "`r'_hh_table.tex", frag replace  varwidth(25) label se ///
	stats(fstat, labels(  F-Stat)) keep($x_iv) mgroups("", pattern(1 0) prefix(\multicolumn{6}{c}{First Stage on GM})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
* OLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	qui sum GM
	local ols_SD=`r(sd)'
	replace `y'=100*`y'
	reg `y' $x_ols  ${baseline_controls}  if `y'!=.
	eststo `y'
	}
	cd "$XX"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	prehead("\\" "&\multicolumn{3}{c}{Low Income}&\multicolumn{3}{c}{High Income}\\" ///
	"&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men}&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men} \\\cmidrule(lr){2-7}")  ///
	stats( r2, labels( R-squared)) keep($x_ols) mgroups("", prefix(\multicolumn{6}{c}{Ordinary Least Squares})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 

* RF 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	qui sum GM
	local ols_SD=`r(sd)'
	replace `y'=100*`y'
	reg `y' $x_iv  ${baseline_controls} if `y'!=.
	eststo `y'
	}
	cd "$XX"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	stats( r2, labels( R-squared)) keep($x_iv) mgroups("", prefix(\multicolumn{6}{c}{Reduced Form})) nonumber  ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
* 2SLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	qui sum GM
	local ols_SD=`r(sd)'
	*Rescaling the outcome variable and conduction the IV regression if y is not missing
	replace `y'=100*`y'
	ivreg2 `y' ($x_ols = $x_iv )  ${baseline_controls}  if `y'!=., first
	*Saving estimates : 
	local GM_`y' = _b[$x_ols]
	local GM_`y'_abs = abs(_b[$x_ols])
	local GM_`y'_se : di %4.3f _se[$x_ols]
	PrintEst `GM_`y'' "GM_`y'" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
	PrintEst `GM_`y'_abs' "GM_`y'_abs" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
	eststo `y'
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	sum `y' 
	*Adding scalar to be included in the table 
	estadd scalar basemean=r(mean)
	estadd scalar sd=r(sd)	
	estadd scalar gm_sd=`ols_SD'
	}
	
	cd "$XX"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	keep($x_ols) mgroups("", prefix(\multicolumn{6}{c}{Two-stage least squares})) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
* Footer
	cd "$XX"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	stats( N  basemean sd gm_sd, labels("Observations"  "Mean Rank" "SD Rank" "SD GM")) drop(*) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	}

***********************************************************************************	
								* Robustness checks	
***********************************************************************************	
	* Table 9: Robustness of Great Migration's effects on black men's upward mobility
***********************************************************************************
	
	*Defining the globals of controls that will be used in each of the columns of the robustness tests. Every variable used here is explained in the 	*codebook 
	global nocon "v2_blackmig3539_share1940"
	global divfe "v2_blackmig3539_share1940 reg2 reg3 reg4"	
	global baseline "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4"
	global emp "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 emp_hat"
	global flexbpop40 "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 i.bpopquartile"		
	global swmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  GM_hat8"
	global eurmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  eur_mig"
	global supmob "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  vm_blacksmob1940"

	
	*Only using one outcome variable this time, focusing on Black men. 
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	local y  kir_black_male_p252015 	

	replace `y' = 100 * `y'
*Running, first stage regressions, OLS and IV for each model specification 
*Model 1 starts here 
	reg $x_ols $x_iv $nocon 
	test $x_iv = 0
	local fstat=`r(F)'
	
	reg `y' $x_ols $nocon  
	eststo nocon_ols
	estadd local hasdivfe       "N"
	estadd local hasbaseline    "N"
	estadd local hasemp         "N"
	estadd local hasflexbpop40  "N"
	estadd local hasswmig       "N"
	estadd local haseurmig      "N"
	estadd local hassupmob      "N" 
	estadd local precisionwt    "Y"

	ivreg2 `y' ($x_ols = $x_iv) $nocon  
	eststo nocon
	estadd scalar fstat = `fstat'  

*Model 2 starts here 
	reg $x_ols $x_iv $divfe 
	test $x_iv = 0
	local fstat = r(F)  // Update `fstat` for the new test

	reg `y' $x_ols $divfe    
	eststo divfe_ols
	estadd local hasdivfe       "Y"
	estadd local hasbaseline    "N"
	estadd local hasemp         "N"
	estadd local hasflexbpop40  "N"
	estadd local hasswmig       "N"
	estadd local haseurmig      "N"
	estadd local hassupmob      "N" 
	estadd local precisionwt    "Y"
	
	ivreg2 `y' ($x_ols = $x_iv )  $divfe    
	eststo divfe
	estadd scalar fstat=`fstat'

*Model 3 starts here 	
	reg $x_ols $x_iv $baseline 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $baseline 
	eststo baseline_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $baseline 
	eststo baseline
	estadd scalar fstat=`fstat'

*Model 4 starts here 	
	reg $x_ols $x_iv $emp 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $emp  
	eststo emp_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"Y"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $emp  
	eststo emp
	estadd scalar fstat=`fstat'

*Model 5 starts here 
	reg $x_ols $x_iv $flexbpop40 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $flexbpop40  
	eststo flexbpop40_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"Y"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y"

	ivreg2 `y' ($x_ols = $x_iv ) $flexbpop40  
	eststo flexbpop40
	estadd scalar fstat=`fstat'

*Model 6 starts here 	
	reg $x_ols $x_iv $swmig 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $swmig  
	eststo swmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"Y"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $swmig  
	eststo swmig
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $eurmig 
	test $x_iv = 0
	local fstat=`r(F)'

*Model 7 starts here 
	reg `y' $x_ols $eurmig  
	eststo eurmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig	 	"N"
	estadd local haseurmig		"Y"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv )  $eurmig  
	eststo eurmig
	estadd scalar fstat=`fstat'

*Model 8 starts here 
	reg $x_ols $x_iv $supmob 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $supmob  
	eststo supmob_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp			"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"Y"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv ) $supmob  
	eststo supmob
	estadd scalar fstat= `fstat'
	
*Saving and importing into tex file:
	cd "$figtab"
	esttab nocon divfe baseline flexbpop40 supmob  swmig eurmig emp using "main_robust_table_bmp25.tex", frag replace varwidth(25) label se ///
	stats( fstat, labels("First Stage F-Stat")) keep($x_ols) coeflabel(GM "GM (2SLS)")  nonumber ///
	nostar nomtitle nonotes nolines nogaps  substitute({table} {threeparttable}) prefoot(\cmidrule(lr){2-9})
	
	esttab nocon_ols divfe_ols baseline_ols flexbpop40_ols supmob_ols  swmig_ols eurmig_ols emp_ols  using "main_robust_table_bmp25.tex", frag append  varwidth(25) label se ///
	prehead("\\") coeflabel(GM "GM (OLS)") ///
	stats( r2  N  precisionwt hasdivfe hasbaseline hasflexbpop40 hassupmob hasswmig haseurmig hasemp , ///
	labels( "R-squared (OLS)" N "Precision Wt" "Census Div FE" "Baseline Controls"  "1940 Black Share Quartile FEs" "Southern Mob" ///
	"White South Mig" "Eur Mig"  "Emp Bartik" )) keep($x_ols)  nonumber  ///
	nostar nomtitle nonotes nolines prefoot(\cmidrule(lr){2-9}) postfoot(\cmidrule(lr){2-9})  substitute({table} {threeparttable}) 
			
	