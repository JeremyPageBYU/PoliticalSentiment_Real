version 13
capture log close

/* Paths */
local project PoliticalSentiment_Real
local subproject raw
local dofilename get_lau_data
cd "/Users/jeremypage/Dropbox/Research/`project'/source/`subproject'"

log using "temp/`dofilename'.log", replace

/* Project: Real effects of political sentiment */ 
/* This do-file: download county level employment data from
BLS Local Area Unemployment (LAU) database and save monthly
and annual data as .dta files */
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
* Download series information for local area unemployment data from BLS
copy "https://download.bls.gov/pub/time.series/la/la.series" input/la.series.txt, replace
insheet using input/la.series.txt, clear
save temp/lau_series, replace

* Download area information for local area unemployment data from BLS
copy "https://download.bls.gov/pub/time.series/la/la.area" input/la.area.txt, replace
insheet using input/la.area.txt, clear
save temp/lau_area, replace

* Download county-level local area unemployment data from BLS
copy "https://download.bls.gov/pub/time.series/la/la.data.64.County" input/la.data.64.County.txt, replace
insheet using input/la.data.64.County.txt, clear

merge m:1 series_id using temp/lau_series, ///
	keepusing(area_type_code area_code measure_code seasonal) ///
	assert(match using) ///
	keep(match)
drop _merge

merge m:1 area_code using temp/lau_area, ///
	keepusing(area_text) ///
	assert(match using) ///
	keep(match)
drop _merge

gen fips = substr(area_code,3,5)
destring fips, replace

gen month = substr(period,2,.)
destring month, replace

keycheck fips year month measure_code

save temp/lau_county_raw, replace

* Reshape data into a table with fips-year-month observations
use fips year month measure_code value area_code area_text footnote_codes using temp/lau_county_raw, clear
destring value, replace force

reshape wide value footnote_codes, i(fips year month) j(measure_code)
rename value3 unemploymentrate
rename footnote_codes3 unemploymentrate_footnote
rename value4 unemployment
rename footnote_codes4 unemployment_footnote
rename value5 employment
rename footnote_codes5 employment_footnote
rename value6 laborforce
rename footnote_codes6 laborforce_footnote

order fips year month area_code area_text
sort fips year month
keycheck fips year month

save temp/lau_county_raw_long, replace

* Extract annual and monthly data and save in output folder
use temp/lau_county_raw_long if month==13, clear
drop month
sort fips year
keycheck fips year
save output/lau_county_annual, replace

use temp/lau_county_raw_long if month!=13, clear
gen mdate = ym(year,month)
format mdate %tm
order fips mdate
sort fips mdate
keycheck fips mdate
save output/lau_county_monthly, replace

* Cleanup
erase temp/lau_series.dta
erase temp/lau_area.dta
erase temp/lau_county_raw.dta
erase temp/lau_county_raw_long.dta

log close