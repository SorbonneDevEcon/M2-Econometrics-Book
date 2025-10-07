/// Stata Replication Project - Ibrahim Ben Araar, Nour Ouljihate, Marie Moussé

* Install Neccessary Packaages 
**ssc install hdfe
**ssc install estout 
**ssc install reghdfe
**ssc install synth, all

**cap ado uninstall synth_runner //in-case already installed
**net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace

/// Replication 

* Set the Path to where the dataset will be located on your PC. You can just replace ~ in the code with your desired directory and the code should run 

use "~/Rebellion.dta", clear *

////////////////////////////////////////////////////////////////////////////////////
/////// Figure 2 - Canal Usage Measured by Tribute Rice Transportation ////////////
//////////////////////////////////////////////////////////////////////////////////


*dropping duplicates in the data 
duplicates drop year, force 
*restrict data to time period between 1755 and 1860
keep if year > 1755 & year <1860  


*fitted line for time before 1826, for time after 1826 and scatter plot 
twoway (lfit lamount year if year < 1826, lwidth(1.5pt) color(black) lpattern(dash)) 
(lfit lamount year if year >= 1826, lwidth(1.5pt) lpattern(dash) color(black)) 
(scatter lamount year, color(gs10)), 
xline(1825, lwidth(2pt) lcolor(maroon)) /// red vertical line in 1825
xtitle("Years") ytitle("Shipping Volume (log million piculs)") legend(off) /// titles of the axes 
title("Figure 1: Canal Usage measured by Tribute Rice Transportation") subtitle("1755 - 1860") /// title of the graph 
graph export figure1.png, replace /// two fitted lines and a scatter plot to highlight the discontinuity follwing 1825

/////////////////////////////////////////////////////////////////////////////
/////// Table 3 - Canal Closure and Rebellions: Baseline Estimates /////////
///////////////////////////////////////////////////////////////////////////

use "~/Rebellion.dta", clear

* defining the global controls which will be used in the analysis
global ctrls larea_after rug_after disaster disaster_after flooding drought flooding_after drought_after lpopdencnty1600_after maize maize_after sweetpotato sweetpotato_after wheat_after rice_after 

* fixed-effects regression (county&year FEs)
reghdfe ashonset_cntypop1600 interaction1, absorb(i.OBJECTID i.year) cluster(OBJECTID) 
eststo Column1 
quietly tabulate OBJECTID if e(sample) 
* save number of clusters
scalar groups=r(r) 
qui su ashonset_cntypop1600 if e(sample)
scalar ymean=r(mean) 
* to compute the mean of the dependent variable
estadd scalar depavg=ymean:Column1 
estadd scalar N_g=groups:Column1 // to get the number of counties 

* repeat for columns 2-5 with additional controls and Fixed Effects
reghdfe ashonset_cntypop1600 interaction1, absorb(i.OBJECTID i.year c.ashprerebels#i.year) cluster(OBJECTID)
eststo Column2
quietly tabulate OBJECTID if e(sample)
scalar groups=r(r)
qui su ashonset_cntypop1600 if e(sample)
scalar ymean=r(mean)
estadd scalar depavg=ymean:Column2
estadd scalar N_g=groups:Column2


reghdfe ashonset_cntypop1600 interaction1, absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year) cluster(OBJECTID)
eststo Column3
quietly tabulate OBJECTID if e(sample)
scalar groups=r(r)
qui su ashonset_cntypop1600 if e(sample)
scalar ymean=r(mean)
estadd scalar depavg=ymean:Column3
estadd scalar N_g=groups:Column3


reghdfe ashonset_cntypop1600 interaction1, absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year i.prefid#c.year) cluster(OBJECTID)
eststo Column4
quietly tabulate OBJECTID if e(sample)
scalar groups=r(r)
qui su ashonset_cntypop1600 if e(sample)
scalar ymean=r(mean)
estadd scalar depavg=ymean:Column4
estadd scalar N_g=groups:Column4


