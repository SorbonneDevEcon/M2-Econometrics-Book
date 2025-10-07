clear mata
capture log close
clear
clear all
set more off

// Replication Project
// Carbon Taxes and CO2 Emissions: Sweden as a Case Study
// Julius J. Andersson
// December 2024

/// DESCRIPTIVE FIGURES

/// 1. Import the dataset
// a) Selection of the Zip
cd "/Users/alicebrossard/Desktop/Replication Project STATA/data"
import delimited "descriptive_data.dta", clear

// Load the dataset
use "descriptive_data.dta", clear
describe 

// Descriptive section - display the first 46 rows and 14 columns
list in 1/46, noobs abbrev(14)
	   
// Figure 1(a): Plot Gasoline price components with white background
twoway (line Real_Gasoline_Price year if inrange(year, 1960, 2005), lwidth(medium) lcolor(black)) ///
       (line Real_Carbontax year if inrange(year, 1960, 2005), lpattern(dash) lwidth(medium) lcolor(black)) ///
       (line Real_VAT year if inrange(year, 1960, 2005), lpattern(dot) lwidth(medium) lcolor(black)) ///
       (line Real_Energytax year if inrange(year, 1960, 2005), lwidth(medium) lcolor(gs10)) ///
       , ytitle("Real price (SEK/litre)") xtitle("Year") ///
         legend(order(1 "Gasoline price" 2 "Carbon tax" 3 "VAT" 4 "Energy tax")) ///
         yscale(r(0 13)) xscale(r(1960 2005)) xline(1990, lpattern(dash)) ///
         scheme(s1color)

graph export "/Users/alicebrossard/Desktop/Figure1a.png", as(png) name("Graph")
file /Users/alicebrossard/Desktop/Figure1a.png saved as PNG format

// Figure 1(b): Plot Gasoline price and Total tax component
twoway (line Real_Gasoline_Price year if inrange(year, 1960, 2005), lwidth(medium) lcolor(black)) ///
       (line Real_total_tax year if inrange(year, 1960, 2005), lpattern(dash) lwidth(medium) lcolor(black)) ///
       , ytitle("Real price (SEK/litre)") xtitle("Year") ///
       legend(order(1 "Gasoline price" 2 "Total tax")) ///
       yscale(r(0 13)) xscale(r(1960 2005)) xline(1990, lpattern(dash))
	   
graph save "Graph" "/Users/alicebrossard/Desktop/Figure1b_GasolinePrice_TotalGasComp.gph"
file /Users/alicebrossard/Desktop/Figure1b_GasolinePrice_TotalGasComp.gph saved

// Figure 2: Road sector fuel consumption per capita
twoway (line gas_cons year if inrange(year, 1960, 2005), lwidth(medium) lcolor(black)) ///
       (line diesel_cons year if inrange(year, 1960, 2005), lpattern(dash) lwidth(medium) lcolor(black)) ///
       , ytitle("Fuel consumption per capita (kg of oil equivalent)") xtitle("Year") ///
       legend(order(1 "Gasoline" 2 "Diesel")) ///
       yscale(r(0 600)) xscale(r(1960 2005)) xline(1990, lpattern(dash)) ///
       text(1981 100 "VAT + Carbon tax", place(e)) 

graph save "Graph" "/Users/alicebrossard/Desktop/Figure2_roadSectorFuel.gph"
file /Users/alicebrossard/Desktop/Figure2_roadSectorFuel.gph saved

// Figure 3: CO2 Emissions per capita, Sweden vs OECD average
twoway (line CO2_Sweden year if inrange(year, 1960, 2005), lwidth(medium) lcolor(black)) ///
       (line CO2_OECD year if inrange(year, 1960, 2005), lpattern(dash) lwidth(medium) lcolor(black)) ///
       , ytitle("Metric tons per capita (CO2 from transport)") xtitle("Year") ///
       legend(order(1 "Sweden" 2 "OECD sample")) ///
       yscale(r(0 3)) xscale(r(1960 2005)) xline(1990, lpattern(dash)) ///
       text(1981 1 "VAT + Carbon tax", place(e))

graph save "Graph" "/Users/alicebrossard/Desktop/Figure3_CO2Emissions_percapita.gph"
file /Users/alicebrossard/Desktop/Figure3_CO2Emissions_percapita.gph saved

// Figure 11: GDP per capita, Sweden vs Synthetic Sweden
twoway (line GDP_Sweden year if inrange(year, 1960, 2005), lwidth(medium) lcolor(black)) ///
       (line GDP_Synthetic_Sweden year if inrange(year, 1960, 2005), lpattern(dash) lwidth(medium) lcolor(black)) ///
       , ytitle("GDP per capita (PPP, 2005 USD)") xtitle("Year") ///
       legend(order(1 "Sweden" 2 "Synthetic Sweden")) ///
       yscale(r(0 35000)) xscale(r(1960 2005)) xline(1990, lpattern(dash)) ///
       text(1981 10000 "VAT + Carbon tax", place(e))

