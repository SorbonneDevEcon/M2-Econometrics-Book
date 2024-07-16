/*
We are going to download the data directly from the author's personal github page. You will need to have a working internet connection. This website was last accessed on December 2023. 

Run the code and you will obtain multiple dataframes, however the only one essential for replicating the code is "dataframe_replication.dta.".

Create a new folder on your computer and paste it's location after dirroot "". Then run the code and obtain the essential dataframe.

!! Stata could take a moment downloading the dataframes depending on your internet connection
*/

global dirroot "PUT YOUR OWN WORKING DIRECTORY HERE (and store the data under this folder)"

cd "${dirroot}"

capture log close
clear
clear matrix

copy "https://scholar.harvard.edu/files/dell/files/files2.zip" "files2.zip", replace
unzipfile "${dirroot}/files2.zip", replace

copy "https://scholar.harvard.edu/files/dell/files/files3.zip" "files3.zip", replace
unzipfile "${dirroot}/files3.zip", replace

***********************************
**---Household Consumption
***********************************

*HOUSEHOLD IDS

/*first get household and identifier codes and data on age and sex of members*/

use "${dirroot}/enaho01_2001iv_200.dta", clear
keep conglome	vivienda	hogar	ubigeo p203	p207	p208a	p208b

drop if p203==0 /*people who were in the panel before but not in household anymore*/

recode p208b .=0
gen age= p208a + (p208b/12)
drop p208a p208b
tab age

rename 	p203	hhead
rename 	p207	male
recode hhead 2/10=0
egen test=sum(hhead), by (conglome vivienda hogar)
tab test
drop test
recode male 2=0

label var	conglome	"conglomerado"
label var	vivienda	"vivienda"
label var	hogar	"hogar"
label var	ubigeo	"ubicacion geografica"
label var	hhead	"household head"
label var	male	"male"

label define noyes 0 no 1 yes
label values hhead noyes

label define gender 0 female 1 male
label values male gender

/*delete departments not in sample*/
gen ccdd=substr(ubigeo, 1, 2)
tab ccdd
gen ccpp=substr(ubigeo, 3, 2)
tab ccpp
gen ccdi=substr(ubigeo, 5, 2)
tab ccdi
destring ccdd, replace
destring ccpp, replace
destring ccdi, replace
keep if (ccdd==3 | ccdd==4 | ccdd==5 | ccdd==8 | ccdd==21)

save "${dirroot}/consumption.dta", replace

*HOUSEHOLD CONSUMPTION NET TRANSFERS PER EQUIVALENT MEMBER

*generate a unique household identifier
gen hid = conglome + vivienda + hogar
label var hid "household identifier"

*create a variable which contains the number of members per household
gen var1=1
egen hhmem=sum (var1), by (hid)
tab hhmem
label var hhmem "number of household members"
drop var1
gen lhhmem=ln(hhmem)
label var lhhmem "log number of household members"

*create an age category var
gen age_cat=age
recode age_cat 0/14=1
recode age_cat 15/9999=2
tab age_cat, gen(ac)
egen kids=sum(ac1), by (hid)
drop ac*
tab kids
label var kids "# hh members aged 0 through 14"
gen k_hhmem=kids/hhmem
label var k_hhmem "kids/household members"
drop age_cat

/*(Deaton values)*/
gen age_cat=age
recode age_cat 0/4=1
recode age_cat 5/14=2
recode age_cat 15/9999=3
tab age_cat
label var age_cat "age category"
tab age_cat, gen(ac)
egen infants=sum(ac1), by (hid)
egen children=sum(ac2), by (hid)
egen adults=sum(ac3), by (hid)

*babies count as .4, children as .5, and adults as 1
recode age_cat 1=.4 2=.5 3=1
tab age_cat
egen ces = sum(age_cat), by(hid)
summarize ces
drop age_cat
drop ac*

save "${dirroot}/consumption.dta", replace

/*HOUSEHOLD CONSUMPTION*/

