*Replication exercise on : Laajaj, R., Moya, A., & Sánchez, F. (2022). Equality of opportunity and human capital accumulation: Motivational effect of a nationwide scholarship in Colombia. Journal of Development Economics, 154, 102754. https://doi.org/10.1016/j.jdeveco.2021.102754

*Link to the article : https://www.sciencedirect.com/science/article/pii/S0304387821001206

*Replication file prepared by : Angélique Fantou, Emma Verhille and Agathe Loyer

*****************************************************************************************************
*									       Replication exercise 	            				    *
*									              Do File 	             	                 		*
*	      Reproduces tables 1 (rows 1,2,4,5,7) and 3 & figures 4 and 2A with Saber 11 results       *
*****************************************************************************************************

***************************************************************************************
*********   A/ Generate the data from original replication file               *********
***************************************************************************************

*download and save the original dataset "SPP_ready.dta" from https://www.openicpsr.org/openicpsr/project/146921/version/V1/view:
*go to Data>Originals>SPP_ready.dta

*set the directory C:\Users\XXX, where you have stored the dataset and where you will store your results
cd "C:\Users\XXX"

*open the dataset
use "SPP_ready.dta", clear

*______________________________________________________________________
*Data Preparation      

*keep only the variables we need for the replication
keep ranking eligible_post eligible non_eligible post sisben sisben_eligible sisben_post sisben_eligible_post area_ciudades area_urbano icfes_padre_nivel1 icfes_padre_nivel2 icfes_padre_nivel3 icfes_madre_nivel1 icfes_madre_nivel2 icfes_madre_nivel3 edad sexo_sisben departamento_cod_* saber_rk_col area_sisben_dnp puntaje_sisben_dnp year 

*rename the variables 
rename area_ciudades cities 
rename area_urbano other_urban 
rename icfes_padre_nivel1 father_educ_prim 
rename icfes_padre_nivel2 father_educ_second 
rename icfes_padre_nivel3 father_educ_high 
rename icfes_madre_nivel1 mother_educ_prim 
rename icfes_madre_nivel2 mother_educ_second 
rename icfes_madre_nivel3 mother_educ_high 
rename edad age
rename sexo_sisben sex 
rename area_sisben_dnp area_sisben
rename puntaje_sisben_dnp score_sisben 
rename saber_rk_col saber_avg_school

*change labels for the variable area_sisben
label define new_labels 1 "14 Main Cities" 2 "Urban Rest" 3 "Rural"
label values area_sisben new_labels

*use a loop to rename several variables
forval i = 1/33 {
    local oldvar "departamento_cod_`i'"
    local newvar "department_`i'"
    rename `oldvar' `newvar'
}

gen status_eligible= 1 if non_eligible == 0 & post ==0
replace  status_eligible= 2 if non_eligible == 1 & post ==0
replace  status_eligible = 3 if non_eligible == 0 & post ==1
replace  status_eligible = 4 if non_eligible ==1 & post ==1

label define status_eligible_labels 1 "Need-based Eligible 2013-2014" 2 "Non-Eligible 2013-2014" 3 "Need-based Eligible 2015" 4 "Non-Eligible 2015"

* Apply the labels to the categorical variable
label values status_eligible non_eligible_post_labels
drop non_eligible 

label variable score_sisben "Score Sisbén DNP"
label variable area_sisben "Area Sisbén DNP"
label variable father_educ_prim "Father's primary education"
label variable father_educ_second "Father's secondary education"
label variable father_educ_high "Father's high school education"
label variable mother_educ_prim "Mother's primary education"
label variable mother_educ_second "Mother's secondary education"
label variable mother_educ_high "Mother's high school education"
label variable sex "Sex"
label variable cities "14 Main Cities"
label variable other_urban "Other cities"
label variable ranking "Ranking Saber test"
label variable sisben "Distance to the threshold"
label variable post "Before or after SPP"
label variable eligible "Eligibility"
label variable eligible_post "Treated or not"
label variable status_eligible "Student's status"
label variable saber_avg_school "Saber average score of middle school"

