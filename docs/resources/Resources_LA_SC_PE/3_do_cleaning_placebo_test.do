clear mata
capture log close
set more off

********************************************************************************
*********************** CLEANING DO FILE 3 *************************************
************* REPLICATION - ATWOOD (2022) - PLACEBO DATASET ********************
********************************************************************************

*This do file creates the dataset used to perform a placebo test (Table 5) of this paper. It uses both the measles incidence rate of each state between 1952 and 1963, and labor market outcomes of individuals from the ACS, 1960-70, which should not be affected by the vaccine.


global home "C:\Users\elsap\Dropbox\replication_project_LA_SC_PE\resources"

global tables  			"$home/output_replication/tables"
global figures 			"$home/output_replication/figures"
global do_files      	"$home/do_files_replication"
global data    			"$home/data_replication"
global raw		    	"$home/raw_data"
global logs   	 		"$home/logs_replication"


**# PLACEBO TEST DATA CLEANING - ACS ********************

use "$raw/false_19601970_census.dta", clear


*Inclusion criteria *******************************

*keep only the 25<age<=60
keep if age>25
keep if age<=60


*keep only those native born
generate native=bpl<57
replace native=. if bpl==.

keep if native==1


*keep only black and white people observations
gen white=race==1
gen black=race==2
gen other=race>2

gen blackwhite=1 if white==1 | black==1

keep if blackwhite==1


*OUTCOME VARIABLES****************************

*labor force participation
gen labforcepart=labforce==2
*employed
gen employed=empstat==1

*generate years of schooling
*generate other educational groups
gen edu_years2=0 if educ==0

local i = 9
forval j = 3/11{
	replace edu_years2= `i' if educ==`j'
	local i = `i' + 1
}

replace edu_years2=0 if educ==1 & educd==0
replace edu_years2=0 if educ==1 & educd==1
replace edu_years2=0 if educ==1 & educd==2
replace edu_years2=0 if educ==1 & educd==11
replace edu_years2=0 if educ==1 & educd==12

replace edu_years2=1 if educ==1 & educd==14
replace edu_years2=2 if educ==1 & educd==15
replace edu_years2=3 if educ==1 & educd==16
replace edu_years2=4 if educ==1 & educd==17

replace edu_years2=5 if educ==2 & educd==22
replace edu_years2=6 if educ==2 & educd==23
replace edu_years2=7 if educ==2 & educd==25
replace edu_years2=8 if educ==2 & educd==26

*interaction for birthplace and education years
gen bpl_edu=bpl*edu_years2
*interaction for birth year and education
gen byr_edu=birthyr*edu_years2

*Dummy for being after the vaccine introduction
generate post_vaccine=year>=1964


*Create control variables**************************************


*female
gen female=sex==2

*interactions 
gen sexpost=sex*post
gen racepost=race*post
gen blackfemale=black*female
gen femalepost=female*post
gen blackfemalepost=blackfemale*post
gen blackpost=black*post


*metro has three categories - rural, city, suburbs
gen metropost=metro*post
gen rural=metro==1
replace rural=. if metro==.
gen ruralpost=rural*post


*family income cubed
*make negative values and 9999999 values = .
gen famincome=ftotinc
replace famincome=. if ftotinc<0
replace famincome=. if ftotinc==9999999
gen famincome2=famincome*famincome
gen famincome3=famincome*famincome*famincome


save "$data/placebo_dataset_acs196070.dta", replace 


*merge with inc_rate.dta

use "$data/inc_rate.dta", clear

rename state bpl_state
rename statefip bpl

keep avg_12yr_measles_rate bpl_state bpl

merge 1:m bpl using "$data/placebo_dataset_acs196070.dta"
drop _m

generate M_post_rate=avg_12yr_measles_rate*post_vaccine 
generate M_post_rate_scale=(avg_12yr_measles_rate*post_vaccine)/100000


save "$data/placebo_dataset_acs196070.dta", replace 


*Unweighted 12 years measles rates*****
preserve 

collapse (mean) avg_12yr_measles_rate, by(bpl_state)

summ avg_12yr_measles_rate
scalar avg_measles_rate = r(mean)  // Store the mean in a scalar variable

restore

display avg_measles_rate //unweighted 12 years average measles rate 

*generate unweighted (line 3 of the table of main results)
gen unweight_avg_12_measles_rate = avg_measles_rate

save "$data/placebo_dataset_acs196070.dta", replace 


**# TOY DATASET VERSION*************
*In this part of the code, we are cleaning the dataset created by the author, so that we are only keeping the variables that we need for the robustness check.

keep employed labforcepart edu_years2 year rural ruralpost female femalepost blackpost blackfemale blackfemalepost age race statefip  famincome famincome2 famincome3 M_post_rate_scale statefip unweight_avg_12_measles_rate serial hhwt region pernum perwt


*Label variables ****
lab var employed "Employed"
lab var labforcepart "Labor force participation"
lab var edu_years2 "Education"
lab var M_post_rate_scale "Measles exposure 1952-63 * POST"

save "$data/placebo_dataset_acs196070", replace