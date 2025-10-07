
*Reference: Braakmann, N., Chevalier, A., & Wilson, T. (2024). Expected returns to crime and crime location. 
*American Economic Journal: Applied Economics, 16(4), 144-160.

*Link to the article: https://www.econstor.eu/bitstream/10419/265741/1/dp15520.pdf
*Link to the original replication package: https://www.openicpsr.org/openicpsr/project/190941/version/V1/view

*Replication file prepared by: Louis Marie, Rebecca Gramiscelli and Victoria Bel

*Academic year: 2024/2025

*****************************************************************************************************
*									       Replication exercise 	            				    *
*									              Do File 	             	                 		*
*																									*
*	     				        	 Reproduces tables 1 and 3 & figure 2                 		    *
*****************************************************************************************************

***************************************************************************************
*********   A/ Generate the data from original replication file               *********
***************************************************************************************

*download and save the original dataset "LSOAFinal.dta" from https://www.openicpsr.org/openicpsr/project/190941/version/V1/view?path=/openicpsr/190941/fcr:versions/V1/Replication-pack/Data/Final&type=folder

clear all
set more off

*set the directory, where you have stored the original dataset and where you will store your results. To do so create a file named "data" in the file that you have defined as home
*global home "C:\Users\XXX"  

*cd "C:\Users\XXX\...\data"


*open the dataset
*use "$home/.../LSOAfinal", clear
use "$home/data/LSOAfinal", clear

*______________________________________________________________________
*Data Preparation      

*keep only the variables we need for the replication
keep BIPshare treat2 Blackshare DEshare urban totpop unemploy burglary robbery vehiclecrime violence totexclburg ///
     lsoacode lsoaid laid month time time2 hypburg hypgoldprice BIPhypgoldpriceOUTLA BIPuqLA BIPiqrLA pfa ///

*Labelling our variables
label var month "Month"
label var time "Time"
label var time2 "Time squared"
label var lsoaid "Lower-layer super output area"
label var laid "Local Authority"
label var pfa "Police force area"
label var hypburg "Burglary"
label var hypgoldprice "Gold Price"
label var BIPshare "Share of BIP population in LSOA"
label var treat2 "Outlier Local Authority" // A neighborhood is considered an outlier if: BIPshare > BIPuqLA + 1.5*BIPiqrLA - That is the threshold defined by the authors.
label var Blackshare "Share of Black population in LSOA"
label var DEshare "Share of social grade DE"
label var urban "Indicator variable for urban areas"
label var totpop "Total population in LSOA of 2011"
label var unemploy "Local unemployment rate"
label var burglary "Number of burglaries reported"
label var robbery "Number of robberies recorded"
label var vehiclecrime "Number of vehicle-related crimes reported"
label var violence "Number of violent crimes reported"
label var totexclburg "Total crime excluding burglary"
label var BIPiqrLA "Interquartile Range of BIPshare within LA"
label var BIPuqLA "Upper Quartile of BIPshare within LA"
label var BIPhypgoldpriceOUTLA "High South Asian neighbourhood X Gold Price" // Authors are giving it like that. But we are going to change that and then use "interact".

*Preparation of data for table 3

*Here we are creating our variable to add in our regressions.
g BIParea=.
g interact=.

replace interact=BIPhypgoldpriceOUTLA 
replace BIParea=interact>0 // So only treated.

label variable BIParea "High South Asian neighbourhood"
label variable interact "High South Asian neighbourhood X Gold Price"

encode pfa, gen(pfa_num) // Converts the string variable 'pfa' into a numeric categorical variable 'pfa_num', assigning a unique code to each category.

save Dataset_BCW, replace // save the clean version of the dataset

***************************************************************************************
*********  B / Replication do-file for the replication exercise               *********
***************************************************************************************

*______________________________________________________________________
* Open the data      

*set the directory, where you have stored the dataset and where you will store your results

use "$home/data/Dataset_BCW.dta", clear

*Each table/figure can be reproduced independently.

*******************************************************************************
*** 			Necessary packages and globals                              ***
*******************************************************************************

* Necessary packages to run the code:
*ssc install estout
*ssc install reghdfe
*ssc install ftools