save "dataset_LMS.dta", replace // save the dataset created in a new file


***************************************************************************************
*********  B / Replication do-file for the replication exercise               *********
***************************************************************************************

*______________________________________________________________________
* Open the data      

*set the directory, where you have stored the dataset and where you will store your results
*cd "DIRECTORY HERE"
cd "C:\Users\XXX"
use "dataset_LMS.dta", clear

*Each table/figure can be reproduced independently. 
*********************************************************
*** 	  NECESSARY PACKAGES AND GLOBALS				*
*********************************************************
** Necessary packages to run the code:
ssc install estout, replace
ssc install outreg2, replace
ssc install rdrobust, replace
net install grc1leg.pkg, replace
ssc install rddensity, replace

**Set a global for all the control variables used in regressions
global controls cities other_urban father_educ_prim father_educ_second father_educ_high mother_educ_prim mother_educ_second mother_educ_high age sex department_1-department_32 saber_avg_school

*********************************************************
*** 			BANDWIDTH CALCULATIONS  				*
*********************************************************

** In this part, you will calculate the optimal bandwidths needed for our regressions (here CERSUM introduced by Calonico et al., 2014). 

** For that, you will first need to calculate it for pre period (year 2013 and 2014) and then for post period (2015)
ssc install rdrobust, replace

* pre cersum:
rdrobust ranking sisben if post == 0, kernel(uniform) bwselect(cersum) //robust regression analysis of ranking on sisben under the condition that the variable post = 0 (either in 2013 or 2014)
scalar bw_pre_cersum = e(h_l) // create a scalar variable and assign it to the value of the estimated bandwidth stored in e(h_l)

* post cersum:
rdrobust ranking sisben if post == 1, kernel(uniform) bwselect(cersum) //robust regression analysis of ranking on sisben under the condition that the variable post = 1 (2015)
scalar bw_post_cersum = e(h_l) // create a scalar variable and assign it to the value of the estimated bandwidth stored in e(h_l)

scalar bw_dif_cersum = (bw_pre_cersum +bw_post_cersum)/2 // create a scalar variable and assign it to the mean of both above calculated bandwidths

scalar list _all // see the results 

*In the rest of the replication, you will always simply set the scalar before running any discontinuity regressions
scalar bw_dif_cersum =  3.3502511


***************************************************************************************
*********                         Table 1 - Descriptive Statistics                    *********
***************************************************************************************


* This replicates Table 1 (Parts A, B and C): descriptive statistics for the sisben eligible group, non-eligibile group in pre-period and post-period (mean rank of students, and their rank by quantile, depending on whether they are eligible or not, and if they benefited from the introduction of SPP)

use "dataset_LMS.dta", clear

*______________________________________________________________________
*Replicate rows (1), (2)  from part A and (4), (5) from part B

*** Replicate rows (1), (2), (4) and (5): means for average scores and for each quantile (25,50,75,90) and store it as an xls file (excel)

ssc install estout, replace // install package for regression tables 

eststo A: estpost tabstat ranking, by(status_eligible) statistics(N mean q p90) columns(statistics) //tabstat displays summary statistics (here the number of observations, the mean and the 25th,50th,75th and the 90th quantiles )

esttab A using "means.txt", cells("mean(fmt(1)) p25(fmt(1)) p50(fmt(1)) p75(fmt(1)) p90(fmt(1))") title("Table 1. Saber 11 rank of eligible and non-eligible students before and after the motivational effect") noobs nonumber nonote nostar label replace varwidth(30) //Display the table of the summary statistics in a text file with only one decimal (fmt(1)), showing the labels (label) with their entire names (varwidth(30))


*_____________________________________________________________________
*Replicate row (7) from part C

*** Replicate row (7) descriptive DiD with significance level on average scores and store it as an xls file (excel)
ssc install outreg2, replace
reg ranking eligible_post eligible post, vce (robust)
outreg2 using "descr_DiD_.xls", label ///
ctitle("Average Rank") replace less (1)


