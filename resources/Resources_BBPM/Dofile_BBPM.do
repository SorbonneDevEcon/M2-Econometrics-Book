/*Replication Project
Title : Effects of Copyrights on Science: Evidence from the WWII Book Republication Program
Last modification date : 20/12/2024*/

*clean our environment 
clear
set more off

*libraries 
ssc install estout
ssc install reghdfe
ssc install ftools

*directories 
global Figs "C:Your_Path\figs"
global Prog "C:Your_Path\replication paper\prog"
global Rawdata "C:Your_Path\raw data"
global Tables "C:Your_Path\tables"

// table options 
global options = "label b(3) se(3) starlevel(* .1 ** .05 *** .01)"

*Load and clean the original dataset
use "${Rawdata}/brp_dataset", clear

* Drop variables you don't need 
drop p_original p_reproduction name title publisher licensee nuc emigre emigre_us text ads

* Save the cleaned dataset
save "${Rawdata}/simplified_dataset", replace

* Load the simplified dataset for analysis
use "${Rawdata}/simplified_dataset", clear


* Generate "English" treatment variable & reshape file
gen count1 = count_eng
gen count0 = cit_year - count_eng
// in order to ensure that there is not negative values
replace count0 = 0 if count0 < 0  
// fakeid is used as an identifier for each observation used in the next step
egen fakeid = group(id year_c)  
reshape long count, i(fakeid) j(english) 
 // reshape long combines count0 and count1 into a single count variable that takes both set of values and the english varibale indicates whether a certain obervation is form count0 or coun1 
egen field_gr = group(field) 
// will we use it later (for instance this creates groups for different values in the field)
label var english "English"
label var count "count of citations"

*Figure 1 

*1-makes sure that the dates are sorted so the graph would make sense
sort year_c 
 
*2- We will use preserve to temporarly make changes and then restore is used to get back the initial dataset that is not restricted to >1929 and can have brp that are 0
preserve 
keep if year_c >1929  
drop if brp == 0

*3-collapse(mean) is used to average the data by year_c and english
collapse (mean) count, by(year_c english post)  
twoway (line count year_c if english == 1, lcolor(black) lpattern(solid) lwidth(medium)) (line count year_c if english == 0, lcolor(blue) lpattern(dash) lwidth(medium)), xline(1942, lcolor(black) lpattern(dash)) legend(order(1 "English" 2 "Other") pos(11) ring(0)) ytitle("Citation per book and year") xtitle("Years") ylabel(0(0.2)0.8) xlabel(1930(10)1970) title("Citations to BRP Books from New Work in English versus Other Languages")
graph save "${Figs}/Graph1.gph", replace 

restore 

*table 1 the OLS regression (the authors want to see the impact of BRP on citations of english versus other languages)
preserve 
keep if brp == 1 
*the c.english#c.post is used to do an interaction between those two variables, we clustered by id to take the correlation into account the eststo stores the regression results into r1 that will be used in order to construct our final table with the different fixed effects.
eststo r1: reghdfe count english c.english#c.post, absorb(id year_c) cluster (id) dof(none)
*in order to calculate the mean of the dependent variable here'count' for a subset of the sample here for citations of english language authors before 1941 get the percentage increase in citations in response to brp. we will store the results in r(mean) that is considered a temporary macro. e(sample) is used to restrict the calculation to observations that were included in the regression above.
qui sum count if e(sample) & year_c <= 1941 & english == 1 

*estadd is used to add a single value to the stored regression ans scalar creates a new scalr named ymean in order that is assigned the value of r(mean) 
estadd scalar ymean = `r(mean)' 
 
*if we dont want to rewrite over and over again the same regression with different fixed effects we can define a local macro for instance spec which will save you time instead of rewrite the code over and over to do so we will write the following codes 

*estadd local ensures that the added statistic is temporary and tied to the current session. This is useful when you want to include specific information in your output without permanently altering the original estimation results.

local spec = "english c.english#c.post"
eststo r1: reghdfe count `spec', a(id year_c) cluster(id) dof(none)
estadd local citation_year_FE "Yes":r1
estadd local book_FE "Yes":r1
estadd local field_citation_FE "No":r1
estadd local pub_year_citation_year_FE "No":r1
estadd local publication_year_FE "No":r1
estadd local field_FE "No":r1
estadd local book_publication_year_FE "No":r1

*we now are going to repeat what we have done for the first regression (column) but we will change now the fixed effects each time to account for the variations of different combinations.
*we used in the second regression i. instead od c. to create the interaction because they are categorical variables the interaction here models the combined effect of the year and field categories they used those fixed effects to capture the variation accross fields over time 
 eststo r2: reghdfe count `spec', a(id year_c i.field_gr#i.year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & english == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r2
estadd local book_FE "Yes":r2
estadd local field_citation_FE "Yes":r2
estadd local pub_year_citation_year_FE "No":r2
estadd local publication_year_FE "No":r2
estadd local field_FE "No":r2
estadd local book_publication_year_FE "No":r2

* In column 3 the fixed effects the author used are used to controlfor variation in citations across the life cycle of a book
eststo r3: reghdfe count `spec', a(id year_c i.publ_year#i.year_c) cluster(id) dof(none) 
qui sum count if e(sample) & year_c <= 1941 & english == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r3
estadd local book_FE "Yes":r3
estadd local field_citation_FE "No":r3
estadd local pub_year_citation_year_FE "Yes":r3
estadd local publication_year_FE "No":r3
estadd local field_FE "No":r3
estadd local book_publication_year_FE "No":r3

