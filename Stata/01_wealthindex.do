**   MALAWI DHS VI
**
**   Aaron Chafetz
**   Date: March 15, 2016
**   Updated: March 16, 2016


/// CREATING A DHS WEALTH INDEX ///
/*
	source - http://www.dhsprogram.com/topics/wealth-index/Wealth-Index-Construction.cfm
	Components
	1. Domestic
	2. Land
	3. House
*/

** SETUP 

	*open female dataset
		use v001 v002 v003 v150 v717 v740 s826a using "$data/mwir61fl.dta", clear //individual woman dataset
	*create HH id
		egen hhid = group(v001 v002) //cluster and HH		
	*DOMESTIC
	/*replace domstic servant variable if individual is unrelated to head of 
		HH (v150==12) and occupation is "Household and domestic" (v717==6) */
		tempvar dom_temp
		gen `dom_temp' = 1 if v150==12 & v717==6
		replace `dom_temp'=0 if v150!=. & v717!=. & `dom_temp'!=1
		bysort hhid: egen domestic = max(`dom_temp')
	*LAND
	*set LAND =1 if the woman works her own or family’s land (v740==0 | 1)
		tempvar land_temp
		gen `land_temp' = 1 if inlist(v740,0,1)
		replace `land_temp' = 0 if v740!=. & `land_temp'!=1
		bysort hhid: egen land = max(`land_temp')
	*HOUSE
	/*If there is a country-specific item on ownership of dwelling in the 
		individual woman’s or men’s individual questionnaire, set HOUSE = 1 */
		tempvar house_temp
		gen `house_temp' = 1 if inlist(s826a,0,1)
		replace `house_temp' = 0 if s826a!=. & `house_temp'!=1
		bysort hhid: egen house = max(`house_temp')
	
	*save female
		keep v001 v002 v003 domestic land house
		tempfile tempdata
		save "`tempdata'", replace
		
	*open male dataset
		use mv001 mv002 mv003 mv150 mv717 mv740 using "$data/mwmr61fl.dta", clear //individual male dataset
	*create HH id
		egen hhid = group(mv001 mv002) //cluster and HH		
	*DOMESTIC
	/*replace domstic servant variable if individual is unrelated to head of 
		HH (v150==12) and occupation is "Household and domestic" (v717==6) */
		tempvar dom_temp
		gen `dom_temp' = 1 if mv150==12 & mv717==6
		replace `dom_temp'=0 if mv150!=. & mv717!=. & `dom_temp'!=1
		bysort hhid: egen domestic = max(`dom_temp')
	*LAND
	*set LAND =1 if the man works his own or family’s land (v740==0 | 1)
		tempvar land_temp
		gen `land_temp' = 1 if inlist(mv740,0,1)
		replace `land_temp' = 0 if mv740!=. & `land_temp'!=1
		bysort hhid: egen land = max(`land_temp')
	*HOUSE
	/*If there is a country-specific item on ownership of dwelling in the 
		individual woman’s or men’s individual questionnaire, set HOUSE = 1 */
		*n/a - missing owns house variable
	*rename variables
		rename (mv001 mv002 mv003) (v001 v002 v003)
	*save male
		keep v001 v002 v003 domestic land 
	
	*MERGE
		append using "`tempdata'"
		*create HH id
		egen hhid = group(v001 v002) //cluster and HH	
		*create variable combining male and female
		foreach x in domestic land house {
			bysort hhid: egen `x'_n = max(`x')
			drop `x'
			rename `x'_n `x'
			}
			*end
		*collapse to hh
			collapse (max) domestic land house, by(v001 v002)
		save "$output/assets_major_temp.dta",replace
	
* Additional indices
	*open HH data
		use hhid hv001 hv002 hv003 hv025 hv005 hv009 hv012 hv013 hv015 using "$data/mwhr61fl.dta", clear	
	*select only interviewed households (hv015==1)
		tab hv015==1 //all
