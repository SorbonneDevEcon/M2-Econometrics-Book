*Boberg-Fazli´c, N., Lampe, M., Lasheras, P. M., & Sharp, P. (2022). Winners and losers from Agrarian Reform: Evidence from Danish land inequality 1682–1895. Journal of Development Economics, 155, 102813.
*Link to the paper: https://doi.org/10.1016/j.jdeveco.2021.102813
*Link to the original replication package: https://osf.io/jmn5y/?view_only=f18f6d51efe44f04abef6e9042c0163c 

*Replication file prepared by : Auvray Adrien, Carette Anne-Laure and Tarlapan Alina.
*Replicating : Table 1, Figure 5, Table A.3 and Table A.4.

*3. From the article to practice: exploring the replication code 
**3.1 Getting started: database access and required packages

***Open the database*** 
*download and save WinnersandLosers_finaldata.dta from: https://osf.io/jmn5y/files/osfstorage?view_only=f18f6d51efe44f04abef6e9042c0163c
*define your working directeory, where you also just stored the dataset
cd "C:\Users\" /*C:\Users\ = path where you also store the dataset*/

use "WinnersandLosers_finaldata.dta", clear
keep ID BygLG Lat Long year MLmean Theil_c AggTheil_c gini1682 gini1834 region ln_area LnDistCoast LnDistCPH ln_TotalFarmHK ln_Theil_1682c ln_Theil_1834c ln_Theil_1850c ln_Theil_1860c ln_Theil_1873c ln_Theil_1885c ln_Theil_1895c year_1 Gini ln_TotalFarmHK1682 ln_TotalFarmHK1834 ln_TotalFarmHK1850 ln_TotalFarmHK1860 ln_TotalFarmHK1873 ln_TotalFarmHK1885 ln_TotalFarmHK1895 ln_TotalFarmHK1682_nohouses ln_TotalFarmHK1834_nohouses ln_TotalFarmHK1850_nohouses ln_TotalFarmHK1860_nohouses ln_TotalFarmHK1873_nohouses ln_TotalFarmHK1885_nohouses ln_TotalFarmHK1895_nohouses
save "Dataset_AA_ALC_AT.dta", replace


***Open the database*** 
use "Dataset_AA_ALC_AT", clear

***Install the required packages***
ssc install estout, replace
ssc install ivreg2, replace
ssc install coefplot, replace
ssc install outreg2, replace

*The first package needed is the estout package which allows to make regression tables using regressions previously stored in the Stata memory.

*The second package required is the ivreg2 package which allows to run instrumental variables regressions.

*The third package is the coefplot package, which is used to create coefficients plots which visually represent the estimated coefficients and their confidence intervals. 

*The fourth package is outreg2, which is used to produce illustrative tables of regression outputs. This package is able to write LaTex-format tables.

**3.2 Understanding the replication process: code analysis of Table 1
***3.2.1 OLS regressions by replicating the columns 1,2 and 4 of Table 1

*Column (1) : OLS***
eststo clear
eststo ols1: qui reg D.Theil_c ln_TotalFarmHK ln_area LnDistCPH Lat Long LnDistCoast i.region if year==1834, vce(robust)

eststo ols2: qui reg D.AggTheil_c ln_TotalFarmHK ln_area LnDistCPH Lat Long LnDistCoast i.region i.year if year==1834, vce(robust)

*Column (2) : First stage***
eststo fiv1: qui reg ln_TotalFarmHK MLmean ln_area LnDistCPH Lat Long LnDistCoast i.region if year==1834, vce(robust)

*Column (4) : Reduced form (diff Theil)***
eststo ziv1: qui reg D.Theil_c MLmean ln_area LnDistCPH Lat Long LnDistCoast i.region if year==1834, vce(robust)

*'eststo clear' clears any previously stored estimation results which ensures a clean slate before running the new estimations.

*The function 'qui' for "quietly" allows us to temporarily store the results in the matrix named ols1 (in the 1st regression for example). This function allow us not to display the results of this very regression and store them. The results of the regression are available under the name ols1 for later utilization i.e. for the moment where authors will want to display a table with more specifications.

*The function 'reg' for 'regress' allows us to run an OLS estimation. 

*D.Theil_c ln_TotalFarmHK ln_area LnDistCPH Lat Long LnDistCoast i.region' specifies the variables in the regression equation.

*The 'if year==1834' filters the data to include only observations where the variable year is equal to 1834.