//column 4 
eststo r4: reghdfe count `spec', a(field_gr publ_year year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & english == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r4
estadd local book_FE "No":r4
estadd local field_citation_FE "No":r4
estadd local pub_year_citation_year_FE "No":r4
estadd local publication_year_FE "Yes":r4
estadd local field_FE "Yes":r4
estadd local book_publication_year_FE "No":r4

//column 5
eststo r5: reghdfe count `spec', a(i.id#i.year_c) cluster(id) 
qui sum count if e(sample) & year_c <= 1941 & english == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r5
estadd local book_FE "No":r5
estadd local field_citation_FE "No":r5
estadd local pub_year_citation_year_FE "No":r5
estadd local publication_year_FE "No":r5
estadd local field_FE "No":r5
estadd local book_publication_year_FE "Yes":r5

/* Now that we have all the regressions stored from r1 to r5 and the rmean are stored in ymean as well its time to get the final table, we will use the esttab command to generate a table using  the stored regressions
using "$Tables/table1.txt", replace saves the output as a text file at the ${table} path definied above and overwrites it if it exists 
we use $option as a global macro here to avoid rewrite the same options another time and save time (the global has been definied and explained above)
-(drop_constant) to drop our constant 
-stat() includes wich statistics to display:-N is for the number of observations
										    -r2 is to include the Rsquare
										    -ymean to include the mean of the dependent variable
										    -then we list the fixed effects included in the five regressions above
											-fmt(0 3 3): Format for each statistic meaning the number of decimal places so the 0 (integer) for the N since its number of observations and 3 for  r2 and ymean meaning 3 decimals places
											
-label is the descriptive name used to make those statics readable.
-nomtitle deletes model titles (default is to display r1, r2, etc., as titles).
-booktabs formats the table using the LaTeX booktabs style, which improves table appearance.
-nogaps removes extra spacing between rows in the table, making it more compact. 
-nonum deletes the numbering of models
*/