*** Replicate row (7) : descriptive DiD with significance level per quantile (25,50,75,90) and store it as an xls file (excel)
foreach j in .25 .50 .75 .90 {
qreg ranking eligible_post eligible post, q(`j') vce (robust) 
outreg2 using "descr_DiD_.xls", ///
ctitle(`j') append less (1)  //Append to the precedent table
}


***************************************************************************************
*********    	  Figure 4 - Graphical representation of the             *********
*          		  difference-in-discontinuities estimators                 
***************************************************************************************

*This replicates Figure 4, which plots the relationship between the running variable (Sisben score, centered at the cutoff) and the outcome variable (ranking change). It provides a graphical representation of the RDD estimators on average effect, and at the 25th, 50th, 75th, 90th percentile.

scalar drop _all

use "dataset_LMS.dta", clear

scalar bw_dif_cersum =  3.3502511 //Set the optimal bandwidth determining treatment to 3.35. 

*Set a global for all the control variables used in regressions
global controls cities other_urban father_educ_prim father_educ_second father_educ_high mother_educ_prim mother_educ_second mother_educ_high age sex department_1-department_32 saber_avg_school

set seed 1984 //  This specifies the initial value of the random-number seed used by the function. 

*Set the width of bins 
scalar small_binsize = .01 
scalar large_binsize = .3

*______________________________________________________________________
*Data preparation for Graph Kernel 90th percentile 

use "dataset_LMS.dta", clear

keep if abs(sisben)<bw_dif_cersum // We keep only observations for which the absolute value of the running variable (distance between student's Sisben score and the need-based eligibility cutoff) is inferior to 3.35, that is keep only the need-based eligible. 

gen pre = (post == 0) // The variable pre is equal to 1 for students who passed the Saber 11 exam in 2015 before and didn't benefit from the SPP.

*Generate bins that will appear in the graph. In an RDD graph, observations are often grouped into bins based on their values on the assignment variable. The graph displays the average ranking in the Saber 11 for each bin.
*Large bins
gen large_bins = round(sisben + large_binsize/2, large_binsize)- large_binsize/2 if abs(sisben)<bw_dif_cersum  
*Small bins 
gen small_bins = round(sisben,small_binsize) // Each small bin is set to 0.01 around the sisben score for each individual. 

*______________________________________________________________________
*OLS (average) estimation depicted in the graph

reg ranking ${controls} post , robust // Regress the ranking in Saber score (outcome) according to control variables and passing the Saber exam after the implementation of SPP. 
predict resid_ols, residuals // Save the residuals from the regression, creating the variable resid_ols.  

	***Calculation of local percentiles:
/*We compute means for the variables ranking and resid_ols, within subsets defined by the variable small_bins and large_bins, for two time periods (pre and post). It creates new variables for each combination of time period, variable, and subset.
	- ranking_ols_pre is the mean of ranking within each small bin, before the introduction of SPP.
	- ranking_ols_r_pre is the mean of the residuals (of the regression of ranking on post) within each small bin, before the introduction of SPP.
	- ranking_ols_r_largeb_post is the mean of the residuals within each bin, before the introduction of SPP.
*/
foreach t in pre post {
bysort small_bins: egen ranking_ols_`t'=mean(ranking)  if `t' == 1 //, by(small_bins) 
bysort small_bins: egen ranking_ols_r_`t'=mean(resid_ols)  if `t' == 1  //, by(small_bins)
bysort large_bins: egen ranking_ols_r_largeb_`t'  = mean(resid_ols)  if `t' == 1
}

	***Adjustment for the constant (so that the average is the same as the data)
/*
We calculate means for the variables ranking_ols_r_pre, ranking_ols_r_post, ranking_ols_r_largeb_pre, ranking_ols_r_largeb_post, and then adjust the values of those variables based on the differences between the mean of the original variable (ranking) and the calculated means on residuals.
*/

foreach t in pre post {
foreach x in ranking_ols_r_`t' ranking_ols_r_largeb_`t' {
quietly sum `x' if `t' == 1. //This quietly calculates the mean of each variable within each group for the specified time period. 
scalar m_`x' = r(mean) // Store the previous mean in a scalar (m_`x')
quietly  sum ranking if `t' == 1  // This calculates the mean of ranking within each group for the specified time period.
scalar ols_ranking = r(mean) // Store the previous mean in a scalar (ols_ranking)
scalar dify = ols_ranking - m_`x' // This calculates the difference between the mean of the original ranking variable and the mean of the residuals variables.
replace `x' = `x' + dify if `t' == 1 // Replace the values of the variables by their adjusted values based on the calculated difference
}
}

	bysort post: sum ranking ranking_ols_r_*  // This shows the summary statistics of ranking and the residuals variables for each time period (before and after the introduction of SPP), 