*Finally, vce(robust) specifies robust standard errors for the estimation, addressing potential heteroscedasticity.

***3.2.2 IV regressions by replicating the columns 3,5 and 6 of Table 1

*Column (3) : Second stage (diffTheil)***
eststo ivdiff1: qui ivregress 2sls D.Theil_c ln_area LnDistCPH Lat Long LnDistCoast i.region (ln_TotalFarmHK = MLmean) if year==1834, vce(robust)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 

*Column (5) : Second stage (diffAggTheil)***
eststo ivdiff2: qui ivregress 2sls D.AggTheil_c ln_area LnDistCPH Lat Long LnDistCoast i.region (ln_TotalFarmHK = MLmean) if year==1834, vce(robust)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 

*Column (6) : Second stage (Gini)***
eststo ginihkdiff: qui ivregress 2sls D.Gini ln_area LnDistCPH Lat Long LnDistCoast i.region (ln_TotalFarmHK = MLmean) if year==1834, vce(robust)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 

*First, like in OLS regressions, 'eststo ivdiff1 : qui' allows us to store the estimation results in a matrix named 'ivdiff1'.

*The function 'ivregress 2sls' allows us to run a two-stage IV regression, as indicated by '2sls'.  

*As in the OlS regressions, 'D.Theil_c ln_area LnDistCPH Lat Long LnDistCoast i.region' are the explanatory variables. 

*'(ln_TotalFarmHK = MLmean)'allows us to specify which is the endogenous variable, here 'ln_TotalFarmHK' and its instrument, here 'MLmean'.

*The command 'vce(robust)' uses a robust variance-covariance matrix to address heteroscedasticity and autocorrelation.

*The line 'estat firststage' displays statistics from the first stage of the IV regression. Generally, it is used to assess the validity of the instruments.

*The line 'mat fstat = r(singleresults)' stores the first-stage results in a matrix named 'fstat'.

*Finally, 'estadd scalar Fstat = fstat[1,4]' adds a new scalar variable 'Fstat' to the main regression results. It extracts the F-statistic from the first-stage matrix created 'fstat' and assigns it to 'Fstat'.

***3.2.3 Formatting Table 1, an additional but optional step
esttab ols1 fiv1 ivdiff1 ziv1 ivdiff2 ginihkdiff, se star(* 0.10 ** 0.05 *** 0.01) b(3) r2 var(15) model(12) wrap keep(MLmean ln_TotalFarmHK) mtitles("OLS" "first stage" "second stage (diffTheil)" "reduced form (diff Theil)" "second stage (diffAggTheil)" "second stage (diffGini)" ) stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic") fmt(%9.0fc 2 2)) indicate("Region FE = 2.region" "Geography = LnDistCPH" , labels(Y N)) label

*First, 'esttab ols1 fiv1 ivdiff1 ziv1 ivdiff2 ginihkdiff' specifies the models whose results will be included in the table.
 
*'se star(* 0.10 ** 0.05 *** 0.01)' specifies the display of standard errors with significance stars. The significance levels are denoted by asterisks : * for 0.10, ** for 0.05 and *** for 0.01.

*'b(3)' allows us to limit the number of decimal places for coefficient estimates to 3.

*'r2' allows us to display the value of the coefficient of determination (R2) in the table, indicating the proportion of the variance of the dependent variable explained by the model. 

*'var(15)' allows us to limit the number of decimals displayed for the R2 to 15 digits.

*'model(12)' allows us to specify the maximum number of models to be displayed in the table, so 12 different models.

*'wrap' command allows us to wrap long variable names onto multiple lines.

*'keep(MLmean ln_TotalFarmHK)' allows us to specify which variables are going to be included in the table. Here, only the variables 'MLmean' and 'ln_TotalFarmHK' will be displayed.

*'mtitles()' indicates titles for each of the specified models.

*'stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic")fmt(%9.0fc 2 2))' specifies additional statistics to include in the table, namely the number of observations (N), the R-squared and the F-statistic.

*'indicate("Region FE = 2.region" "Geography = LnDistCPH"', labels(Y N))', first '"Region FE = 2.region"' specifies the inclusion of an indicator variable for fixed effects related to the region. '2.region' indicates that the fixed effects are associated with the variable named 'region' and the value '2' which corresponds here to Jutland. So we have fixed effects for a specific region. Secondly, '"Geography = LnDistCPH"' indicates the inclusion of an indicator variable related to geography. So geographic controls include 'LnDistCPH' as an indicator variable. Finally, 'labels(Y N)' specifies the labels for the indicator variables. So if the observation has the fixed effect or the control there is a "Y" and if not there is a "N". 

