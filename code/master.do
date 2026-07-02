*=====================================================================
* master.do
* Revisiting "The Impact of Unilateral Divorce on Crime"
* Replication and reassessment of Caceres-Delpiano & Giolito (2012)
* Louis Chen, Queen's University
*
* Inputs  : ucr.dta            (UCR state-year panel, 1965-1996)
*           usa_00001.dta      (IPUMS USA extract: 1960-2000 censuses)
* Outputs : analysis_log.txt   (full text log of every result)
*           figure1a_levels.png, figure1b_normalized.png
*           figure2_event_study.png
*           figure3_didl.png
*
* Requires: did_multiplegt_dyn  ->  ssc install did_multiplegt_dyn
*
* Run from the project folder (File > Change Working Directory, or:
*   cd "/Users/louis/Desktop/Econometrics project" )
* Then:  do master.do
*=====================================================================

clear all
set more off
capture log close
log using "analysis_log.txt", text replace

* Uncomment on first run:
* ssc install did_multiplegt_dyn

*---------------------------------------------------------------------
* 0. TREATMENT CODING
* Friedberg (1998), Table 1 Column (1) of Caceres-Delpiano & Giolito
* (2012), WITHOUT separation requirements: states whose unilateral
* divorce law requires a period of separation are coded as
* non-adopting. Under this definition the non-adopting states are:
*   never adopted:            AR DE MS NY TN
*   separation requirement:   DC IL LA MD MO NJ NC OH PA SC UT VT VA WV
* These 19 states have year_uni = missing.
*---------------------------------------------------------------------
use "ucr.dta", clear

gen year_uni = .
replace year_uni = 1950 if statefip == 2                            // AK
replace year_uni = 1950 if statefip == 40                           // OK (pre-1968)
replace year_uni = 1969 if statefip == 20                           // KS
replace year_uni = 1970 if inlist(statefip, 6, 19)                  // CA IA
replace year_uni = 1971 if inlist(statefip, 1, 8, 12, 16, 33, 38)   // AL CO FL ID NH ND
replace year_uni = 1972 if inlist(statefip, 21, 26, 31)             // KY MI NE
replace year_uni = 1973 if inlist(statefip, 4, 9, 13, 15, 18) ///
                         | inlist(statefip, 23, 32, 35, 41, 53)     // AZ CT GA HI IN ME NV NM OR WA
replace year_uni = 1974 if inlist(statefip, 27, 48)                 // MN TX
replace year_uni = 1975 if inlist(statefip, 25, 30)                 // MA MT
replace year_uni = 1976 if statefip == 44                           // RI
replace year_uni = 1977 if inlist(statefip, 55, 56)                 // WI WY
replace year_uni = 1985 if statefip == 46                           // SD

* Conservative rule: the adoption year itself is coded as untreated
gen treatment = (year > year_uni) if !missing(year_uni)
replace treatment = 0 if missing(year_uni)
label var treatment "Unilateral divorce in force"

* Check: expect 882 untreated / 750 treated
tab treatment

gen ln_vcr = ln(violent_crime_rate)
label var ln_vcr "Log violent crime rate"

save "ucr_coded.dta", replace

*---------------------------------------------------------------------
* 1. FIGURE 1 - Motivating evidence
* Treatment group: the 10 states adopting in 1973 (modal reform year)
* Control group:   the 5 states that never adopted unilateral divorce
*                  in any form (AR DE MS NY TN)
*---------------------------------------------------------------------
preserve

gen byte fgroup = .
replace fgroup = 1 if year_uni == 1973
replace fgroup = 0 if inlist(statefip, 5, 10, 28, 36, 47)
keep if fgroup < .

collapse (mean) ln_vcr, by(fgroup year)

* Panel (a): levels
twoway (line ln_vcr year if fgroup==1, sort lcolor(navy)) ///
       (line ln_vcr year if fgroup==0, sort lcolor(maroon) lpattern(dash)), ///
       xline(1973, lpattern(dot) lcolor(gs8)) ///
       xlabel(1965(5)1995) ///
       ytitle("Log violent crime rate") xtitle("Year") ///
       legend(order(1 "Adopted unilateral divorce in 1973" ///
                    2 "Never adopted unilateral divorce") ///
              position(6) rows(1)) ///
       graphregion(color(white))