use "${dirroot}/sumaria_2001iv.dta", clear

keep conglome	vivienda	hogar	ubigeo	factorto gashog2d /*
*/defesp ingtexhd ingtrahd gru13hd1 gru13hd2 gru13hd3 /*
*/gru23hd1 gru23hd2 gru33hd1 gru33hd2 gru43hd1 gru43hd2 gru53hd1 gru53hd2 /*
*/gru63hd1  gru63hd2 gru73hd1 gru73hd2 gru83hd1 gru83hd2


/*recode system missings to 0*/
recode ingtexhd .=0
recode ingtrahd .=0
recode gru13hd1 .=0
recode gru13hd2 .=0
recode gru13hd3 .=0
recode gru23hd1 .=0
recode gru23hd2 .=0
recode gru33hd1 .=0
recode gru33hd2 .=0
recode gru43hd1 .=0
recode gru43hd2 .=0
recode gru53hd1 .=0
recode gru53hd2 .=0
recode gru63hd1 .=0
recode gru63hd2 .=0
recode gru73hd1 .=0
recode gru73hd2 .=0
recode gru83hd1 .=0
recode gru83hd2 .=0

/*delete departments not in sample*/
gen ccdd=substr(ubigeo, 1, 2)
tab ccdd
gen ccpp=substr(ubigeo, 3, 2)
tab ccpp
gen ccdi=substr(ubigeo, 5, 2)
tab ccdi
gen depprov=substr(ubigeo, 1, 4)
destring depprov, replace
tab depprov
destring ccdd, replace
destring ccpp, replace
destring ccdi, replace
keep if (ccdd==3 | ccdd==4 | ccdd==5 | ccdd==8 | ccdd==21)

sort conglome vivienda hogar
save temp, replace

use "${dirroot}/consumption.dta", clear
sort conglome vivienda hogar
merge conglome vivienda hogar using temp, uniqusing
tab _merge
drop _merge
save "${dirroot}/consumption.dta", replace

/*generated household consumption in normal prices*/
gen hconsump = gashog2d - ingtexhd -ingtrahd -gru13hd1 -gru13hd2 -gru13hd3 -/*
*/gru23hd1 -gru23hd2 -gru33hd1 -gru33hd2 -gru43hd1 -gru43hd2 -gru53hd1 -gru53hd2 -/*
*/gru63hd1 -gru63hd2 -gru73hd1 -gru73hd2 -gru83hd1 -gru83hd2 
drop gru*   factorto ingtrahd ingtexhd gashog2d  

label variable hconsump "household consumption minus transfers"

/*gen hh consumption in lima metropolitan prices*/

gen hconsumplm = (hconsump)/(defesp)
label variable hconsumplm "household consumption minus transfers (Lima prices)"
drop  defesp

/*for Deaton values*/
gen hhequiv= ((hconsumplm/ces))
gen lhhequiv=ln(hhequiv)
recode lhhequiv .=0

/*log household consumption*/
gen lhhconsplm=ln(hconsumplm)
recode lhhconsplm .=0

count

/*keep only household head*/
keep if hhead==1
count
drop hhead

save "${dirroot}/consumption.dta", replace



*LANGUAGE AND ETHNICITY

use "${dirroot}/enaho01b_2001iv.dta", clear
keep conglome	vivienda	hogar	ubigeo q21 q24 q25 q231 q232 q233 q28 q301 /*
*/q302 q303 q31 q32 q26a1 q33a1 q26a2 q33a2 q26a3 q33a3 q26a4 q33a4 q26a5 q33a5
/*delete departments not in sample*/
gen ccdd=substr(ubigeo, 1, 2)
tab ccdd
gen ccpp=substr(ubigeo, 3, 2)
tab ccpp
gen ccdi=substr(ubigeo, 5, 2)
tab ccdi
gen depprov=substr(ubigeo, 1, 4)
destring depprov, replace
tab depprov
destring ccdd, replace
destring ccpp, replace
destring ccdi, replace
keep if (ccdd==3 | ccdd==4 | ccdd==5 | ccdd==8 | ccdd==21)