reghdfe ashonset_cntypop1600 interaction1 $ctrls, absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year i.prefid#c.year) cluster(OBJECTID) /// include all the previously defined controls
eststo Column5
quietly tabulate OBJECTID if e(sample)
scalar groups=r(r)
qui su ashonset_cntypop1600 if e(sample)
scalar ymean=r(mean)
estadd scalar depavg=ymean:Column5
estadd scalar N_g=groups:Column5

/// Compute Conley Standard Errors (Run the ols_spatial_HAC.ado before this step)

* to manipulate dataset without losing it
preserve 

* get the fixed effects for each observation (value of dependent variable - respective fixed effect values are stored)
hdfe ashonset_cntypop1600 interaction1, clear absorb(i.OBJECTID i.year) tol(0.001) keepvars(OBJECTID year Y_COORD X_COORD) 

* User-written command to get the Conley Standard errors 
ols_spatial_HAC ashonset_cntypop1600 interaction1, lat(Y_COORD) lon(X_COORD) time(year) panel(OBJECTID) distcutoff(500) lagcutoff(262) disp star 

* save the Standard errors in a matrix 
matrix V_spat=vecdiag(e(V)) 
matmap V_spat SE_spat, m(sqrt(@)) 
estadd matrix sesp=SE_spat: Column1 

* reset the dataset to initial status before the last steps 
restore 