graph export "figure1a_levels.png", replace width(2400)

* Panel (b): normalized to 1973 = 0
bysort fgroup: egen ln_vcr73 = mean(cond(year==1973, ln_vcr, .))
gen ln_vcr_norm = ln_vcr - ln_vcr73
twoway (line ln_vcr_norm year if fgroup==1, sort lcolor(navy)) ///
       (line ln_vcr_norm year if fgroup==0, sort lcolor(maroon) lpattern(dash)), ///
       xline(1973, lpattern(dot) lcolor(gs8)) yline(0, lcolor(gs12)) ///
       xlabel(1965(5)1995) ///
       ytitle("Log violent crime rate, relative to 1973") xtitle("Year") ///
       legend(order(1 "Adopted unilateral divorce in 1973" ///
                    2 "Never adopted unilateral divorce") ///
              position(6) rows(1)) ///
       graphregion(color(white))
graph export "figure1b_normalized.png", replace width(2400)

restore

*---------------------------------------------------------------------
* 2. TABLE 1 - TWFE estimates (replicates Table 2 Panel A, Cols 1-4)
* Control blocks:
*   demographic : i.dr_black (quantile dummies), age-structure
*                 quantiles, fraction of immigrants, state population
*   aggregate   : log income, unemployment, lagged prisoners, crack
*   policy      : legal abortion, fault in property division,
*                 equitable division
*---------------------------------------------------------------------
use "ucr_coded.dta", clear

local demo   "i.dr_black dr_0_4 dr_5_9 dr_10_14 dr_15_19 dr_20_24 dr_25_29 dr_30_34 dr_35_39 dr_40_44 dr_45_49 dr_50_54 dr_55_59 dr_60_64 dr_65_69 dr_70_74 dr_75_79 dr_80_more migrant stpop"
local aggr   "ln_inc unemp crack prisonr1"
local policy "legal no_fault_property equitative"

* Column (1): state and year fixed effects only
reg ln_vcr treatment i.statefip i.year, cluster(statefip)
est store col1

* Column (2): + demographic controls
reg ln_vcr treatment `demo' i.statefip i.year, cluster(statefip)
est store col2

* Column (3): + state aggregate controls
reg ln_vcr treatment `demo' `aggr' i.statefip i.year, cluster(statefip)
est store col3

* Column (4): + state policy controls
reg ln_vcr treatment `demo' `aggr' `policy' i.statefip i.year, cluster(statefip)
est store col4

* Summary table in the log
est table col1 col2 col3 col4, keep(treatment) b(%9.4f) se(%9.4f) stats(N r2)

*---------------------------------------------------------------------
* 3. FIGURE 2 - Event study
* Bins of years relative to reform (assignment categorization);
* bin -1 (reform year and the year before) is the omitted group and
* never-treated states are assigned to it. tte = time_to_treat + 5.
*---------------------------------------------------------------------
gen year_to_treat = year - year_uni

gen time_to_treat = .
replace time_to_treat = -4 if year_to_treat <= -8
replace time_to_treat = -3 if inrange(year_to_treat, -7, -5)
replace time_to_treat = -2 if inrange(year_to_treat, -4, -2)
replace time_to_treat = -1 if inrange(year_to_treat, -1, 0)
replace time_to_treat =  0 if inrange(year_to_treat, 1, 3)
replace time_to_treat =  1 if inrange(year_to_treat, 4, 7)
replace time_to_treat =  2 if inrange(year_to_treat, 8, 11)
replace time_to_treat =  3 if inrange(year_to_treat, 12, 15)
replace time_to_treat =  4 if inrange(year_to_treat, 16, 19)
replace time_to_treat =  5 if inrange(year_to_treat, 20, 22)
replace time_to_treat =  6 if year_to_treat >= 23 & !missing(year_to_treat)
replace time_to_treat = -1 if missing(year_uni)      // never-treated -> omitted group

