/*Replication Project
Title : Effects of Copyrights on Science: Evidence from the WWII Book Republication Program
Last modification date : 11/17/2024*/

clear
set more off

global Figs "C:YOUR PATH\figs"
global Prog "C:YOUR PATH\prog"
global Rawdata "C:YOUR PATH\raw data"
global Tables "C:YOUR PATH\tables"

use "${Rawdata}/simplified_dataset.dta", clear

* Make panel balanced
*1- fill any missing period for the variable id so the dataset is set as a balanced panel
tsfill, full 
*2-assign an integer value to each to each field of the 25 mutually exclusive research fields within chemistry and 8 within chemistry.  
egen field_gr = group(field) 
*3-you can see through br command that most of the missing data points are in the early years thats why we will implement the following codes
br
*4- Sort your data by id in asscending and by year_c in desencing order (now the missing data points are at the end)
gsort id -year_c
*5-Download carryforward command if not dowmloaded before.
ssc install carryforward
*6-carryforward command being dowloaded you can use it so most recent available data is carried forward to fill the "early" missing years . So, for each id, the command will take the most recent (non-missing) values of field_gr, math, and publ_year and "carry" them forward to subsequent observations where those variables are missing.
bysort id: carryforward field_gr math publ_year, replace 
*7-now sorte id and year_c ascendingly so the data is in chronological order for each id 
gsort id year_c 
*8-again this step fills in any remaining missing values in field_gr, math, and publ_year for each id from the earliest to the latest year.(no real changes made so was it useful?)
bysort id: carryforward field_gr math publ_year, replace 
replace field_gr = 0 if field_gr == . 
*9-to restrict our analysis to years above 1920 
keep if year_c > 1920   

* Temporary save the dataset we will use it later
preserve
*1-Keep only those 6 variables are going to be included in the temporary dataset.
keep id year_c brp count_eng count_noeng cit_year
*2-to sort them ascendingly  
sort id year_c 
*3- save this dataset that will be used then when constructing the synthetic control
save temp.dta, replace  
restore

*1- We are keeping the variables used for conducting the synthetic control and we are dropping the rest then we declare our data set as panel.
keep cit_year count_eng count_noeng field_gr decl_perc id brp year_c math publ_year 
*2- renaming year_c to year 
rename year_c year 
*3-declare the dataset as a panel data set with id as the panel identifier and year as the as the time variable. 
tsset id year 
*4-important not to have missings as its going to be used in the synthetic controls precedure?
replace count_eng = 0 if count_eng == .
replace count_noeng = 0 if count_noeng == . 
*5-as before this sort your data by id in asscending and by year_c in desencing order?
gsort id -year 
*6-this creats you different dummies for each field 
qui tab field_gr, gen(F) 

/*We are performing Synthetic controls procedure in order to minimize pre-tretment differences between the treated unit (BRP) and the control unit synthetic controls the SCM does so by assigning different weights to the control variables. Here we want to know how the outcomes specifically the number of english citations and non-english citations diverged after 1942 (the implementation date of BRP) we cannot simply compare Swiss and BRP books because they might differ in significant ways beyond the intervention thats why the synthetic method is used, stata has the synth package which we will be using (you have to install it if you dont have it). In order to use the synthetic method we first determine our treatment and control groups for instance BRP is our tratment group and Swiss is our control group  we have to declare the dataset as panel tsset and then we use the synth package.*/

*1-first download if synth has not been installed yet.
ssc install synth 
*2- we want to iterate over a variable we will use levelsof command then we add our variable of interest and we add our conditions (brp==1 and math==1) so its our treatment variable and we create a local macro so it can loop over it and we do the same for the control group (Swiss) 
qui levelsof id if brp == 1 & math == 1, local(BRP)
qui levelsof id if brp == 0 & math == 1, local(Swiss)
*3- we create a loop using foreach command this loop iterates over each group in the treatment group BRP and creates to each book its own synthetic control dataset the variables after the synth package are the outcomes of interest trperiod indicates the intervention year the counit dtermines the control variable. keep(book_`n', replace)is used to create the new dataset. This code will keep running a while. 
foreach n of local BRP {
noisily disp "Book nr. `n'"
tsset id year
synth count_eng count_noeng, trunit(`n') trperiod(1941) counit(`Swiss') keep(book_`n', replace)

} 

*4-and we repeate the same steps for the chemistry fields'books.

qui levelsof id if brp == 1 & math == 0, local(BRP)
qui levelsof id if brp == 0 & math == 0, local(Swiss)
foreach n of local BRP {
noisily disp "Book nr. `n'"
tsset id year
synth count_eng count_noeng, trunit(`n') trperiod(1941) counit(`Swiss') keep(book_`n', replace)

}

/*Now that we have our different synthetic datasets, we have to create our control group, we first create a temporary empty control dataset that will consolidates the synthetic control group data for all treated books. For each treated book it extracts the control books and their synthetic control weights. Merges this with the original dataset using merge command, to gather control books' data. Aggregates the data to calculate synthetic control outcomes (count_eng, count_noeng cit_year) over time using the collapse commande.And finally, appends the synthetic control outcomes to the master control dataset (tempcontr.dta) and saves the changes it keeps iterateing till we have all the synthetic control group.*/
	 
preserve
clear
set obs 1
gen x = .
save tempcontr.dta, replace
restore
qui levelsof id if brp == 1, local(BRP) // here for both fields 
foreach n of local BRP {
preserve
clear
use book_`n'.dta
rename _Co_Number id
rename _W_Weight weight
keep id weight
sort id
merge 1:m id using temp.dta
keep if _m == 3   // only the matched results 
drop _m
drop id
gen id_contr = `n'
collapse (mean) count_eng count_noeng cit_year, by(id_contr year) //summarizes the control group's data for the synthetic control comparison.
gen brp = 0 
append using tempcontr.dta
save tempcontr.dta, replace // now we have our synthetic control group 
restore
}

*Now we add everyting in the same file 
*1- make sure we only have the treated group BPR
keep if brp == 1 
*2-Add the synthetic group file   
append using tempcontr.dta 
*3-Add 50000 to make sure that the books in the synthetic control group and the treated group dont have the same IDs? if feel its not a nessary step  
replace id = id_contr + 50000 if brp == 0
*4-Now we will have a (linking variable) that links each treated and control group   
replace id_contr = id if brp == 1 
*5- Ensure that each group (treated book + its synthetic controls) is consistent in terms of:Whether the group belongs to the "math" category and whether the latest publication year in the group (Year_from).   
bysort id_cont: egen Math = max(math)  
bysort id_cont: egen Year_from = max(publ_year) 
drop if Year_from > year 

*we show now how they constructed figureA13 in the appendix as the figure 1 figure A13 is constructed the same way

preserve
*1-aggregate the count_english in a specific year given brp
collapse count_eng if year >= 1930, by(brp year)  
twoway	(line count year if brp == 1, lc(blue)) (line count year if brp == 0, lp(dash) lc(black)), legend(order(1 "BRP" 2 "Synthetic controls")) xline(1942, lpattern(dash) lcolor(black)) ytitle("Citations per book and year")
graph save "Graph" "C:YOUR PATH\Graph2.gph"
restore 