*Set a global, to export all outputs we are going to make. To do so, create two files, "graphstata" and "texstata" in the file that you have defined as home/directory above.
global graphout "$home/graphstata"
global texout "$home/texstata"

*******************************************************************************
*** 			                 TABLE 1 - Summary Statistics 				***
*******************************************************************************

* In this part, you will replicate the Table 1 of the paper, which shows some demographic and criminal statistics regarding the populational groups we will be using.
* For that, you will first run the means and standard deviations of all characteristics, per group. Then you will export your results all together.

////Replication of Column 3: Treatment Group 

*______________________________________________________________________
*Step 1 : Finding means and sd deviations

/* Comments

eststo: Stata's eststo command stores the estimation results in a model list for later use (e.g., to create comparison tables). This allows you to organize and summarize results across multiple groups.
	** Following the `eststo` command, you can add a name, so it's easy to reference it later.
	** Always remember to `est clear` before running this command to avoid using previously stored results.

summarize: creates main statistics about the given group such as mean, standard deviation, maximum, and minimum values.
	** To find means only for our group of interest, we add the condition `treat2 == 1` to determine the treatment group, as previously explained.
		
estadd: adds custom annotations to stored regression results, like model specifications or contextual details, to enrich descriptions for easier comparison or presentation in tables.
	** We created a `local` variable named `tt` to save the number of months for which we compute information (108 months).
	** We also added a `scalar` variable named `unique_lsoacode`, which gives the number of neighbohoods that fulfill the condition `treat2 == 1`.
	
preserve: this function saves the existing dataset used and allow us to make temporary changes on it, such as calculating variables or creating graphics.
	** Always remeber to `restore` after finishing the temporary changes
	** Here, we use it to calculate the number of neighborhoods for the given condition: the `contract` function keps only the unique values of variable we chose; by creating a `local` variable equal to `_N`, we are defining a temporary variable that represents the count of unique neighborhoods for the specified group.
*/

est clear

** Summarize for control group
eststo control: estpost summarize BIPshare treat2 Blackshare DEshare urban totpop unemploy burglary robbery vehiclecrime violence totexclburg if treat2 == 0
estadd local tt "108"

* Count unique lsoacode for control group  = to find number of neighborhoods
preserve
keep if treat2 == 0
contract lsoacode
local neigh_control = _N  // Store the number of unique neighborhoods in a local macro
restore
* Add the unique count to the eststo object
estadd scalar unique_lsoacode = `neigh_control'


** Summarize for treated group
eststo treated: estpost summarize BIPshare treat2 Blackshare DEshare urban totpop unemploy burglary robbery vehiclecrime violence totexclburg if treat2 == 1
estadd local tt "108"

* Count unique lsoacode for control group
preserve
keep if treat2 == 1
contract lsoacode
local neigh_treated = _N  // Store the number of unique neighborhoods in a local macro
restore
* Add the unique count to the eststo object
estadd scalar unique_lsoacode = `neigh_treated'


* Summarize for total sample
eststo total1: estpost summarize BIPshare treat2 Blackshare DEshare urban totpop unemploy burglary robbery vehiclecrime violence totexclburg
estadd local tt "108"

