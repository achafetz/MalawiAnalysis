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
	
* Indicator Construction
	*open HH data
		use hhid hv001 hv002 hv003 hv025 hv005 hv009 hv012 hv013 hv015 ///
			hv201 hv205-hv216 hv221 hv225 hv226 hv243* hv245 hv246* hv247 ///
			sh111* using "$data/mwhr61fl.dta", clear	
	*select only interviewed households (hv015==1)
		tab hv015 //all
	*land farmed
		clonevar agland = hv245
			recode agland (99 = .) (98 =.a) // note 95 = 95ha or more
	*number of members per sleeping room
		clonevar sleepingrooms = hv216
			recode sleepingrooms (0 = 1) (99 =.)
		gen sleepnum = hv012/sleepingrooms
			lab var sleepnum  "number of members per sleeping room"
	/*Source of drinking wateróeach category is a separate indicator variable 
		except that surface water sources (lakes, ponds, rivers, streams, etc.)
		is combined into one indicator variable if they are separate categories.*/
		tab hv201
		clonevar water = hv201
			recode water (51/71 = 96) (99=.)
		tab water
		tab water, gen(water_) 
			rename water_* ///
				(water_piped_dwelling water_piped_yard water_public ///
				water_borehole water_well_protected water_well_unprotected ///
				water_spring_protected water_spring_unprotected water_river ///
				water_other)
		
	*Type of toilet and sharing of toilets
		tab hv205 hv225, m
		clonevar toilet = hv205 
			recode toilet (41/43 = 96) (99 = .) 
		local i = 0
		foreach t in "" "_sh"{
			tab toilet if hv225==`i' & toilet<31, gen(toilet`t'_)
			rename toilet`t'_* (toilet`t'_flush toilet`t'pit_vip ///
				toilet`t'_pit_slab toilet`t'_pit_open )
			local i = `i' + 1 		
			}
			*end
		gen toilet_bush=0
			replace toilet_bush=1 if toilet==31
		gen toilet_other=0
			replace toilet_other=1 if toilet==96
	
	*other goods
		local good electric radio tv fridge bicycle motorcycle car landline ///
			mobilephone watch cart bank koloboyi paraffin bed sofaset table
		local i 1
		foreach n of varlist hv206-hv212 hv221 hv243a-hv243c hv247 sh111a2-sh111i{
			local g : word `i' of `good'
			clonevar `g' = `n' if `n'!=9
			local i = `i' + 1
			}
			*end
	*house
		clonevar floor = hv213  
			recode floor (31/33 35 = 30) (21/23 = 96) (99 = .)
		tab floor, gen(floor_)
			rename floor_* (floor_natrl floor_dung floor_finished ///
			floor_cement floor_other)
		clonevar wall = hv214
			recode wall (11 = 12) (24 26 = 20)(34 = 32) (35=33) (36 = 96) (99=.)
			lab copy hv214 wall
			lab val wall wall
			lab def wall 12 "cane/palm/trunks/no walls" ///
				32 "stone w/ cement or unburnt bricks" ///
				33 "burnt bricks or cement blocks", modify
		tab wall, gen(wall_)
			rename wall_* (wall_cane wall_dirt wall_rudmat wall_bamboo ///
				wall_stone_mud wall_cement wall_cementunburntbricks ///
				wall_burntbricks wall_other)
		clonevar roof = hv215
			recode roof (11 96 99= .) (13 = 12) (21/24 = 20) (31/36 =30)
			lab def hv215 12 "thatch/palm/sod", modify
		tab roof, gen(roof_)
			rename roof_* (roof_thatch roof_rudmat roof_finished)
	*cooking
		clonevar cooking = hv226
			recode cooking (11 = 9) (6 = 7) (2/5 96 = 8) (99=.)
			lab copy hv226 cooking
			lab def cooking 9 "straw/shrubs/grass/dung"  ///
				7 "charcoal or lignite/coal for cooking" ///
				8 "wood, other for cooking fuel", modify
		tab cooking, gen(cooking_)
			rename cooking_* (cooking_electric cooking_natural cooking_charcoal ///
				cooking_wood cooking_nofood)
		
		
	