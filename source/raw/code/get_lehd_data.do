version 13
capture log close

/* Paths */
local project PoliticalSentiment_Real
local subproject lib
local dofilename template
cd "/Users/jeremypage/Dropbox/Research/`project'/source/`raw'"

log using "temp/`dofilename'.log", replace

/* Project: ... */ 
/* What this do-file does */ 
/* Author: ... */ 

clear all
set more off

/* PROGRAMS */

/* EXECUTION */

log close