* Count unique lsoacode for all population
preserve
contract lsoacode
local neighl_all = _N  // Store the number of unique neighborhoods in a local macro
restore
* Add the unique count to the eststo object
estadd scalar unique_lsoacode = `neighl_all'


*______________________________________________________________________
*Step 2 : Export our results in a tex-format table

esttab total1 control treated using "$texout/Table_1.tex", ///
    cells("mean(fmt(3))" "sd(par)") substitute({l} {p{11cm}}) ///
    stat(tt unique_lsoacode N, fmt(%9.0fc %9.0fc %9.0fc) labels("Time periods (months)" "Neighbourhoods" "Obs")) nonum ///
    collabels(none) ///
    mti(Total Control "Outlier in LA") /// 
    title("Summary Statistics by Group") /// 
    addnote("\textit{Notes: The table displays summary statistics at the neighbourhood level (LSOA). The top panel is based on Census 2011 data, quarterly unemployment rate is provided by NOMIS. Monthly Crime data are aggregated at the LSOA level by the authors. Note, that there is no data available for the Greater Manchester Police Force between June and December 2019.}") /// 
    label replace nonumbers nocons nodepvar nostar compress

	
*******************************************************************************
***            TABLE 3  - Impact of Gold Price on Burglaries                ***
*******************************************************************************

* In this part, you will replicate the table 3 that highlights the main results of the paper.
* For that, you will first run the regressions and store the estimates, then you will export your results.

clear all
use "$home/data/Dataset_BCW.dta", clear

est clear //Erase previous estimates stored

*______________________________________________________________________
*Step 1 : Run the regressions

/* Comments for column 4

eststo: Stata's eststo command stores the regression results in a model list for later use (e.g., to create comparison tables). This allows you to organize and summarize results across multiple regressions.

quietly: Suppresses the display of output during the execution of the regression.

reghdfe: Runs a high-dimensional fixed effects regression. This is a robust method for handling large datasets with multiple levels of fixed effects. The variables used were:
	Dependent Variable: hypburg
	Independent Variables: BIParea hypgoldprice i.month
							- BIParea: A binary variable indicating whether a certain condition related to the BIP is met.
							- hypgoldprice: A continuous variable representing hypothetical gold prices, which could influence the outcome.
							- i.month: Includes month categorical variable (values from 1 to 12) to control temporal variations. Indeed, it is likely that there are more burglaries during the summer (and differ across units).
	
	absorb(lsoaid#c.time lsoaid#c.time2): Specifies the fixed effects to "absorb":
							- i.pfa_num; Local Authority Fixed effects
							- lsoaid#c.time: Interaction of the location ID (lsoaid) with a linear time variable (time), controlling for time-specific trends at the location level.
	 						- lsoaid#c.time2: Interaction of lsoaid with a quadratic time term (time2), allowing for nonlinear time trends specific to each location.
							
	cluster(lsoaid): Clusters the standard errors at the location ID (lsoaid) level. This accounts for within-location correlation of errors over time, providing more reliable inference.					
		
estadd: adds custom annotations to stored regression results, like model specifications or contextual details, to enrich descriptions for easier comparison or presentation in tables.
*/
/* According the paper, what link can make between the fourth regression and the first equation in the paper ?

hypburg : yict 
BIParea : SAic
hypgoldprice : GPt
interact : SAic * GPt --> the coefficient associated measures the differential impact of changes in the price of gold on crime across areas with different shares of South Asian households within a local authority.
i.laid : "alpha"c
lsoaid#c.time lsoaid#c.time2 : TRENDit

i.month is not include in their regressions, but we are thinking that is an additional control.

*/

* Col 1
eststo: quietly reghdfe hypburg BIParea hypgoldprice i.month , absorb(lsoaid#c.time lsoaid#c.time2) cluster(lsoaid)
estadd local fe "None"
estadd local time "LSOA"
estadd local tt "108"

* Col 2
eststo: quietly reghdfe hypburg BIParea hypgoldprice interact i.month , absorb(lsoaid#c.time lsoaid#c.time2) cluster(lsoaid)
estadd local fe "None"
estadd local time "LSOA"
estadd local tt "108"

* Col 3
eststo: quietly reghdfe hypburg BIParea hypgoldprice interact i.month , absorb(i.pfa_num lsoaid#c.time lsoaid#c.time2) cluster(lsoaid)
estadd local fe "PFA"
estadd local time "LSOA"
estadd local tt "108"

* Col 4- LA fixed effects, lsoa specific time trend 
eststo: quietly reghdfe hypburg BIParea hypgoldprice interact i.month , absorb(i.laid lsoaid#c.time lsoaid#c.time2) cluster(lsoaid)
estadd local fe "LA"
estadd local time "LSOA"
estadd local tt "108"

* Col 5- LSOA fixed effects, lsoa specific time trend
eststo: quietly reghdfe hypburg BIParea hypgoldprice interact i.month  , absorb(i.lsoaid lsoaid#c.time lsoaid#c.time2) cluster(lsoaid)
estadd local fe "LSOA"
estadd local time "LSOA"
estadd local tt "108"

*______________________________________________________________________
*Step 2 : Export our results in a tex-format table 

esttab using "$texout/Table_3_Main.tex", replace b(3) se(3) nonote compress nomti substitute({l} {p{16cm}}) stat(fe time tt N_clust N, fmt(%9.0f %9.0f %9.0f %9.0f %9.0f) labels("Fixed Effect" "Quadratic Time Trend" "Time Periods" "LSOAs" "Obs")) ///
keep(BIParea hypgoldprice interact) order(BIParea hypgoldprice interact) ///
coef( BIParea "High South Asian neighbourhood" hypgoldprice "Gold Price"  interact "High South Asian neighbourhood x Gold Price") addnote("Notes: The table displays estimates of the impact on burglaries estimated using Eq.1. Regressions also control for seasonality via monthly dummies. Standard errors adjusted for clustering at the LSOA level in parentheses. */**/*** denote statistical significance on the 10\%, 5\% and 1\% level respectively.") title("Table 3: Impact of Gold Price on Burglaries")


*******************************************************************************
***                    	  Robustness: FIGURE 2 - Placebo                    ***
*******************************************************************************

* In this part, you will replicate the robustness test of randomization placebo.

/* Randomization Placebo
The placebo randomization tests whether the results are robust to the potentially arbitrary definition of treated neighborhoods (outliers of BIPshare). Unlike in classic DiD designs, where treatment is exogenously defined (e.g., by policy), here the researchers define treatment using a statistical threshold, allowing for randomization. By randomly assigning the treated status 1,000 times and recalculating the estimated effects, they compare these placebo results to the actual coefficients. If the real results differ significantly from the random ones, it validates that the findings are not driven by the threshold choice (or randomness) but by the actual relationship being studied.
*/

clear all
use "$home/data/Dataset_BCW.dta", clear

est clear

set seed 12345 // Ensures the same distribution is obtained each time. Essential for result traceability.
set matsize 5000 // Expands the maximum size for matrices, essential for handling large data or storing results during iterative procedures.

keep laid lsoaid time time2 BIPshare hypgoldprice BIPhypgoldpriceOUTLA month hypburg BIPuqLA BIPiqrLA BIParea interact // select only relevant variables to speed up computation time
compress //Optimizes variable types to reduce memory usage.

save a, replace //Saves the reduced dataset as a new file for subsequent use.
keep if time==1 //Filters the dataset to include only observations for the first time period. This is because BIPshare is assumed constant over time, so only the initial period is needed for randomization.

*______________________________________________________________________
*Step 1 : Create the random distribution

/* Comments
To reduce calculation time, we can reduce the number of distributions to 25 instead of 1000, the statistical accuracy of the results is decreased, but we can explain that this is to enable faster calculations. 

- forvalues i=1(1)25: Executes a loop to generate random distributions. 
- bys laid (lsoaid) : Divides the data into groups based on the variable laid. Within each group, the data is sorted by lsoaid.
- gen randi' = runiform(0,1)`: Generates uniformly distributed random numbers between 0 and 1. Simulates random assignment of treated neighborhoods for placebo tests.
*/