/*Which language do you speak most frequently?*/
rename q231 CAST
replace CAST=1 if q21==1
replace CAST=0 if (q24!=. & q24!=1)
tab CAST

rename q232 QUE
recode QUE 2=1
replace QUE=1 if q21==2
replace QUE=0 if (q24!=. & q24!=2)
tab QUE

rename q233 AYM
recode AYM 3=1
replace AYM=1 if q21==3
replace AYM=0 if (q24!=. & q24!=3)
tab AYM

gen test=CAST+QUE+AYM
tab test
drop test

replace q301=1 if q28==1
replace q301=0 if (q31!=. & q31!=1)
tab q301

recode q302 2=1
replace q302=1 if q28==2
replace q302=0 if (q31!=. & q31!=2)
tab q302

recode q303 3=1
replace q303=1 if q28==3
replace q303=0 if (q31!=. & q31!=3)
tab q303

replace CAST=q301 if CAST==.
replace QUE=q302 if QUE==.
replace AYM=q303 if AYM==.

recode QUE .=0
recode CAST .=0
recode AYM .=0

tab CAST
tab QUE
tab AYM
drop q*
count

sort conglome vivienda hogar
save temp, replace

use "${dirroot}/consumption.dta", clear
sort conglome vivienda hogar
merge conglome vivienda hogar using temp, unique
tab _merge
drop _merge 
save "${dirroot}/consumption.dta", replace


*GIS VARS

use "${dirroot}/gis_dist.dta", clear
sort ubigeo
save temp, replace

use "${dirroot}/consumption.dta", clear
destring ubigeo, replace
sort ubigeo
merge ubigeo using temp, uniqusing
tab _merge
keep if _merge==3 /*keep only those observations in the study region for which we have consumption data*/
drop _merge
summ
save "${dirroot}/consumption.dta", replace



******************************
**---Childhood Stunting
******************************

use "${dirroot}/ctalla.dta", clear

keep if situacion==""

gen desnu=.
replace desnu=1 if (cnive=="3" | cnive=="4" | cnive=="5")
recode desnu (.=0)

gen desnu_sev=.
replace desnu_sev=1 if (cnive=="4" | cnive=="5")
recode desnu_sev (.=0)

destring canios, replace
destring cmeses, replace
replace canios=canios*12
gen age_mo=canios+cmeses
replace age_mo=age_mo/3
replace age_mo=floor(age_mo)
tab age, g(yr)
rename sexo male
destring male, replace
recode male (2=0)

foreach X of num 1/16 {
	gen age_sex`X'=male*yr`X'
}

keep cod_mod codgeo desnu* z_score talla_cm age_sex* male yr*

rename codgeo ubigeo
destring ubigeo, replace force
sort ubigeo
save "${dirroot}/height.dta", replace


/*GIS DATA AND TREATMENT DATA*/

use "${dirroot}/gis_dist.dta", clear
sort ubigeo
save temp, replace

use "${dirroot}/height.dta", clear
sort ubigeo
merge ubigeo using temp, uniqusing
tab _merge 
keep if _merge==3
drop _merge
sum
saveold "${dirroot}/height.dta", replace



// Create unique dataframe for replication

use "${dirroot}/gis_grid.dta", clear
gen gis_db=1
save "${dirroot}/gis_append.dta", replace

use "${dirroot}/consumption.dta", clear
gen consumption_db=1
save "${dirroot}/consumption_append.dta", replace

use "${dirroot}/height.dta", clear
gen height_db=1
save "${dirroot}/height_append.dta", replace

use "${dirroot}/height_append.dta", clear
append using "${dirroot}/consumption_append.dta"
append using "${dirroot}/gis_append.dta"
save "${dirroot}/Dataset_Dell.dta", replace