*______________________________________________________________________
*Quantile estimations depicted in the graph

*With a loop , we run the same code as in the OLS estimation, on each quantile ; that is regress the ranking in Saber score according to controls and passing the Saber exam after the implementation of SPP ; calculation of local percentiles ; and adjust for the constant. 

set maxiter 1000 // This sets the maximum number of iterations to 1000. In quantile regression, the estimation procedure follows a maximization procedure: the algorithm repeats computations (here 1000 repetitions) to find parameter estimates that maximize the loss objective function.


foreach q in 25 50 75 90 {

quietly  qreg ranking ${controls} post , q(`q') vce(r) // Quantile regression of the outcome ranking on controls and being in the post-treatment period. The q(`q) option specifies the quantile being estimated, and the vce(r) option allows for robust standard errors.
predict resid_`q', residuals // Save the residuals from each regression, creating 4 variables resid_`q'.  

	***Calculation of local percentiles:
foreach t in pre post {
egen ranking_p`q'_`t'=pctile(ranking) if `t' == 1, by(small_bins) p(`q') 
egen ranking_p`q'r_`t'=pctile(resid_`q') if `t' == 1, by(small_bins) p(`q') 
egen ranking_p`q'r_largeb_`t' = pctile(resid_`q') if `t' == 1, by(large_bins) p(`q') 
}


	***Adjustment for the constant (so that the average is the same as the data)
foreach t in pre post {
foreach x in ranking_p`q'r_`t' ranking_p`q'r_largeb_`t' {
quietly  sum `x' if `t' == 1
scalar m_`x' = r(mean)
qui sum ranking if `t' == 1 , d 
scalar p`q'_ranking = r(p`q')
scalar dify = p`q'_ranking - m_`x' 
replace `x' = `x' + dify if `t' == 1
}
}
}


*______________________________________________________________________
*One will be used for counting and then weight based on the number of observations used to calculate the percentile (it is frequent using quantiles that multiple observations take the same value. Instead of counting them as one observation, each of the observations is assigned a weight). For example, if you have three observations taking the same value, counting them as one observation and assigning them a weight of 3 reflects the fact that these three observations contribute to the percentile calculation.

**For predictions, we need to replace each control by its average value:

foreach x in cities other_urban father_educ_prim father_educ_second father_educ_high mother_educ_prim mother_educ_second mother_educ_high age sex saber_avg_school department_1 department_2 department_3 department_4 department_5 department_6 department_7 department_8 department_9 department_10 department_11 department_12 department_13 department_14 department_15 department_16 department_17 department_18 department_19 department_20 department_21 department_22 department_23 department_24 department_25 department_26 department_27 department_28 department_29 department_30 department_31 department_32 {

quietly  sum `x' //This quietly calculates the mean of each control.
scalar aux = r(mean) // Store the previous results in the scalar "aux".
quietly  replace `x' = aux // Replace each control variable by its mean value.
}


**We create binary indicator variables (one_pre and one_post) that take the value 1 for observations corresponding to the specified time periods (pre or post, that is if t==1) and 0 for all other observations. 
foreach t in pre post {
gen one_`t' = 1 if `t' == 1
}


**We collapse by bins, so that we keep only 1 observation per bin, which makes us avoid artificial significance through repetition of observations:

