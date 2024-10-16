**==================================================
* Declare working directory and files 
**==================================================
global path  "C:\Users\Preterm & ITS"
global a "$path\\a_Do"
global b "$path\\b_BD"
global c "$path\\c_Temp"
global d "$path\\d_Out"

**==================================================**
**	        	Create  working file        		**
**==================================================**	
cd "$b"
foreach j in preterm lbw sga {
forval i = 2020/2021 {
global country="Peru" 
use "${country}_covid_dataset.dta", clear
global var = "`j'"  
lab def month 1"Jan" 2"Feb" 3"Mar" 4"Apr" 5"May" 6"Jun" 7"Jul" 8"Aug" 9"Sep" 10"Oct" 11"Nov" 12"Dec", modify
lab val month month
sort district year month
bysort year month: egen ${var}_total_month=sum(${var})
lab var ${var}_total_month "Total ${var} by month"
egen time=group(periodate)
lab variable time "Time in Month"
gen urban = urban_rural==2
gen mixtearea = urban_rural==3

** Create dummy variables for month
gen jan=0
gen feb=0
gen mar=0
gen apr=0
gen may=0
gen jun=0
gen jul=0
gen aug=0
gen sep=0
gen oct=0
gen nov=0
gen dec=0
replace jan=1 if month==1
replace feb=1 if month==2
replace mar=1 if month==3
replace apr=1 if month==4
replace may=1 if month==5
replace jun=1 if month==6
replace jul=1 if month==7
replace aug=1 if month==8
replace sep=1 if month==9
replace oct=1 if month==10
replace nov=1 if month==11
replace dec=1 if month==12

** Create covid months, per year of interest (2020 and 2021) 
if "`i'" == "2020" {
	gen mar2020c=0
	gen apr2020c=0
	gen may2020c=0
	gen jun2020c=0
	gen jul2020c=0
	gen aug2020c=0
	gen sep2020c=0
	gen oct2020c=0
	gen nov2020c=0
	gen dec2020c=0
	replace mar2020c=1 if year==2020 & time==39
	replace apr2020c=1 if year==2020 & time==40
	replace may2020c=1 if year==2020 & time==41
	replace jun2020c=1 if year==2020 & time==42
	replace jul2020c=1 if year==2020 & time==43
	replace aug2020c=1 if year==2020 & time==44
	replace sep2020c=1 if year==2020 & time==45
	replace oct2020c=1 if year==2020 & time==46
	replace nov2020c=1 if year==2020 & time==47
	replace dec2020c=1 if year==2020 & time==48
}

if "`i'" == "2021" {
	gen jan2021c=0
	gen feb2021c=0
	gen mar2021c=0
	gen apr2021c=0
	gen may2021c=0
	gen jun2021c=0
	gen jul2021c=0
	gen aug2021c=0
	gen sep2021c=0
	gen oct2021c=0
	gen nov2021c=0
	gen dec2021c=0
	replace jan2021c=1 if year==2021 & time==49
	replace feb2021c=1 if year==2021 & time==50
	replace mar2021c=1 if year==2021 & time==51
	replace apr2021c=1 if year==2021 & time==52
	replace may2021c=1 if year==2021 & time==53
	replace jun2021c=1 if year==2021 & time==54
	replace jul2021c=1 if year==2021 & time==55
	replace aug2021c=1 if year==2021 & time==56
	replace sep2021c=1 if year==2021 & time==57
	replace oct2021c=1 if year==2021 & time==58
	replace nov2021c=1 if year==2021 & time==59
	replace dec2021c=1 if year==2021 & time==60
}

** First level admin unit
tab upper_admin_unit, gen(admin1_)

** Run random intercept model and/or slope, per year 
if "`i'" == "2020" {
	xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec live_births_cnv urban mixtearea admin1_* *2020c || district: time  
} 
if "`i'" == "2021" {
	xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec live_births_cnv urban mixtearea admin1_* *2021c || district: time  
}

** Predicting fitted values and CIs
predict  predicted_${var},  fitted 
predict  predicted_${var}_se,  stdp 
generate  ub_ci  =  predicted_${var}  +  1.96*predicted_${var}_se
generate  lb_ci  =  predicted_${var} -  1.96*predicted_${var}_se
sort time district
by time: egen tot_predicted_${var} = sum(predicted_${var})
by time: egen tot_predicted_${var}_ub = sum(ub_ci)
by time: egen tot_predicted_${var}_lb = sum(lb_ci)
lab var tot_predicted_${var} "Observed ${var}"

** Model without COVID period, per year
xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec live_births_cnv urban mixtearea admin1_* if time<39|| district: time 
predict  bpredicted_${var},  fitted  
predict  bpredicted_${var}_se,  stdp 
generate  bub_ci  =  bpredicted_${var}  +  1.96*bpredicted_${var}_se
generate  blb_ci  =  bpredicted_${var} -  1.96*bpredicted_${var}_se
sort time district
by time: egen btot_predicted_${var} = sum(bpredicted_${var})
by time: egen btot_predicted_${var}_ub = sum(bub_ci)
by time: egen btot_predicted_${var}_lb = sum(blb_ci)
lab var btot_predicted_${var} "Expected ${var}"
lab var btot_predicted_${var}_ub "Upper bound"
lab var btot_predicted_${var}_lb "Lower bound"

** Create covid period, per year of interest (2020 and 2021) 
if "`i'" == "2020" {
	gen covidperiod=1 if year==2020 & (month>=3 & month<.)
}
if "`i'" == "2021" {
	gen covidperiod=1 if year==2021 & (month>=1 & month<.)
}

** Diferences, ratios and drops
gen diff${var}=tot_predicted_${var} - btot_predicted_${var} if time>38  & time<61
gen ratio${var}=100*tot_predicted_${var}/btot_predicted_${var} if time>38  & time<61
gen drop${var}=100*(tot_predicted_${var}-btot_predicted_${var})/btot_predicted_${var}
save "$c\\temp_${var}_`i'" , replace
}
}

