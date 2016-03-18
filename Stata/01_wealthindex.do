**   MALAWI DHS VI
**
**   Aaron Chafetz
**   Date: March 15, 2016
**   Updated: March 16, 2016


/// CREATING A DHS WEALTH INDEX ///
*source - http://www.dhsprogram.com/topics/wealth-index/Wealth-Index-Construction.cfm
	
* INDICATOR CONSTRUCTION

	*open HH data (use only select variables to open in Stata/SE)
		use hhid hv001 hv002 hv003 hv025 hv005 hv009 hv012 hv013 hv015 ///
			hv201 hv205-hv216 hv221 hv225 hv226 hv243* hv245 hv246* hv247 ///
			sh111* using "$data/mwhr61fl.dta", clear	
	
	*select only interviewed households (hv015==1)
		qui: tab hv015
		assert `r(r)' == 1 // will only have 1 row (completed)
	
	*residence- urban v rural
		gen urban = 0
			replace urban = 1 if hv025==1
			lab def urban 0 "rural" 1 "urban"
			lab val urban urban
			lab var urban "Urban residence?"
		
	* total hectares of agricultural land owned
		clonevar agland = hv245
			recode agland (99 = .) (98 =.a) // 
			note agland: if >= 95ha, coded as 95ha

	*number of members per sleeping room
		tab hv012 //check to see if in any HH de jure ==0  -> use de facto
		tab hv013 if hv012==0
		clonevar members = hv012 
			replace members = hv013 if hv012==0
			qui: sum hv012 if hv012==0 //use for N in note below
			note members: HH de jure members; where de jure==0, replaced ///
				with de facto (n=`r(N)'/ 24,825 )
		clonevar temp_sleepingrooms = hv216
			recode temp_sleepingrooms (0 99 = 1) //recode any reporting 0 rooms to 1
		gen sleepnum = members/temp_sleepingrooms
			lab var sleepnum  "number of members per sleeping room"
	*how much livestock does the HH own?
		local livestock cattle goats sheep pultry pigs other
		local i 1
		foreach n of varlist hv246a hv246d-hv246g hv246k{
			local l : word `i' of `livestock'
			clonevar `l' = `n' if `n'!=98 | `n'!=99
			note `l': `l' max possible to report = 95
			local i = `i' + 1
			}
			*end		
	*source of drinking water
		clonevar temp_water = hv201
			recode temp_water (51/71 = 96) (99=.) //rainwater & bottled water categorized as other
		tab temp_water, gen(water_) 
			rename water_* ///
				(water_piped_dwelling water_piped_yard water_public ///
				water_borehole water_well_protected water_well_unprotected ///
				water_spring_protected water_spring_unprotected water_river ///
				water_other)
		
	*Type of toilet (hv205) and if shared (hv225) 
		tab hv205 hv225, m
		clonevar temp_toilet = hv205 
			recode temp_toilet (41/43 = 96) (99 = .) //recode composting & hanging to other
		local i = 0
		foreach t in "" "_sh"{
			tab temp_toilet if hv225==`i' & temp_toilet<31, gen(toilet`t'_)
			rename toilet`t'_* (toilet`t'_flush toilet`t'pit_vip ///
				toilet`t'_pit_slab toilet`t'_pit_open )
			local i = `i' + 1 		
			}
			*end
		gen toilet_bush=0
			replace toilet_bush=1 if temp_toilet==31
		gen toilet_other=0
			replace toilet_other=1 if temp_toilet==96
	
	*does HH own certain goods?
		local good electric radio tv fridge bicycle motorcycle car landline ///
			mobilephone watch cart bank koloboyi paraffin bed sofaset table
		local i 1
		foreach n of varlist hv206-hv212 hv221 hv243a-hv243c hv247 sh111a2-sh111i{
			local g : word `i' of `good'
			clonevar `g' = `n' if `n'!=9
			local i = `i' + 1
			}
			*end
	*floor type
		clonevar temp_floor = hv213  
			recode temp_floor (31/33 35 = 30) (21/23 = 96) (99 = .)
		tab temp_floor, gen(floor_)
			rename floor_* (floor_natrl floor_dung floor_finished ///
			floor_cement floor_other)
	*wall type
		clonevar temp_wall = hv214
			recode temp_wall (11 = 12) (24 26 = 20)(34 = 32) (35=33) (36 = 96) (99=.)
			lab copy hv214 wall
			lab val temp_wall wall
			lab def wall 12 "cane/palm/trunks/no walls" ///
				32 "stone w/ cement or unburnt bricks" ///
				33 "burnt bricks or cement blocks", modify
		tab temp_wall, gen(wall_)
			rename wall_* (wall_cane wall_dirt wall_rudmat wall_bamboo ///
				wall_stone_mud wall_cement wall_cementunburntbricks ///
				wall_burntbricks wall_other)
	*roof type
		clonevar temp_roof = hv215
			recode temp_roof (11 96 99= .) (13 = 12) (21/24 = 20) (31/36 =30)
			lab def hv215 12 "thatch/palm/sod", modify
		tab temp_roof, gen(roof_)
			rename roof_* (roof_thatch roof_rudmat roof_finished)
	*cooking fuel
		clonevar temp_cooking = hv226
			recode temp_cooking (11 = 9) (6 = 7) (2/5 96 = 8) (99=.)
			lab copy hv226 cooking
			lab def cooking 9 "straw/shrubs/grass/dung"  ///
				7 "charcoal or lignite/coal for cooking" ///
				8 "wood, other for cooking fuel", modify
		tab temp_cooking, gen(cooking_)
			rename cooking_* (cooking_electric cooking_charcoal cooking_wood ///
				cooking_straw cooking_nofood)
	*keep only ids and variables created
		drop members temp_* 
		keep hhid-hv005 agland-cooking_nofood
	*recode all missings as zero
		recode water_piped_dwelling-cooking_nofood (.=0) 
	*create yes no label
		lab drop _all
		lab def yn 0 "no" 1 "yes"
		lab val water_piped_dwelling-cooking_nofood	yn
	
	
* DESCRIPTIVE STATS
	tabstat agland-cooking_nofood, stat(mean sd n) col(stat)
	
* PRINCIPLE COMPONENTS ANALYSIS
	factor agland-cooking_nofood, pcf