esttab r1 r2 r3 r4 r5 using "$Tables/table1.tex", replace $options drop(_cons) stat(citation_year_FE book_FE field_citation_FE pub_year_citation_year_FE publication_year_FE field_FE book_publication_year_FE N r2 ymean , fmt(0 3 3) label( `"Citation-Year FE"' `"Book FE"' `"Field-Citation FE"' `"Publication-Year-Citation-Year FE"'`"Publication-Year FE"' `"Field FE"' `"Book-Publication-Year FE"'`"N"' `"R2"' `"Mean of dep var"')) nomtitle booktabs nogaps title("Table 1—OLS, Effect of BRP on Citations—English versus Other Languages")
restore 

******************************************************************
/*Since it is a triple difference now we will explain the second identification stragy that will be afterwards combined with their first. Their second identification strategy relies on comparing after 1941 the english-language citations to BRP books with English-language citations to Swiss books that were not eligible to BRP. This identification is used to make sure that this increase in citations is not caused by post war investments in science made by the USA. 
To crate a comparable sample of Swiss books the authors use the Mahalanobis propensity score matching. So, they matched each BRP book with a Swiss book in the same research field and with a comparable pre-BRP stock of non-English-language citations wich will be used constructing table2 . They used also an alternative method wich is the synthetic control and we will be explaining it we will need a other do file to do it, now lets replicate table 2.*/

*The Table below shows the effect of BRP on english language citations versus Swiss Books.
* Table 2
preserve
*Since here you want to calculate the impact for a subset of the sample mainly the books that have been matched with swiss books by the Mahalanobis propensity score 
keep if english == 1 & matched == 1
*the main regression is citesit = βBRPi × postt + booki + τt + εit  so the local macro is as shown below an interaction between BRP variable and post variable
local spec = " c.brp#c.post" 

*then the rest is just as shown in table 1       
eststo r1: reghdfe count `spec', a(id year_c) cluster(id) dof(none)   
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r1
estadd local book_FE "Yes":r1
estadd local field_citation_FE "No":r1
estadd local pub_year_citation_year_FE "No":r1
estadd local publication_year_FE "No":r1
estadd local field_FE "No":r1


*the interaction in the fixed effects of regression2 are used to capture the idiosyncratic variation in citaions accross fields over time
eststo r2: reghdfe count `spec', a(id i.field_gr#i.year_c) cluster(id) dof(none)  
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "No":r2
estadd local book_FE "Yes":r2
estadd local field_citation_FE "Yes":r2
estadd local pub_year_citation_year_FE "No":r2
estadd local publication_year_FE "No":r2
estadd local field_FE "No":r2


 *the interaction in the fixed effects are used to capture the idiosyncratic variation for a book's age, with an interaction for publication year × citation year fixed effects
eststo r3: reghdfe count `spec', a(id i.publ_year#i.year_c) cluster(id) dof(none) 
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r3
estadd local book_FE "Yes":r3
estadd local field_citation_FE "No":r3
estadd local pub_year_citation_year_FE "Yes":r3
estadd local publication_year_FE "No":r3
estadd local field_FE "No":r3

eststo r4: reghdfe count `spec', a(year_c i.field_gr i.publ_year) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r4
estadd local book_FE "No":r4
estadd local field_citation_FE "No":r4
estadd local pub_year_citation_year_FE "No":r4
estadd local publication_year_FE "Yes":r4
estadd local field_FE "Yes":r4


esttab r1 r2 r3 r4 using "${Tables}/table2.tex", replace $options drop(_cons) stat( citation_year_FE book_FE field_citation_FE pub_year_citation_year_FE publication_year_FE field_FE N r2 ymean , fmt(0 3 3) label( `"Citation-Year FE"' `"Book FE"' `"Field-Citation FE"' `"Publication-Year-Citation-Year FE"'`"Publication-Year FE"' `"Field FE"' `"N"' `"R2"' `"Mean of dep var"')) nomtitle booktabs nogaps title("Table 2—OLS, Effect of BRP on English-Language Citations: BRP versus Swiss Books")
restore 


*combining the 2 identifications 

//Table 3—OLS, Effect of BRP on English-Language versus Other Citations: BRP versus Swiss Books (Matched Sample)

/*this is the triple difference table now the regression changed to include the differential change in citations to BRP books from English-language and other-language authors with the same differential change for Swiss books so here there is 2 comparaisons The first examines changes in English-language citations to BRP books compared to citations to the same books in other languages, mitigating selection bias by focusing on the same source material across different linguistic contexts. The second compares changes in English-language citations to BRP books with those to Swiss books, addressing the concern that English-language citations may have increased automatically due to a post-World War II 
To account for this the authors are estimating the following equation 

citesilt = β1 Englishl +β2 BRPi × postt+  β3 Englishl × BRPi + β4 Englishl × postt+ β5 Englishl × BRPi × postt + booki + τt + εilt, where B5 is the coefficient of interest (the triple difference coefficient) 
 the local macro is defined accordingly and then you repeat the steps of table 1 and table 2 with different specification  
*/

preserve
keep if matched == 1
local spec = "english brp c.brp#c.post c.english#c.brp c.english#c.post c.english#c.brp#c.post"
eststo r1: reghdfe count `spec', a(id year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r1
estadd local book_FE "Yes":r1
estadd local field_citation_FE "No":r1
estadd local pub_year_citation_year_FE "No":r1
estadd local book_citation_FE "No":r1
estadd local english_citation year "No":r1

eststo r2: reghdfe count `spec', a(id year_c i.field_gr#i.year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "No":r2
estadd local book_FE "Yes":r2
estadd local field_citation_FE "Yes":r2
estadd local pub_year_citation_year_FE "No":r2
estadd local book_citation_FE "No":r2
estadd local english_citation year "No":r2

eststo r3: reghdfe count `spec', a(year_c i.field_gr i.publ_year) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r3
estadd local book_FE "No":r3
estadd local field_citation_FE "No":r3
estadd local pub_year_citation_year_FE "Yes":r3
estadd local book_citation_FE "No":r3
estadd local english_citation year "No":r3

eststo r4: reghdfe count `spec', a(id year_c i.id#i.year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r4
estadd local book_FE "Yes":r4
estadd local field_citation_FE "No":r4
estadd local pub_year_citation_year_FE "No":r4
estadd local book_citation_FE "No":r4
estadd local english_citation year "Yes":r4

eststo r5: reghdfe count `spec', a(id year_c i.english##i.year_c) cluster(id) dof(none)
qui sum count if e(sample) & year_c <= 1941 & brp == 1
estadd scalar ymean = `r(mean)'
estadd local citation_year_FE "Yes":r5
estadd local book_FE "No":r5
estadd local field_citation_FE "No":r5
estadd local pub_year_citation_year_FE "No":r5
estadd local book_citation_FE "Yes":r5
estadd local english_citation year "Yes":r5

esttab r1 r2 r3 r4 r5 using "${Tables}/table3.tex", replace $options drop(_cons) stat(citation_year_FE book_FE field_citation_FE pub_year_citation_year_FE publication_year_FE field_FE N r2 ymean , fmt(0 3 3) label( `"Citation-Year FE"' `"Book FE"' `"Field-Citation FE"' `"Publication-Year-Citation-Year FE"'`"Publication-Year FE"' `"Field FE"' `"N"' `"R2"' `"Mean of dep var"' )) nomtitle booktabs nogaps title("Table 3—OLS, Effect of BRP on English-Language versus Other Citations: BRP versus Swiss Books")
restore 