**================================================== 
* globals
**================================================== 
global name_preterm 	"Number of preterm births"
global name_lbw 		"Number of low birthweight" "newborns"
global name_sga 		"Number of small for" "gestational age newborns"
global per_preterm 	"% Change of preterm births"
global per_lbw 		"% Change of low birthweight" "newborns"
global per_sga 		"% Change of small for" "gestational age newborns"
global id_preterm 		"a"
global id_lbw  			"b"
global id_sga   		"c"


**==================================================**
**	   Percent change, national level 2020  		**
**==================================================**	
global colors 	bar(1, fcolor( 61 151 218 ) lcolor(black) lwidth(vthin))	///
				bar(2, fcolor( 253 158 81 ) lcolor(black) lwidth(vthin)) 
global lab_preterm	-15(5)5
global lab_lbw		-20(5)5
global lab_sga		-15(10)25
global per_sga 		"% Change of small for gestational" "age newborns"
foreach x in preterm lbw sga {
global var 	= "`x'" 
use "$c\\temp_${var}_2020", clear
keep if covidperiod==1
collapse (max) tot_predicted_${var} btot_predicted_${var}, by(month)
rename tot_predicted_${var} observed
rename btot_predicted_${var} expected 
lab var observed "Observed ${var}"
lab var expected "Expected ${var}"
set obs 11
replace month=13 if month==.
lab def month 13"Total", modify
egen s_obs=sum(observed)
egen s_exp=sum(expected)
replace observed=s_obs if observed==.
replace expected=s_exp if expected==.
drop s_obs s_exp
gen drop${var}=100*(observed-expected)/expected 
gen tot_drop${var}= drop${var} if _n==_N
replace drop${var}=. if _n==_N
if  ustrregexm("lbw sga", "${var}") == 0 	graph bar (max) drop${var} tot_drop${var} , $colors b2title( "2020" , size(vsmall) ) over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}", size(vsmall) height(2)) scheme(s1color) legend(off) name(d1_${var}, replace)  nodraw
else  										graph bar (max) drop${var} tot_drop${var} , $colors b2title( "2020" , size(vsmall) ) over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}" , size(vsmall) height(3.5)) scheme(s1color) legend(off) name(d1_${var}, replace)  nodraw
}
graph combine d1_preterm d1_lbw d1_sga , cols(1) xsize(2.6) scheme(s1mono) name(PER2020, replace)
graph export 	"$d\Figure2.png",  as(png) width(5000) replace


**==================================================**
**			          	Graphs 			        	**
**==================================================**	
global scales_preterm 		0(1000)5000	
global scales_lbw  			0(1000)5000		
global scales_sga  			0(1000)4000