collapse ranking_* sisben large_bins eligible_post eligible post sisben_eligible sisben_post sisben_eligible_post  ${controls} (count) one_pre one_post, by(small_bins)
*We end up with only 675 observations, one for each unique value of small bins. 

**For each of the residuals variables, we generate a variable equal to the difference between their pre and post value. We do so in the OLS average and in the quantile estimations. 

foreach x in ranking_ols_r_ ranking_ols_r_largeb_ {
gen `x'dif = `x'post - `x'pre 
}


foreach q in 25 50 75 90 {
foreach x in ranking_p`q'r_ ranking_p`q'r_largeb_ {
gen `x'dif = `x'post - `x'pre 
}
}

*We save the database created in a new file. 
save "bybeans_pre_post_dif.dta", replace 


*______________________________________________________________________
*
*OLS average graph:

use "dataset_LMS.dta", clear

	**Main regression to display in the graph
*reg ranking eligible_post eligible post sisben sisben_eligible sisben_post sisben_eligible_post  ${controls} if abs(sisben)<bw_dif_cersum , ro  

reg ranking eligible_post eligible post sisben sisben_eligible sisben_post sisben_eligible_post  ${controls} if abs(sisben)<bw_dif_cersum , ro  

use "bybeans_pre_post_dif.dta", clear

	***Data preparation 
*Up to now, we compare at the thresold students from the 2014 cohort (post=0) and from the 2015 cohort (post=1). However, to represent the discontinuity effect graphically and construct confidence intervals, you have to get rid of this temporal dimension. To do so we replace each variable that is interacted with post, by the corresponding simple non-interacted variable. 
replace eligible_post = eligible 
replace sisben_post = sisben  
replace sisben_eligible_post = sisben_eligible 

*sisben_post and sisben_eligible_post are idem. 