graph save "Graph" "/Users/alicebrossard/Desktop/Figure11_GDP_SyntheticSweden.gph"
file /Users/alicebrossard/Desktop/Figure11_GDP_SyntheticSweden.gph saved

// Figure 12: Gap in CO2 emissions and GDP per capita
// Set graph options
set scheme s2mono

twoway (line gap_CO2_emissions_transp year, lcolor(black)) ///
       (line gap_GDP year, lcolor(gs8) yaxis(2)), ///
       ytitle("Gap in metric tons per capita (CO2 from transport)") ///
       ylabel(-0.4(0.2)0.4) ///
       ytitle("Gap in GDP per capita (PPP, 2005 USD)", axis(2)) ///
       ylabel(-2000(1000)2000, axis(2)) ///
       xtitle("Year") ///
       xlabel(1960 1970 1980 1990 2000) ///
       xline(1990, lpattern(dash) lcolor(black)) ///
       legend(order(1 "CO2 Emissions (left y-axis)" 2 "GDP per capita (right y-axis)"))

* Tracé de la série `gap_CO2_emissions_transp`
twoway line gap_CO2_emissions_transp year, lcolor(black) ///
       ytitle("Gap in metric tons per capita (CO2 from transport)") ///
       xtitle("Year")
* Tracé avec les deux séries
twoway (line gap_CO2_emissions_transp year, lcolor(black)) ///
       (line gap_GDP year, lcolor(gs8) yaxis(2)), ///
       ytitle("Gap in metric tons per capita (CO2 from transport)") ///
       ytitle("Gap in GDP per capita (PPP, 2005 USD)", axis(2)) ///
       xtitle("Year")

graph save "Graph" "/Users/alicebrossard/Desktop/Gap_CO2Emissions_GDPcapita.gph"
file /Users/alicebrossard/Desktop/Gap_CO2Emissions_GDPcapita.gph saved


// -----------------------------------------------------

/// Replication of Figures 4 using the R code : carbontax

cd "/Users/alicebrossard/Desktop/Replication Project STATA/data"
import delimited "carbontax_data.dta", clear

// Load the dataset
use "leave_one_out_data.dta", clear
use "tax_incidence_data.dta", clear
use "carbontax_fullsample_data.dta", clear
use "fullsample_figures.dta", clear
 
describe 
browse

// Figure 4: Path Plot of per capita CO2 Emissions from Transport

* Set the data as panel data
use "carbontax_data.dta", clear
describe
browse

// Load the synth package in Stata if not already installed
ssc install synth, replace

// This is to Ensure our dataset has the necessary variables:
* Outcome: CO2_transport_capita
* Predictors: GDP_per_capita, gas_cons_capita, vehicles_capita, urban_pop
* Treatment: Treatment identifier (e.g., Sweden as 13)
* Control: Control units (1 2 3 ... 12, 14 15)

local time_predictors_prior 1980 1989
local time_optimize_ssr 1960 1989
local time_plot 1960 2005
local treatment_identifier "13"
local controls_identifier 1 2 3 4 5 6 7 8 9 10 11 12 14 15

* Define predictors, treatment, and control units
global predictors "GDP_per_capita gas_cons_capita vehicles_capita urban_pop"
global special_predictors "CO2_transport_capita"
global dependent "CO2_transport_capita"
global unit_variable "Countryno"
global unit_names_variable "country"
global time_variable "year"

* Specify the treatment period (e.g., treatment started in 1990)
local treatment_start_year "1990"

* Check for missing values in the pre-intervention period (e.g., 1960-1989)
summarize CO2_transport_capita if year >= 1960 & year <= 1989

tsset Countryno year
list Countryno if Countryno == 13

* Run synthetic control method
// Figure 4: The path plot comparing actual per capita CO2 emissions with the synthetic control.
synth CO2_transport_capita GDP_per_capita gas_cons_capita vehicles_capita urban_pop, ///
      trunit(13) ///
      trperiod(1990) ///
      fig keep(main.dta, replace)

use main.dta, clear
describe

 graph save "Graph" "/Users/alicebrossard/Desktop/Figure4_Replication.gph"
file /Users/alicebrossard/Desktop/Figure4_Replication.gph saved
	  
// Table 1: Predictor Means before Tax Reform 
use "carbontax_data.dta", clear
tsset Countryno year
list Countryno if Countryno == 13

synth CO2_transport_capita GDP_per_capita gas_cons_capita vehicles_capita urban_pop, ///
      trunit(13) ///
      trperiod(1990) ///
	  tables
		 
/// MAIN RESULTS 

use "/Users/alicebrossard/Desktop/Replication Project STATA/data/disentangling_regression_data.dta", clear 
describe 
browse 

tsset year
ssc install ivreg2
ssc install ranktest

// Table 3: Estimation Results from Gasoline Consumption Regressions

eststo clear
eststo: newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t, lag(16)
eststo: newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000, lag(16)
eststo: newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop, lag(16)
eststo: newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate, lag(16)
eststo: ivregress 2sls log_gas_cons (real_carbontaxexclusive_with_vat=real_energytax_with_vat) real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate, vce(hac bartlett opt)
eststo: ivregress 2sls log_gas_cons (real_carbontaxexclusive_with_vat=real_oil_price_sek) real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate, vce(hac bartlett opt)