** Get graphs by variable
foreach x in preterm lbw sga {
global var 	= "`x'" 
use "$c\\temp_${var}_2020", clear
lab var btot_predicted_${var} 	"Expected value"
lab var tot_predicted_${var}  	"Observed value"
lab var ${var}_total_month 		"Total value by month"

** Graphs (Single/Double line for graph) *** 
if  ustrregexm("lbw sga", "${var}") == 0 twoway  (line btot_predicted_${var} time, ///
			b2title( "(${id_${var}})" , size(vsmall)) xlabel(#5) lcolor(black) ytitle("${name_${var}}", size(vsmall) height(2)) ///
			scheme(s1color) leg(off symx(15) symy(0.2) forces size(tiny)) bgcolor(white) ///
			graphregion(fcolor(white))  plotregion(style(none) fcolor(white)) ylabel( ${scales_${var}} , format(%10.0f) nogrid angle(horizontal) labsize(vsmall)) msize(vsmall) xtitle("") ///
			xlabel(1 "Jan17" 3 "Mar17" 5 "May17" 7 "Jul17" 9 "Sep17" 11 "Nov17" 13 "Jan18" 15 "Mar18" 17 "May18" 19 "Jul18" 21 "Sep18" 23 "Nov18" 25 "Jan19" 27 "Mar19" 29 "May19" 31 "Jul19" 33 "Sep19" 35 "Nov19" 37 "Jan20" 39 "Mar20" 41 "May20" 43 "Jul20" 45 "Sep20" 47 "Nov20" 49 "Jan21" 51 "Mar21" 53 "May21" 55 "Jul21" 57 "Sep21" 59 "Nov21" , angle(vertical) labsize(vsmall))) ///
		(line btot_predicted_${var}_ub time, lcolor(gray) lpattern(dash)) ///
		(line btot_predicted_${var}_lb time, lcolor(gray) lpattern(dash)) ///
		(scatter ${var}_total_month time, xline(39, lw(vthin)) msize(vsmall) lcolor(orange) mcolor(orange) msymbol(T) ) ///
		(line tot_predicted_${var} time if inrange(time,39,59)) , ///
		name(g_${var}, replace)  bgcolor(white) nodraw		
else twoway  (line btot_predicted_${var} time, ///
			b2title( "(${id_${var}})" , size(vsmall)) xlabel(#5) lcolor(black) ytitle("${name_${var}}", size(vsmall) height(3.5)) ///
			scheme(s1color) leg(off symx(15) symy(0.2) forces size(tiny)) bgcolor(white) ///
			graphregion(fcolor(white))  plotregion(style(none) fcolor(white)) ylabel( ${scales_${var}} , format(%10.0f) nogrid angle(horizontal) labsize(vsmall)) msize(vsmall) xtitle("") ///
			xlabel(1 "Jan17" 3 "Mar17" 5 "May17" 7 "Jul17" 9 "Sep17" 11 "Nov17" 13 "Jan18" 15 "Mar18" 17 "May18" 19 "Jul18" 21 "Sep18" 23 "Nov18" 25 "Jan19" 27 "Mar19" 29 "May19" 31 "Jul19" 33 "Sep19" 35 "Nov19" 37 "Jan20" 39 "Mar20" 41 "May20" 43 "Jul20" 45 "Sep20" 47 "Nov20" 49 "Jan21" 51 "Mar21" 53 "May21" 55 "Jul21" 57 "Sep21" 59 "Nov21" , angle(vertical) labsize(vsmall))) ///
		(line btot_predicted_${var}_ub time, lcolor(gray) lpattern(dash)) ///
		(line btot_predicted_${var}_lb time, lcolor(gray) lpattern(dash)) ///
		(scatter ${var}_total_month time, xline(39, lw(vthin)) msize(vsmall) lcolor(orange) mcolor(orange) msymbol(T) ) ///
		(line tot_predicted_${var} time if inrange(time,39,59))  , ///
		name(g_${var}, replace)  bgcolor(white)  nodraw
}

** Combining graphs 
grc1leg	 g_preterm g_lbw g_sga, rows(3) scheme(s1mono) legendfrom(g_preterm) name(combine, replace) 
graph display combine, xsize(2.6) 
graph export 	"$d\Figure.png",  as(png) width(5000) replace
 