*Also, the 'label' option is appended to the end of the 'esttab' command, indicating that variable labels should be included in the table.

**3.3 Understanding the replication process: code analysis of Figure 5
eststo clear	
foreach x in 1682 1834 1850 1860 1873 1885 1895 {
    qui ivregress 2sls ln_Theil_`x'c ln_area LnDistCPH Lat Long LnDistCoast i.region (ln_TotalFarmHK`x' = MLmean) if year==`x', vce(clust ID)
	estimates store coef`x' 
}		
	coefplot coef*, vert yline(0) keep(ln_TotalFarmHK*) graphregion(color(white)) ciopts(recast(rcap) lcol(black)) mcolor(black) ///
	xtick(1(1)7) xlabel(1 "1682" 2 "1834" 3 "1850" 4 "1860" 5 "1873" 6 "1885" 7 "1895", ) grid(b) legend(off)

*'eststo clear' clears any previously stored estimation results which allows to have a clean slate before running the new estimations.

*'foreach x in 1682 1834 1850 1860 1873 1885 1895 {' loops over the specified years.

*'qui ivregress 2sls' allows us to run a 2-stage least squares regression for each year specified in the loop 'x'. The model includes various independent variables 'ln_Theil_`x'c ln_area LnDistCPH Lat Long LnDistCoast', the instrumental variable 'ln_TotalFarmHK`x'' and fixed effects for 'region'.

*The 'if year==`x'' condition limits the observations to the specified year.

*The line 'estimates store coef`x'' allows us to store the estimation results in matrices named 'coef`x'', where 'x' represents the specific year.

*The 'coefplot coef*' creates a coefficient plot based on the stored estimation results and it specifies that it includes all stored estimation results.

*'vert yline(0)' allows us to add a vertical line at 0 for reference.

*'keep(ln_TotalFarmHK*)' keeps only coefficients related to the variable 'ln_TotalFarmHK'.

*'graphregion' specifies the region of the graph where the actual plot is drawn and '(color(white))' sets the background color of the graph to white. 

*'ciopts' controls the appearance of the confidence intervals and '(recast(rcap) lcol(black))' specifies that the confidence intervals should be displayed using a horizontal line ('rcap') and the line color ('lcol') should be black.

*'mcolor' sets the color of the markers (dots) representing coefficient estimates on the plot. Here, it is set to black.

*'xtick(1(1)7)' specifies that tick marks should be placed at positions 1 to 7 on the x-axis, with increments of 1.

*'xlabel(1 "1682" 2 "1834" 3 "1850" 4 "1860" 5 "1873" 6 "1885" 7 "1895", )' assigns labels to the corresponding tick positions on the x-axis.

*'grid(b)' specifies that gridlines should be drawn.

*'legend(off)' indicates that the legend should be turned off.

**3.4 Understanding the replication process: code analysis of Table A.3
***3.4.1 Creation of a loop 
eststo clear
foreach x in 1682 1834 {
	eststo ginihk`x': ivregress 2sls gini`x' ln_area LnDistCPH Lat Long LnDistCoast i.region (ln_TotalFarmHK = MLmean) if year==`x' & gini1834!=., vce(clust ID)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 
}
*'foreach x in 1682 1834' is a loop that iterates over two years, 1682 and 1834.
*eststo ginihk'x' allows us to store the results matrix in 'ginihk'x'', where 'x' is the current year.
**The function 'ivregress 2sls' allows us to run a two-stage IV regression, as indicated by'2sls'.  

*As in the OlS regressions, 'D.Theil_c ln_area LnDistCPH Lat Long LnDistCoast i.region' are the explanatory variables. 

*'(ln_TotalFarmHK = MLmean)'allows us to specify the endogenous variable, here 'ln_TotalFarmHK' and its instrument, here 'MLmean'.

*'if year==x' & gini1834!=.' is a condition to include only observations for the specified year (x) where the variable 'gini1834' is not missing.

*The command 'vce(clust ID)' is used to adjust standard errors in a regression model to account for within-cluster correlation.

*The line 'estat firststage' displays statistics from the first stage of the IV regression. Generally, it is used to assess the validity of the instruments.

*The line 'mat fstat = r(singleresults)' stores the first-stage results in a matrix named 'fstat'.

*Finally, 'estadd scalar Fstat = fstat[1,4]' adds a new scalar variable 'Fstat' to the main regression results. It extracts the F-statistic from the first-stage matrix created 'fstat' and assigns it to 'Fstat'.
	
***3.4.2 Formatting table A.3, an additional but optional step
esttab ginihk1682 ginihk1834, se star(* 0.10 ** 0.05 *** 0.01) b(3) r2 var(15) model(11) wrap keep(ln_TotalFarmHK) mtitles("2nd stage: Gini diff" "2nd stage: gini 1682" "2nd stage: gini 1834") stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic") fmt(%9.0fc 2 2)) indicate("Region FE = 2.region" "Geography = LnDistCPH" , labels(Y N)) label

*Similar to what we saw in section 3.2.3

*First, 'esttab ginihk1682 ginihk1834' specifies the models whose results will be included in the table.
 
*'se star(* 0.10 ** 0.05 *** 0.01)' specifies the display of standard errors with significance stars. The significance levels are denoted by asterisks : * for 0.10, ** for 0.05 and *** for 0.01.

*'b(3)' allows us to limit the number of decimal places for coefficient estimates to 3.

*'r2' allows us to display the value of the coefficient of determination (R2) in the table, which indicates the proportion of the variance of the dependent variable explained by the model. 

*'var(15)' allows us to limit the number of decimals displayed for the R2 to 15 digits.

*'model(11)' allows us to specify the maximum number of models to be displayed in the table, so 11 different models.

*'wrap' allows us to wrap long variable names onto multiple lines.

*'keep(ln_TotalFarmHK)' allows us to specify which variables are going to be included in the table. Here, only the variable 'ln_TotalFarmHK' will be displayed.

*'mtitles()' indicates titles for each of the specified models.

*'stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic")fmt(%9.0fc 2 2))' specifies additional statistics to include in the table which are the number of observations (N), the R-squared and the F-statistic.

*'indicate("Region FE = 2.region" "Geography = LnDistCPH"', labels(Y N))', first '"Region FE = 2.region"' specifies the inclusion of an indicator variable for fixed effects related to the region. '2.region' indicates that the fixed effects are associated with the variable named 'region' and the value '2' which corresponds here to Jutland. So we have fixed effects for a specific region. Secondly, '"Geography = LnDistCPH"' indicates the inclusion of an indicator variable related to geography. So geographic controls include 'LnDistCPH' as an indicator variable. Finally, 'labels(Y N)' specifies the labels for the indicator variables. So if the observation has the fixed effect or the control there is a "Y" and if not there is a "N". 

*Finally, the 'label' option is appended to the end of the 'esttab' command, indicating that variable labels should be included in the table.

**3.5 Understanding the replication process: code analysis of Table A.4
***3.5.1 OLS regressions by replicating the columns 1 and 2 of Table A.4
eststo clear

***Column (1) : OLS***
eststo ols1: qui reg D.Theil_c BygLG ln_area LnDistCPH Lat Long LnDistCoast i.region if year==1834, vce(robust)

eststo ols2: qui reg D.AggTheil_c BygLG ln_area LnDistCPH Lat Long LnDistCoast i.region i.year if year==1834, vce(robust)

***Column (2) : First stage***
eststo fiv1: qui reg BygLG MLmean ln_area LnDistCPH Lat Long LnDistCoast i.region if year==1834 & ln_TotalFarmHK!=., vce(robust)
	
*First, 'eststo ols1' is a command to store the estimation results and the name of the stored results matrix is 'ols1'.

*The function 'qui' for "quietly" allows the temporary storage of the results in the matrix named 'ols1' (in the 1st regression for example). This function allows us not to display the results of this very regression and store them. That said, the results of the regression are available under the name 'ols1' for later utilization i.e. for the moment where authors will want to display a table with more specifications.

*The function 'reg' for 'regress' allows us to run an OLS estimation. 

*Theil_c BygLG ln_area LnDistCPH Lat Long LnDistCoast i.region' specifies the variables in the regression equation.

*'if year==1834 & ln_TotalFarmHK!=.' is a condition that restricts the analysis to observations where the variable 'year' is equal to 1834 and 'ln_TotalFarmHK' is not missing.

*Finally, 'vce(robust)' specifies the use of robust standard errors to account for heteroscedasticity and potential correlation of the error terms.

***3.5.2 IV regressions by replicating the columns 3 and 4 of the Table A.4

***Column (3) : Second stage (diffTheil)***
eststo ivdiff1: qui ivregress 2sls D.Theil_c ln_area LnDistCPH Lat Long LnDistCoast i.region (BygLG = MLmean) if year==1834, vce(robust)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 

***Column (4) : Second stage (diffAggTheil)***
eststo ivdiff2: qui ivregress 2sls D.AggTheil_c ln_area LnDistCPH Lat Long LnDistCoast i.region (BygLG = MLmean) if year==1834, vce(robust)
	estat firststage
	mat fstat = r(singleresults)
	estadd scalar Fstat = fstat[1,4] 

*First, like in OLS regressions, 'eststo ivdiff1 : qui' allows us to store the estimation results in a matrix named 'ivdiff1'.

*The function 'ivregress 2sls' allows us to run a two-stage IV regression, as indicated by '2sls'.  

*As in the OlS regressions, 'D.Theil_c ln_area LnDistCPH Lat Long LnDistCoast i.region' are the explanatory variables. 

*'(BygLG = MLmean)'allows us to specify which is the endogenous variable, here 'BygLG' and its instrument, here 'MLmean'.

*The command 'vce(robust)' uses a robust variance-covariance matrix to address heteroscedasticity and autocorrelation of the error terms.

*The line 'estat firststage' displays statistics from the first stage of the IV regression. Generally, it is used to assess the validity of instruments.

*The line 'mat fstat = r(singleresults)' stores the first-stage results in a matrix named 'fstat'.

*Finally, 'estadd scalar Fstat = fstat[1,4]' adds a new scalar variable 'Fstat' to the main regression results. It extracts the F-statistic from the first-stage matrix created 'fstat' and assigns it to 'Fstat'.

***3.5.3 Formatting Table A.4, an additional but optional step
esttab ols1 fiv1 ivdiff1 ivdiff2, se star(* 0.10 ** 0.05 *** 0.01) b(3) r2 var(15) model(11) wrap keep(MLmean BygLG) mtitles("OLS" "first stage" "second stage (diffTheil)" "second stage (diffAggTheil)" ) stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic") fmt(%9.0fc 2 2)) indicate("Region FE = 2.region" "Geography = LnDistCPH" , labels(Y N)) label

*First, 'ols1 fiv1 ivdiff1 ivdiff2' specifies the models whose results will be included in the table.
 
*'se star(* 0.10 ** 0.05 *** 0.01)' specifies the display of standard errors with significance stars. The significance levels are denoted by asterisks : * for 0.10, ** for 0.05 and *** for 0.01.

*'b(3)' allows us to limit the number of decimal places for coefficient estimates to 3.

*'r2' allows us to display the value of the coefficient of determination (R2) in the table, which indicates the proportion of the variance of the dependent variable explained by the model. 

*'var(15)' allows us to limit the number of decimals displayned for the R2 to 15 digits.

*'model(11)' allows us to specify the maximum number of models to be displayed in the table, so 11 different models.

*'wrap' command allows us to wrap long variable names onto multiple lines.

*'keep(MLmean BygLG)' allows us to specify which variables are going to be included in the table. Here, only the variables 'MLmean' and 'BygLG' will be displayed.

*'mtitles()' gives titles for each of the specified models.

*'stats(N r2 Fstat, labels("Observations" "R-squared" "KP F-statistic")fmt(%9.0fc 2 2))' specifies additional statistics to include in the table which are the number of observations (N), the R-squared and the F-statistic.

*'indicate("Region FE = 2.region" "Geography = LnDistCPH"', labels(Y N))', first '"Region FE = 2.region"' specifies the inclusion of an indicator variable for fixed effects related to the region. '2.region' indicates that the fixed effects are associated with the variable named 'region' and the value '2' which corresponds here to Jutland. So we have fixed effects for a specific region. Secondly, '"Geography = LnDistCPH"' indicates the inclusion of an indicator variable related to geography. So geographic controls include 'LnDistCPH' as an indicator variable. Finally, 'labels(Y N)' specifies the labels for the indicator variables. So if the observation has the fixed effect or the control there is a "Y" and if not there is a "N". 

*Finally, the 'label' option is appended to the end of the 'esttab' command, indicating that variable labels should be included in the table.