*repeat the steps
preserve
hdfe ashonset_cntypop1600 interaction1, clear absorb(i.OBJECTID i.year c.ashprerebels#i.year) tol(0.001) keepvars(OBJECTID year Y_COORD X_COORD)
ols_spatial_HAC ashonset_cntypop1600 interaction1, lat(Y_COORD) lon(X_COORD) time(year) panel(OBJECTID) distcutoff(500) lagcutoff(262) disp star
matrix V_spat=vecdiag(e(V))  
matmap V_spat SE_spat, m(sqrt(@)) 
estadd matrix sesp=SE_spat: Column2
restore
preserve
hdfe ashonset_cntypop1600 interaction1, clear absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year) tol(0.001) keepvars(OBJECTID year Y_COORD X_COORD)
ols_spatial_HAC ashonset_cntypop1600 interaction1, lat(Y_COORD) lon(X_COORD) time(year) panel(OBJECTID) distcutoff(500) lagcutoff(262) disp star
matrix V_spat=vecdiag(e(V)) 
matmap V_spat SE_spat, m(sqrt(@)) 
estadd matrix sesp=SE_spat: Column3
restore
preserve
hdfe ashonset_cntypop1600 interaction1, clear absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year i.prefid#c.year) tol(0.001) keepvars(OBJECTID year Y_COORD X_COORD)
ols_spatial_HAC ashonset_cntypop1600 interaction1, lat(Y_COORD) lon(X_COORD) time(year) panel(OBJECTID) distcutoff(500) lagcutoff(262) disp star
matrix V_spat=vecdiag(e(V)) 
matmap V_spat SE_spat, m(sqrt(@)) 
estadd matrix sesp=SE_spat: Column4
restore
preserve
hdfe ashonset_cntypop1600 interaction1 $ctrls, clear absorb(i.OBJECTID i.year c.ashprerebels#i.year i.provid#i.year i.prefid#c.year) tol(0.001) keepvars(OBJECTID year Y_COORD X_COORD)
ols_spatial_HAC ashonset_cntypop1600 interaction1, lat(Y_COORD) lon(X_COORD) time(year) panel(OBJECTID) distcutoff(500) lagcutoff(262) disp star
matrix V_spat=vecdiag(e(V)) 
matmap V_spat SE_spat, m(sqrt(@)) 
estadd matrix sesp=SE_spat: Column5
restore

estfe Column1 Column2 Column3 Column4 Column5

esttab Column* using table3.tex , compress keep(interaction1 _cons) se(4) nomtitles nonotes ///
cells(b(fmt(4)) se(fmt(4) par(( ))) sesp(fmt(4) par([ ]) drop(_cons))) collabels("",none) ///
sca(OBJECTID) stats( depavg N N_g r2_a, fmt( 3 %7.0fc 0 4) labels( "Mean of the dependent Variable" "Number of observations" "Number of counties" "Adjusted R^2")) label title("Rebellions") ///
indicate("County FE =0.OBJECTID" "Year FE=0.year" "Pre-reform rebellion $\times$ Year FE=0.year#c.ashprerebels" "Province $\times$ Year FE=0.provid#0.year"  "Prefecture Year Trend=0.prefid#c.year" "Controls $ \times $ Post=$ctrls ") 

/// indicate() to get table with yes or no indication for each fixed effect 
/// cells() to define which values to include. b are the coeeficients for instance and sesp are our Conley SEs 

eststo clear

////////////////////////////////////////////////////////////////////////////////////
///////// Figure A6 - Robustness Check using Synthetic Control ////////////////////
//////////////////////////////////////////////////////////////////////////////////

* rounding down all years 
replace year=floor((year-1826)/10)*10+1826 
* get average values of each decade
collapse (mean) onset_all cntypop1600 alongcanal distance_canal, by(OBJECTID year) 
* re-generate the dependent variable 
gen ashonset_cntypop1600=asinh(onset_all/(cntypop1600/1000000)) 
* define y as our dependent variable 
gen y=ashonset_cntypop1600 
* drop missings
keep if y<. 
* keep only values after 1776
keep if year>=1776 
* drop observations too close to treated counties
drop if distance_canal<150 & alongcanal==0 
* re-generate treatment variable 
gen interaction1=alongcanal*(year>=1826) 
drop if OBJECTID == 491 /// code did not work without dropping this observation 

* synth_runner specifying that values in 1776, 1806 and 1816 are used for computation; gen_var will save the results 
synth_runner y y(1776) y(1796) y(1806) y(1816), d(interaction1) gen_var 
matrix P = e(pvals_std) /// keep the p-values of the SCM estimation 

* reshaping of data for the final graph 
preserve
clear
svmat P, names(matcol)
gen I = 1
reshape long Pc, i(I) j(lead)
drop I
rename Pc p_vals
tempfile temp
save "`temp'.dta", replace
restore
merge m:1 lead using "`temp'.dta", nogenerate
save "~/synth10alt.dta", replace

use "~/synth10alt.dta", clear
replace year=year-1826
keep if alongcanal == 1
collapse (mean) p_vals y y_synth, by(year)
gen effect = y - y_synth
keep if year<70 

* Graph presenting the average treated observations and the average for the synthtic controls over time 
twoway (connected y year, lpattern(solid) msymbol(C) color(black)) ///
(connected y_synth year, lpattern(dash) msymbol(T)  color(gs10)), ///
ytitle("Coefficients") ///
xtitle("Number of years since the 1826 reform") ///
xline(-5, lpattern(dash) lcolor(maroon)) //////
xlabel(-50(10) 70) /// 
graphregion(color(white)) ///
scheme(s2color) ///
legend(order(1 "Canal counties (treated)" 2 "Synthetic controls") cols(2)) ///
title("(a) Treatment v.s. synthetic control") 

* Save Graph to disk
graph export "~/figureA6a.pdf", replace

*Graph showing the effectsizes (left axis) and the corresponding p-values (right axis) over time
twoway (line effect year, c(l) yaxis(1) lpattern(solid) color(black) ytitle("Treatment effects", axis(1)) ylabel(-0.2(0.2)0.8,axis(1))) ///
(scatter p_vals year, yaxis(2) color(gs10) ylabel(0.0(0.2)1.0, axis(2)) ytitle("p-values", axis(2))), ///
xtitle("Number of years since the 1826 reform") ///
xline(-5, lpattern(dash) lcolor(maroon)) /// ///
xlabel(-50(10) 70) ///
graphregion(color(white)) ///
scheme(s2color) ///
legend(order(2  "P-values" 1 "Treatment effects" ) cols(2)) ///
title("(b) Treatment effects") 

* Save Graph to disk
graph export "~/figureA6b.pdf", replace