* Generates random numbers uniformly distributed between 0 and 1 for each LSOA.
* Simulates a random treatment assignment within each LA.
forvalues i=1(1)25{		
bys laid (lsoaid): g rand`i'=runiform(0,1)
} 

* Sorts the LSOAs by the random numbers (`rand`i'`) within each LA.
* Assigns a sequential order (`random`i'`) to LSOAs based on the sorted random numbers.
* Creates a new randomized BIPshare variable for each iteration.
forvalues i=1(1)25{	
bys laid (rand`i'): g random`i'=_n						// Generates a sequential index (`random`i'`) for LSOAs based on the sorted random numbers.		
bys laid (lsoaid): g BIP`i'rand=BIPshare[random`i']		// Assigns a randomized BIPshare value to each LSOA within its LA.
}

/* Hypothesis tested:
   - Null hypothesis (H0): The relationship between BIP and hypburg is random.
     If H0 is true, the coefficients obtained with the real data should not differ from those obtained with the random data.
   - Alternative hypothesis (H1): The relationship between BIP and hypburg is significant and non-random.
*/

keep laid lsoaid BIP*rand 
save "$home/data/tempLSOA", replace
clear
use a // Reloads the original dataset to prepare for merging with the randomized data.


merge m:1 laid lsoaid using "$home/data/tempLSOA", nogen //Merges the main dataset with the generated random distributions.
erase "$home/data/tempLSOA.dta"

*______________________________________________________________________
*Step 2 : Regress the new distribution and store the results

reghdfe hypburg BIParea hypgoldprice interact i.month , absorb(i.laid lsoaid#c.time lsoaid#c.time2)		/* Actual BIP distribution same as column 4 without the clustering*/

mat B=[_b[interact], _se[interact]] // Stores coefficients and standard errors from regressions.				

/* Why the following code is so long to run?
This loop may take approximately 24 hours to run with 1,000 randomizations! With "only" 25 randomizations, the code processes each of the 36,000 LSOAs by:
1. Generating 25 random BIP distributions.
2. Running one regression for each random distribution.
This results in approximately 900,000 regressions in total.
*/

forvalues i=1(1)25{
	
gen BIPhypgoldout`i'=(BIP`i'rand>=(BIPuqLA+(1.5*BIPiqrLA)))*hypgoldprice
gen BIPareaout`i'=BIPhypgoldout`i'>0
 reghdfe hypburg  BIPareaout`i' hypgoldprice BIPhypgoldout`i' i.month , absorb(i.laid lsoaid#c.time lsoaid#c.time2)
mat B=[B\_b[BIPhypgoldout`i'], _se[BIPhypgoldout`i']]
drop BIPhypgoldout`i' BIPareaout`i'
}
   
//Two first lines of the loop above:
    * Creates a new variable (`BIPhypgoldout`i'`) to identify outlier BIPshare values from the random distribution.
    * Outliers are defined as values greater than the upper quartile (`BIPuqLA`) plus 1.5 times the interquartile range (`BIPiqrLA`).
    * These outliers are then multiplied by `hypgoldprice`.
    * Converts the outlier variable (`BIPhypgoldout`i'`) into a binary indicator.
    * This defines a "treated area" based on the randomized BIP distribution.
	
//The third line of the loop above:
	* Regresses `hypburg`

//The 4th line stores the results. Appends the coefficient and standard error of the `BIPhypgoldout`i'` variable from the current regression to the matrix `B`.

//The 5th line deletes the variables specific to the current iteration to free memory and avoid conflicts in the next loop iteration.
	
*______________________________________________________________________
*Step 3 : Export as a graphic

//Creates a new Excel file for each matrix `m` (stored coefficients and standard errors).
//Writes the matrix `m` to the first cell (A1) of the corresponding Excel file. 
 
foreach m in  B {
putexcel set "$texout/randdist`m'", replace
putexcel A1= matrix(`m')
}

import excel "$texout/randdistB", clear // Imports the combined Excel file with all the stored matrices into Stata for further analysis.
gen num=_n // Creates a new variable `num` as a sequential identifier for each row of the imported dataset.
su A if num==1 // Calculates summary statistics for the variable `A` in the first row of the dataset.
local BIP=r(mean) // Stores the mean of `A` (from the first row) in the local macro `BIP`.
count // Counts the total number of observations in the dataset.
local obs=(r(N) - 1) // Stores the number of rows minus one (excluding the first row) in the local macro `obs`.
drop if num==1 // Deletes the first row from the dataset.
su A // Summarizes the remaining observations of `A` to understand its distribution.			
reg A // Runs a regression on the variable `A`.
test _cons=`BIP' // Conducts a hypothesis test to compare the constant term (`_cons`) from the regression with the stored mean value (`BIP`).
kdensity A, generate(beta density) //Generates a density estimate to visualize the distribution of estimated coefficients.
two line density beta, xtitle(Beta) xlabel(-0.06(0.02)0.06) ylabel(0(5)25) xline(`BIP') graphregion(color(white)) ytitle(Density) // Creates a line plot showing the kernel density of coefficients (`density`) against `beta`. Adds a vertical line at the mean coefficient (`BIP`) to visually compare the real result with the random coefficients.
graph export "$graphout/Figure_2.pdf", replace as(pdf) //Exports the density plot.

clear 
erase a.dta


	
