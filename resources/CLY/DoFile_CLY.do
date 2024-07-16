*Reference: Carter, M., Laajaj, R., & Yang, D. (2021). Subsidies and the African Green Revolution: Direct effects and social network spillovers of randomized input subsidies in Mozambique. American Economic Journal: Applied Economics, 13(2), 206‑229. https://doi.org/10.1257/app.20190396

*Link to the published article: https://www.aeaweb.org/articles?id=10.1257/app.20190396; https://pubs.aeaweb.org/doi/pdfplus/10.1257/app.20190396

*Replication file prepared by: Chiara Balducci, Ambre Delaunay, Elvire Jégu, Yagmur Aslan.

*Replicating: Table 2, Figure 2, Table A7 (in Appendix) from the original paper.

*__________________________________DATA______________________________________________________________________________

*DOWNLOAD data "Moz1234panel.dta" from: https://www.openicpsr.org/openicpsr/project/116761/version/V2/view?path=/openicpsr/116761/fcr:versions/V2.1/Rep-file-Moz-Input-Subsidy/data/original/Moz1234panel.dta&type=file

*SAVE in a folder (working directory)

*__________________________________WORKING DIRECTOTY______________________________________________________________________________

*SET WORKING DIRECTOTY /*the directory where you just saved the dataset*/
*cd "YOUR DIRECTORY HERE" 
cd "XXX" /*XXX=the directory where you just saved the dataset*/

*__________________________________DATASET______________________________________________________________________________

use "Moz1234panel.dta", clear

* selecting the necessary avriables for replicating the Table 2, Figure 2, and Table A7
keep sn5up_sub_dur sn2up_sub_aft nw_talkedagmoder lfertmaizr sn2_sub_dur sn2up_sub_dur sn1_sub_aft lyieldr sn3_sub_aft lexp_yield_fertr vouch_aft_r3 sn2up_sub_aft_r3 limprovedseedsr vouch_aft sn1_sub_dur vlgid_round respid sn2up_sub_aft_r4 vouch_aft_r4 vouch_dur ldailyconsr sn3_sub_dur sn4_sub_aft sn5up_sub_aft sn4_sub_dur sn2_sub_aft fertmaizr vouch round

* exponentiation of the winsorized variables back to their original forms
foreach x in improvedseedsr yieldr dailyconsr exp_yield_fertr{ 
	// it is necessary in order to add the means of the control to the table 2. This way it uses the value that is not Winsorized. 
		gen `x' = exp(l`x')
}

save "Dataset_CLY.dta", replace

*__________________________________DATASET______________________________________________________________________________

*Install parmest if not already installed /*necessary for Graph 2*/
ssc install parmest, replace


use "Dataset_CLY.dta", clear
xtset vlgid_round
global sn_treatments sn1_sub_dur sn2_sub_dur sn3_sub_dur  sn4_sub_dur sn5up_sub_dur sn1_sub_aft sn2_sub_aft  sn3_sub_aft  sn4_sub_aft sn5up_sub_aft 


									*********************************
									* Table 2 : Standard regression *
									*********************************

								


foreach v in fertmaizr improvedseedsr yieldr dailyconsr exp_yield_fertr {
		local x : variable label l`v' 
		local x = trim(subinstr("`x'","(log)","",.)) 
		label variable l`v' "`x'" 
		
}
local rep_app = "replace"