// Afficher les résultats avec des titres, R2, erreurs standards et niveaux de significativité
esttab, r2 label mtitles("OLS" "OLS" "OLS" "OLS" "IV(EnTax)" "IV(OilPrice)") se(3) star(* 0.10 * 0.05 ** 0.01)

// p-value b1=b2
test real_carbontaxexclusive_with_vat = real_carbontax_with_vat

* Instrument F-statistic and testing for weak instruments
gen rctewvat= real_carbontaxexclusive_with_vat
ivreg2 log_gas_cons (rctewvat = real_energytax_with_vat ) real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate  , bw(auto) robust first
ivreg2 log_gas_cons (rctewvat = real_oil_price_sek ) real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate  , bw(auto) robust first 

* Estimated elasticities, using results from column (4)
newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate , lag(16)
margins, dyex(real_carbontax_with_vat real_carbontaxexclusive_with_vat) at(real_carbontax_with_vat=8.478676 real_carbontaxexclusive_with_vat=8.478676)

******************************************************
* Creating data set disentangling_data.dta used for Figure 13 and Figure 14
******************************************************

* First, predict gasoline consumption using the full model
newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate , lag(16) 
predict yhat

* Second, predict gasoline consumption without the carbon tax 
preserve
newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate , lag(16)
replace d_carbontax=0
replace real_carbontax_with_vat=0
predict yhat_nocarb
restore

* Third, predict emissions without the carbon tax and without the VAT
preserve
newey log_gas_cons real_carbontaxexclusive_with_vat real_carbontax_with_vat d_carbontax t real_gdp_cap_1000 urban_pop unemploymentrate , lag(16)
replace real_carbontaxexclusive_with_vat= real_carbontaxexclusive
replace d_carbontax=0
replace real_carbontax_with_vat=0
predict yhat_nocarb_novat
restore

* To convert predicted gasoline consumption to CO2 emission estimates I added empirical data on diesel consumption and multiplied with a combined (weighted) emissions factor.   

// Figure 13: Disentangling the Carbon Tax and VAT

* Set the data as panel data
use "disentangling_data.dta", clear
describe
browse

* Load data
use "disentangling.dta", clear

* Display first 46 rows and 6 columns of the dataset
list year CarbonTaxandVAT NoCarbonTaxWithVAT NoCarbonTaxNoVAT in 1/46

* Create the graph with three lines and adjusted x-axis and y-axis scales
graph twoway (line CarbonTaxandVAT year if year >= 1970 & year <= 2005, lwidth(medium) lcolor(black) yaxis(1)) ///
    (line NoCarbonTaxWithVAT year if year >= 1970 & year <= 2005, lwidth(medium) lcolor(black) lpattern(dot) yaxis(1)) ///
    (line NoCarbonTaxNoVAT year if year >= 1970 & year <= 2005, lwidth(medium) lcolor(black) lpattern(longdash) yaxis(1)), ///
    xlabel(1970(5)2005, grid) ylabel(0(0.5)3.5, angle(horizontal)) ///
    legend(label(1 "Carbon Tax and VAT") label(2 "No Carbon Tax, With VAT") label(3 "No Carbon Tax, No VAT") position(4) ring(0) col(1)) ///
    xtitle("Year") ytitle("Metric tons per capita (CO2 from transport)") ///
    yscale(range(0 3.5)) ///
    xline(1990, lpattern(dash) lwidth(medium) lcolor(black))
	
// Figure 14: Gap in Per Capita CO2 Emissions from Transport: Synthetic Control versus Simulation
use "disentangling.dta", clear

list year CO2_reductions_simulation CO2_reductions_synth in 1/46

* Here I Create the graph with CO2 reductions for both Synthetic Control and Simulation
twoway (line CO2_reductions_synth year, lcolor(black) lwidth(medium)) /// 
       (line CO2_reductions_simulation year, lcolor(gs14) lwidth(medium)), /// 
       xlabel(1960(5)2005, grid) ylabel(-0.8(0.2)0.6, angle(horizontal)) /// 
       xtitle("Year") ytitle("Gap in metric tons per capita (CO2 from transport)") ///
       yscale(range(-0.8 0.6)) /// 
       xline(1990, lpattern(dash) lcolor(black) lwidth(medium)) ///
       legend(label(1 "Synthetic Control result") label(2 "Simulation result") position(2) ring(0) col(1) size(medium))


twoway (function y=-0.845, range(2000 2004.9) lcolor(gs15) fcolor(gs15) lwidth(none)) ///
       (function y=0, range(1960 2005) lpattern(dash) lcolor(black) lwidth(medium)) ///
       , addplot (scatter 0 1987, msymbol(none) mcolor(black)) ///
       addplot (scatter 0 1989, msymbol(none) mcolor(black)) ///
       addplot (line 0.3 1987 1989, lcolor(black) lpattern(solid) lwidth(medium)) ///
       text(1981 0.3 "VAT + Carbon tax", size(medium) color(black))



	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
