version 13
capture log close

/* Paths */
local project PoliticalSentiment_Real
local subproject raw
local dofilename get_lehd_data
cd "/Users/jeremypage/Dropbox/Research/`project'/source/`subproject'"

log using "temp/`dofilename'.log", replace

/* Project: Real effects of political sentiment */ 
/* This do-file: get annual county-level private employment and
wages from BLS Quarterly Census of Employment and Wages (QCEW) */
/* Inputs:	la.series.txt from BLS.gov 
			la.area.txt from BLS.gov
			la.data.64.County.txt from BLS.gov */
/* Outputs:	lau_county_annual.dta 
			lau_county_monthly.dta */ 
/* Author: Jeremy Page */ 

clear all
set more off

/* PROGRAMS */
capture program drop keycheck
* Check to confirm that the dataset is properly keyed
* Ensure that (1) key variable(s) have no missing values
* and (2) key values uniquely identify observations
program define keycheck
	syntax varlist(min=1)
	foreach v in `varlist' {
		assert !missing(`v')
	}
	bysort `varlist': assert _n==_N
end

/* EXECUTION */
*************************************************************************
* Extract county-level total private employment and wages from QCEW data
*************************************************************************
local qcew "/Users/jeremypage/Dropbox/ResearchDatabases/QCEW"
forvalues y = 1990/2015 {
	use `qcew'/`y'_annual_singlefile if own_code==5 & agglvl_code==71, clear
	destring area_fips, replace
	rename area_fips fips
	keep fips year annual_avg_estabs annual_avg_emplvl total_annual_wages avg_annual_pay
	save temp/`y'_qcew_total, replace
}
use temp/1990_qcew_total, clear
forvalues y = 1991/2015 {
	append using temp/`y'_qcew_total
}

keycheck fips year
save temp/1990_2015_qcew_total, replace

forvalues y = 1975/1989 {
	use `qcew'/sic_`y'_annual_singlefile if own_code==5 & agglvl_code==27, clear
	destring area_fips, replace
	destring avg_annual_pay, replace
	rename area_fips fips
	rename annual_avg_estabs_count annual_avg_estabs
	keep fips year annual_avg_estabs annual_avg_emplvl total_annual_wages avg_annual_pay
	save temp/sic_`y'_qcew_total, replace
}
use temp/sic_1975_qcew_total, clear
forvalues y = 1976/1989 {
	append using temp/sic_`y'_qcew_total
}

keycheck fips year
save temp/sic_1975_1989_qcew_total, replace

use temp/1990_2015_qcew_total, clear
append using temp/sic_1975_1989_qcew_total

replace avg_annual_pay = floor(total_annual_wages / annual_avg_emplvl) if avg_annual_pay==0

sort fips year
keycheck fips year
save output/qcew_annual_total, replace

* Clean up
forvalues y = 1990/2015 {
	erase temp/`y'_qcew_total.dta
}
forvalues y = 1975/1989 {
	erase temp/sic_`y'_qcew_total.dta
}
erase temp/1990_2015_qcew_total.dta
erase temp/sic_1975_1989_qcew_total.dta

*************************************
* Broad industry shares (as control)
*************************************
forvalues y = 1990/2015 {
	use `qcew'/`y'_annual_singlefile if own_code==5 & agglvl_code==73, clear
	qui destring area_fips, replace
	qui destring industry_code, replace
	rename area_fips fips
	keep fips year industry_code annual_avg_emplvl
	qui reshape wide annual_avg_emplvl, i(fips) j(industry_code)
	qui egen total_emplvl = rowtotal(annual_avg_emplvl*)
	qui gen natural_share = annual_avg_emplvl1011 / total_emplvl
	qui gen construction_share = annual_avg_emplvl1012 / total_emplvl
	qui gen manufacturing_share = annual_avg_emplvl1013 / total_emplvl
	qui gen tradetransutil_share = annual_avg_emplvl1021 / total_emplvl
	qui gen information_share = annual_avg_emplvl1022 / total_emplvl
	qui gen finance_share = annual_avg_emplvl1023 / total_emplvl
	qui gen profservices_share = annual_avg_emplvl1024 / total_emplvl
	qui gen eduhealth_share = annual_avg_emplvl1025 / total_emplvl
	qui gen leisure_share = annual_avg_emplvl1026 / total_emplvl
	keep fips year *_share
	foreach v of varlist *_share {
		qui replace `v'=0 if `v'==.
	}
	save temp/`y'_qcew_industry_share, replace	
}
use temp/1990_qcew_industry_share, clear
forvalues y = 1991/2015 {
	append using temp/`y'_qcew_industry_share
}

sort fips year
keycheck fips year
save output/qcew_industry_share, replace

* Clean up
forvalues y = 1990/2015 {
	erase temp/`y'_qcew_industry_share.dta
}

log close