foreach x in fertmaizr improvedseedsr yieldr dailyconsr exp_yield_fertr {
		qui sum `x' if vouch==0 & round==2
		local control_mean=r(mean) 
		qui xi: areg l`x' vouch_dur vouch_aft ${sn_treatments} i.nw_talkedagmoder*i.round, absorb(vlgid_round) cluster(respid)  

		outreg2 using "table_2.xls", `rep_app' bracket label nocons noni less(1) nor2 keep(vouch_dur vouch_aft ${sn_treatments}) adds(mean_control,`control_mean') ctitle(`Fertilizer on maize' `Improved maize seeds' `Maize yield' `Daily consumption per capita' `Expected yield with technology package') 

		local rep_app = "append"
}

											***********
											* Graph 2 *
											***********

											
*** FIGURE 2—DIRECT AND SPILLOVER IMPACTS OF SUBSIDIES FOR GREEN REVOLUTION TECHNOLOGY ***

** Prepare the data **

use "Dataset_CLY.dta", clear

foreach x in lfertmaizr  limprovedseedsr lyieldr ldailyconsr lexp_yield_fertr {
	qui xi: reg `x' vouch_dur vouch_aft sn2up_sub_dur sn2up_sub_aft i.nw_talkedagmoder*i.round i.vlgid_round, cluster(respid)
	parmest, saving(`x', replace)
	}


local y = 1
foreach x in lfertmaizr limprovedseedsr lyieldr ldailyconsr lexp_yield_fertr {
	use `x'.dta 
	gen time=_n
	drop if time>4
	keep estimate stderr time

	replace estimate=round(estimate,0.01) 
	replace stderr=round(stderr,0.01)

	gen estimate_NV`y'=. 
	replace estimate_NV`y'=estimate[3] in 1 
	replace estimate_NV`y'=estimate[4] in 2 

	gen sd_NV`y'=.
	replace sd_NV`y'=stderr[3] in 1
	replace sd_NV`y'=stderr[4] in 2

	rename estimate estimate_V`y'
	rename stderr sd_V`y'

	local y = `y'+1
	drop if time>2
	save, replace
}

use lfertmaizr, clear

foreach x in limprovedseedsr lyieldr ldailyconsr lexp_yield_fertr{
	merge 1:1 time using `x'.dta, nogen
		save datafigure2.dta, replace
}
	
								
									
******************************************************************************************************************	

clear matrix
clear results
use "datafigure2.dta", clear

foreach i in V1 V2 V3 V4 V5 NV1 NV2 NV3 NV4 NV5{
	gen ll95_`i' = estimate_`i' - 1.96*sd_`i' 
	gen ul95_`i' = estimate_`i' + 1.96*sd_`i' 
	replace ul95_`i'=1 if ul95_`i'>1  
	mkmat estimate_`i' ll95_`i' ul95_`i', matrix(`i') //  Create a matrix to store results
}
	
/* PACKAGE A INSTALLER
*Install graph style and coefplot if not already installed:

ssc install grstyle
ssc install coefplot
grstyle init
grstyle color background white
grstyle color major_grid white
*/

coefplot /* 
*/ (matrix(V1[,1]), ci((V1[,2] V1[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/ (matrix(NV1[,1]), ci((NV1[,2] NV1[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1))|| /*
*/  ||, bylabel( ) byopts(title("Fertilizer on maize")) xsize(2) scale(1.35) ylabel(,labsize(vlarge)) ciopts(lwidth(thick thick)) /*
*/ 		coeflabels(r1="During" r2="After" ) mlabel mlabposition(1) mlabsize(vlarge)   format(%04.2f) name(fertilizer)

coefplot /*
*/ (matrix(V2[,1]), ci((V2[,2] V2[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/ (matrix(NV2[,1]), ci((NV2[,2] NV2[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/  ||, byopts( title("Improved maize seeds")) bylabel( ) xsize(2) scale(1.35) ylabel(,labsize(vlarge)) ciopts(lwidth(thick thick)) /*
*/ 		coeflabels(r1="During" r2="After" ) mlabel mlabposition(1) mlabsize(vlarge) format(%04.2f)  name(improved)

coefplot /*
*/ (matrix(V3[,1]), ci((V3[,2] V3[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1))  || /*
*/ (matrix(NV3[,1]), ci((NV3[,2] NV3[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1))|| /*
*/  ||, byopts( title("Maize yield")) bylabel( ) xsize(2) scale(1.35) ylabel(,labsize(vlarge)) ciopts(lwidth(thick thick) ) /*
*/ 		coeflabels(r1="During" r2="After" ) mlabel mlabposition(1) mlabsize(vlarge)	format(%04.2f) name(yield)

coefplot /*
*/ (matrix(V4[,1]), ci((V4[,2] V4[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/ (matrix(NV4[,1]), ci((NV4[,2] NV4[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/  ||, byopts( title("Consumption")) bylabel( ) xsize(2) scale(1.35) ylabel(,labsize(vlarge)) ciopts(lwidth(thick thick) ) /*
*/ 		coeflabels(r1="During" r2="After" ) mlabel mlabposition(1) mlabsize(vlarge) format(%04.2f)	name(consumption)

coefplot /*
*/ (matrix(V5[,1]), ci((V5[,2] V5[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/ (matrix(NV5[,1]), ci((NV5[,2] NV5[,3])) msize(large) xline(0, lpattern(solid) lw(thick)) xscale(range(-0.5(0.5)1)) xlabel(-0.5(0.5)1)) || /*
*/  ||, byopts( title("Expected yield with technology package")) bylabel( ) xsize(2)  scale(1.35) ylabel(,labsize(vlarge)) ciopts(lwidth(thick thick)) /*
*/ 		coeflabels(r1="During" r2="After" ) mlabel mlabposition(1) mlabsize(vlarge) format(%04.2f) name(expected)	

graph combine fertilizer improved yield consumption expected, b1title(Estimated coefficients, size(small) color(black)) cols(1) altshrink iscale(*3.2) xsize(3) xcommon  imargin(b=1 t=1) title("Direct impact" "on treatment group", size(small) color(black) position(11)) subtitle("Spillover impact via social" "network contacts", size(small) color(black) position(1))
 

gr export figure2.png, replace
gr export figure2.pdf, replace

										******************************
										* Table 7 : robustness check *
										******************************

use "Dataset_CLY.dta", clear										
										
local rep_app = "replace" 
label var vouch_dur "Direct impacts during"
label var vouch_aft_r3 "Direct impacts 1 year after"
label var vouch_aft_r4 "Direct impacts 2 year after"
label var sn2up_sub_dur "Spillover impacts during"
label var sn2up_sub_aft_r3 "Spillover impacts 1 year after" 
label var sn2up_sub_aft_r4 "Spillover impacts 2 year after"
foreach x in lfertmaizr  limprovedseedsr lyieldr ldailyconsr lexp_yield_fertr {  
		qui xi: areg `x' vouch_dur vouch_aft_r3 vouch_aft_r4 sn2up_sub_dur sn2up_sub_aft_r3 sn2up_sub_aft_r4 i.nw_talkedagmoder*i.round, absorb(vlgid_round) cluster(respid)

		test vouch_aft_r3 = vouch_aft_r4 
		scalar vou_di = r(p) 

		test sn2up_sub_aft_r3 = sn2up_sub_aft_r4
		scalar sn_di = r(p)
 
		
		outreg2 using "table A7.xls", `rep_app' bracket label nocons noni less(1) nor2 ///
		keep(vouch_dur vouch_aft_r3 vouch_aft_r4 sn2up_sub_dur sn2up_sub_aft_r3 sn2up_sub_aft_r4)  adds("vouch_aft dif (r3-r4) p-value", vou_di, "sn2up_sub_aft dif (r3-r4) p-value" , sn_di )

		local rep_app = "append"
}
 