gen tte = time_to_treat + 5                           // tte = 4 omitted

reg ln_vcr ib4.tte i.statefip i.year, cluster(statefip)

* Collect coefficients for the plot
tempname memhold
postfile `memhold' tte b se using "es_results.dta", replace
foreach k of numlist 1/11 {
    if `k' == 4 {
        post `memhold' (`k') (0) (.)
        continue
    }
    lincom `k'.tte
    post `memhold' (`k') (r(estimate)) (r(se))
}
postclose `memhold'

preserve
use "es_results.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
twoway (rcap lo hi tte, lcolor(navy)) ///
       (scatter b tte, mcolor(navy)), ///
       yline(0, lpattern(dash) lcolor(gs8)) ///
       xline(4.5, lpattern(dash) lcolor(gs8)) ///
       xlabel(1 "{&le}-8" 2 "-7/-5" 3 "-4/-2" 4 "-1/0" 5 "+1/+3" ///
              6 "+4/+7" 7 "+8/+11" 8 "+12/+15" 9 "+16/+19" ///
              10 "+20/+22" 11 "{&ge}+23", labsize(small)) ///
       xtitle("Years relative to reform (binned)") ///
       ytitle("Coefficient estimate") ///
       legend(off) graphregion(color(white))
graph export "figure2_event_study.png", replace width(2400)
restore

*---------------------------------------------------------------------
* 4. TABLE 2 - Census: institutionalization (Table 7, Cols 1,2,5,6)
* NOTE: usa_00001.dta is 1.9 GB; this section takes a while to run.
*---------------------------------------------------------------------

* 4a. Build the merge file (assignment procedure: 1965 laws for the
*     1960 census, 1996 laws for the 2000 census)
use "ucr_coded.dta", clear
keep if inlist(year, 1965, 1970, 1980, 1990, 1996)
replace year = 1960 if year == 1965
replace year = 2000 if year == 1996
rename statefip bpl
keep year bpl treatment year_uni no_fault_property equitative
save "ucr_merge.dta", replace

* 4b. Census sample: men aged 15-24; institutionalization from GQ
use "usa_00001.dta", clear
keep if sex == 1
keep if age >= 15 & age <= 24
gen inst = (gq == 3)                    // group quarters: institutions
label var inst "Lives in an institution"

merge m:1 year bpl using "ucr_merge.dta"
keep if _merge == 3
drop _merge

* Check: expect 1,917,886 untreated / 1,442,569 treated
tab treatment

gen black = (race == 2)

* Column (1): all men, individual controls
areg inst treatment i.year i.age i.race i.age#i.year i.race#i.year, ///
     absorb(bpl) cluster(bpl)
est store cen1

* Column (2): + state of residence FE and policy dummies
areg inst treatment i.year i.age i.race i.age#i.year i.race#i.year ///
     i.statefip no_fault_property equitative, ///
     absorb(bpl) cluster(bpl)
est store cen2

* Column (5): Black men, individual controls
areg inst treatment i.year i.age i.age#i.year if black == 1, ///
     absorb(bpl) cluster(bpl)
est store cen5

* Column (6): + state of residence FE and policy dummies
areg inst treatment i.year i.age i.age#i.year ///
     i.statefip no_fault_property equitative if black == 1, ///
     absorb(bpl) cluster(bpl)
est store cen6

est table cen1 cen2 cen5 cen6, keep(treatment) b(%9.4f) se(%9.4f) stats(N)

* Mean institutionalization rate for Black men (for interpretation)
sum inst if black == 1

*---------------------------------------------------------------------
* 5. FIGURE 3 - DID_l estimator (de Chaisemartin & d'Haultfoeuille 2024)
* Dynamic effects up to 10 periods after adoption; placebo estimates
* for 5 pre-reform periods.
*---------------------------------------------------------------------
use "ucr_coded.dta", clear

did_multiplegt_dyn ln_vcr statefip year treatment, ///
    effects(10) placebo(5) cluster(statefip)

graph export "figure3_didl.png", replace width(2400)

*---------------------------------------------------------------------
log close
display "DONE - see analysis_log.txt and the exported figures."