*We set the values of post eligible sisben and sisben_eligible to 0 for estimation, because they are now present twice in the dataset (under their original name and the name interacted with post, that we just attributed values).
foreach x in post eligible sisben sisben_eligible {
replace `x' = 0
}

	***Predicted values
predict yh_ols, xb // This calculates linear predicted values (creating a new variable yh_ols) from the regression above.  
predict y_stdp_ols, stdp // This calculates standard errors of the prediction xb (saving them in a new variable y_stdp_ols) 


	*** Adjustment for the constant (so that the average is the same as the `q'th percentile)

quietly  sum yh_ols // Calculate mean for the variable yh_ols
scalar m_yh_ols = r(mean) // Store the previous results in a scaler (m_yh_ols) 
quietly  sum ranking_ols_r_dif // Calculate mean for the variable ranking_ols_r_dif
scalar ols_ranking_dif = r(mean) // Store the previous results in a scaler (ols_ranking_dif)
scalar dify = ols_ranking_dif - m_yh_ols // Calculate the difference between the mean of ranking_ols_r_dif and the mean of yh_ols and store it in the scalar (dify).
replace yh_ols = yh_ols + dify // We adjust the values of the variable yh_ols by adding the calculated difference to each observation. 


	***Confidence intervals 
*We create two new variables for the lower and upper bound of the confidence intervals, taking missing values for each observation. 
gen ci_h_ols=. 
gen ci_l_ols=.
*We attribute values to the CI bounds, to estimate confidence intervals at the 95% level. 
replace ci_h_ols = yh_ols+1.96*y_stdp_ols  // For each small bin, we attribute a value to the higher bound of the CI equals to : (the coefficient estimates - 1.96 * the standard error estimated). 
replace ci_l_ols=yh_ols-1.96*y_stdp_ols // Doing the same for the lower bound. 


	*** Makes graph of the main estimation (linear fit on each side):

replace sisben = small_bins // We attribute the values of the variable small_bins to sisben.

	***Graph for average effect using the sisben score at the cutoff

twoway (scatter ranking_ols_r_largeb_dif large_bins if large_bins == small_bins, msymbol(O) mcolor(gray)) /*Scatter plot of ranking_ols_r_largeb_dif against large_bins, for cases where large_bins equals small_bins. Circles (O) are used as symbols with gray color.
*/ (line yh_ols  small_bins if sisben <0, pstyle(p) sort lcolor(blue))/* Add a line plot of yh_ols against small_bins for cases where sisben is inferior to 0. The line has point-style (p), is sorted, and has blue color.
*/ (line  ci_l_ols  small_bins if sisben <0, pstyle(p3 p3) lpattern(dash)  sort  lcolor(green)) /* Add a line plot of ci_l_ols against small_bins for cases where sisben is inferior to 0. The line has point-style (p3 p3), a dashed line pattern, is sorted, and has green color.
*/ (line   ci_h_ols small_bins if sisben <0, pstyle(p3 p3) lpattern(dash)  sort  lcolor(green)) /*
*/ (line yh_ols  small_bins if sisben >0, pstyle (p) sort lcolor(blue)) /*
*/ (line  ci_l_ols  small_bins if sisben >0, pstyle (p3 p3) lpattern(dash)  sort  lcolor(green)) /*
*/ (line  ci_h_ols small_bins if sisben >0, pstyle (p3 p3) lpattern(dash)  sort lcolor(green)), /*
*/  ytitle("Ranking change in average" " ") /// Set the y-axis title 
xtitle("		Eligible         Not Eligible" " " "{it:Sisbén} score (centered at cutoff)") /// Set the x-axis title 
legend( label(1 "Change by bin" ) label(2 "Dif in RD linear prediction")  label(3 "95% CI of linear prediction") order(2 1 3)) /// Legend settings 
title(Average Effect) /// Set the graph title 
graphregion(style(none) color(gs16)) /// Specify the style and color of the graph region.
bgcolor(white) /// Set the background color of the graph to white
xline(0,lcolor(red)) /// Add a vertical line at x-axis value 0 with red color.
name(DifRD_ols, replace) ///Name the graph 

graph export "DIf_RD_Fig_Lin_ols.png", replace /// Export the graph into a png format. 


*______________________________________________________________________
*Quantile graphs:
*We redo the same procedure as in the OLS estimation, with a loop to get one graph for each quantile. 
 
foreach q in 25 50 75 90 {
use "dataset_LMS.dta", clear

quietly  qreg ranking eligible_post eligible post sisben sisben_eligible sisben_post sisben_eligible_post  ${controls} if abs(sisben)<bw_dif_cersum , q(`q') vce(r)  

use "bybeans_pre_post_dif.dta", clear

*data preparation
replace eligible_post = eligible
replace eligible_post = 1 if eligible_post > 0.5  // to adjust one case that is slightly in between but with average like .85
replace sisben_post = sisben
replace sisben_eligible_post = sisben_eligible

foreach x in post eligible sisben sisben_eligible{
replace `x' = 0
}

*linear predictions
predict yh_`q', xb
predict y_stdp_`q', stdp

*confidence intervals 
gen ci_h_`q'=.
gen ci_l_`q'=.
replace ci_h_`q'=yh_`q'+1.96*y_stdp_`q' 
replace ci_l_`q'=yh_`q'-1.96*y_stdp_`q'


*Adjustment for the constant (so that the average is the same as the `q'th percentile)

quietly  sum yh_`q'
scalar m_yh_`q' = r(mean)
quietly sum ranking_p`q'r_dif
scalar p`q'_ranking_dif = r(mean)
scalar dify = p`q'_ranking_dif - m_yh_`q'
replace yh_`q' = yh_`q' + dify

replace ci_h_`q'=yh_`q'+1.96*y_stdp_`q' 
replace ci_l_`q'=yh_`q'-1.96*y_stdp_`q' 

replace sisben = small_bins 
 
* Makes graph of the main estimation for percentiles 25, 50, 75 and 90 (linear fit on each side):

twoway (scatter ranking_p`q'r_largeb_dif large_bins if large_bins == small_bins, msymbol(O) mcolor(gray)) /*
*/ (line yh_`q'  small_bins if sisben <0, pstyle(p) sort lcolor(blue)) /*
*/ (line  ci_l_`q'  small_bins if sisben <0, pstyle(p3 p3) lpattern(dash)  sort  lcolor(green)) /*
*/ (line   ci_h_`q' small_bins if sisben <0, pstyle(p3 p3) lpattern(dash)  sort  lcolor(green)) /*
*/ (line yh_`q'  small_bins if sisben >0, pstyle (p) sort lcolor(blue)) /*
*/ (line  ci_l_`q'  small_bins if sisben >0, pstyle (p3 p3) lpattern(dash)  sort  lcolor(green)) /*
*/ (line  ci_h_`q' small_bins if sisben >0, pstyle (p3 p3) lpattern(dash)  sort lcolor(green)), /*
*/  ytitle("Ranking change in `q'{superscript:th} percentile" " ") xtitle("		Eligible         Not Eligible" " " "{it:Sisbén} score (centered at cutoff)") legend( label(1 "Change by bin" ) label(2 "Dif in RD linear prediction")  label(3 "95% CI of linear prediction") order(2 1 3)) title(`q'th percentile) graphregion(style(none) color(gs16))  bgcolor(white) xline(0,lcolor(red)) name(DifRD_`q', replace)

graph export "DIf_RD_Fig_Lin_`q'.png", replace
}
 
*______________________________________________________________________
*Merge the 5 graphs into one. 

net install grc1leg, from (http://www.stata.com/users/vwiggins) // Install the package to be able to use the grc1leg command (. 

grc1leg DifRD_ols DifRD_25 DifRD_50, rows(1) name(row_1,replace) graphregion(color(white)) //  This creates a single-row graph with three graphs arranged in a single row, named "row1".
grc1leg DifRD_75 DifRD_90, rows(1) name(row_2, replace) graphregion(color(white)) //  This creates a single-row graph with 2 graphs arranged in a single row, named "row2".
grc1leg row_1 row_2, cols(1) graphregion(color(white)) // This merges row1 and row2 in a single one column graph. 

graph export "figure_4.png", replace


***************************************************************************************
*********    Table 3 - Difference-in-Discontinuities estimations       *********
          *of  the motivational effect on ranks of Saber 11 test scores                  
***************************************************************************************

*This replicates Table 3 reporting the regression discontinuity estimates of the opportunity to receive the scholarship at the need-based eligibility cutoff (column 1) and for the distributional effects of the scholarships in columns 2-5
*______________________________________________________________________
*Preparation for the replication of table 3

use "dataset_LMS.dta", clear

*Set the optimal bandwidth determining treatment. The authors use the ones suggested by Calonico et al. (2014). We compare students within a 3.35 points/bandwidths around the cutoff
scalar bw_dif_cersum =  3.3502511

*Set a global for all the control variables used in regressions
global controls cities other_urban father_educ_prim father_educ_second father_educ_high mother_educ_prim mother_educ_second mother_educ_high age sex department_1-department_32 saber_avg_school

*______________________________________________________________________
*Regression for mean effect. 

*We regress at the eligibility cutoff the ranking in the Saber 11 on variables for whether students are eligible and pass the Saber 11 exam in 2015. The coefficient of interest (variable eligible_post) gives the change in discontinuity in test scores before and after the introduction of SPP.

reg ranking eligible_post eligible post sisben sisben_eligible sisben_post sisben_eligible_post  ${controls} if abs(sisben)<bw_dif_cersum , robust //The optimal bandwidth restricts the regression to the subsample of students whose distance between the Sisben score and the need-based eligibility cutoff is inferior to 3.35. 

outreg2 using "DIF_RD_main.xls", addtext(Quantiles,"OLS Dif RD") ctitle("LATE") less(1) keep(eligible_post) nocons replace


*______________________________________________________________________
*Regression for quantile effects. 

*We reproduce the same regression as in mean effect, this time on each quantile of the student's distribution.  

set maxiter 1000 // This sets the maximum number of iterations to 1000. In quantile regression, the estimation procedure follows a maximization procedure: the algorithm repeats computations (here 1000 repetitions) to find parameter estimates that maximize the loss objective function.

*Use a loop to repeat the regression on each quantile, and export the final table into excel format.
foreach q in 25 50 75 90 {
qreg ranking eligible_post eligible post sisben sisben_eligible sisben_post sisben_eligible_post  ${controls} if abs(sisben)<bw_dif_cersum , q(`q') vce(robust)  

outreg2 using "DIF_RD_main.xls", addtext(Quantiles,"`q' Dif RD") ctitle("`q'") less(1) keep(eligible_post) nocons append
}



**************************************************************************************
* FIGURE A2. DENSITY OF THE SISBÉN INDEX AROUND THE SOCIOECONOMIC ELIGIBILITY CUTOFF *
**************************************************************************************
*This replicates Figure A2 testing for manipulation around the eligibility cutoff employing the local polynomial density estimation method

use "dataset_LMS.dta", clear


keep if year == 2015

rddensity sisben, p(1) // runs a regression discontinuity analysis, specifying a first-order polynomial (linear regression) around the cutoff point in the "sisben" variable, calculation of the P-Value

rddensity sisben if area_sisben==1, p(1) //same but when the area taken into account is the 14 largest colombian cities

rddensity sisben if area_sisben==2, p(1) //same but when area_sisben= when the area taken into account is the other cities

rddensity sisben if area_sisben==3, p(1) //same but when area_sisben=3 when the area taken into account is rural


graph drop _all //drop all existing graphs

*______________________________________________________________________
*Replication of Figure A2

***Replicate first graph of Figure A1
twoway (histogram score_sisben if area_sisben==1, fcolor(black) bcolor(gray)) ///
(scatteri 0 56.32 0.025 56.32 (9), c(l) m(i) color(red)), /// plots a single red line at coordinates (0.025, 56.32) 
text(0.025 57.21 "14 Cities", place(e) size(medium)) /// adds the text annotation for the line 
text(0.025 0 "P-Val=.3183", place(e) size(medium)) /// adds the p-value at the top left of the graph
legend(off) xtitle("{it:Sisbén} -  Socioeconomic Index") ylabel(0(.01).025) /// no legend, name of the var on the x- and y-axis
ytitle("Density") graphregion(style(none) color(gs16)) name("histogram_14cities", replace)  // title
graph export "$histogram_14cities.png", replace // Exports the graph as a PNG 

***Replicate second graph of Figure A1

twoway (histogram score_sisben if area_sisben==2, fcolor(black) bcolor(gray)) ///
(scatteri 0 57.21 0.025 57.21 (3), c(l) m(i) color(red)), ///
text(0.025 58.32 "Urban", place(e) size(medium)) ///
text(0.025 0 "P-Val=.7747", place(e) size(medium)) ///
legend(off) xtitle("{it:Sisbén} -  Socioeconomic Index")  ylabel(0(.01).025) ///
ytitle("Density") graphregion(style(none) color(gs16)) name("histogram_urban", replace) 
graph export "histogram_urban.png", replace

***Replicate third graph of Figure A1
twoway (histogram score_sisben if area_sisben==3, fcolor(black) bcolor(gray)) ///
(scatteri 0 40.75 0.04 40.75 (9), c(l) m(i) color(red)), ///
text(0.04 41.75 "Rural", place(e) size(medium)) ///
text(0.04 0 "P-Val=.1285", place(e) size(medium)) ///
legend(off) xtitle("{it:Sisbén} -  Socioeconomic Index") ylabel(0(.01).035) ///
ytitle("Density") graphregion(style(none) color(gs16)) name("histogram_rural", replace) 
graph export "histogram_rural.png", replace


***Put the three graphs together
graph combine histogram_14cities histogram_urban histogram_rural, ///
	rows(3) graphregion(style(none) color(gs16)) ///
	imargin(medsmall) xcommon ycommon

***export the three graphs combined
graph export "figure_A2.png", replace


