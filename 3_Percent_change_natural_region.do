**==================================================
* Declare working directory and files
**==================================================
global path  "C:\Users\Preterm & ITS"
global a "$path\\a_Do"
global b "$path\\b_BD"
global c "$path\\c_Temp"
global d "$path\\d_Out"
				
**==================================================**
**	    	       Create working file  	      	**
**==================================================**	
cd "$b"
foreach j in preterm lbw sga {
forval 	i = 2020/2021 {
forval 	r = 1/3{
global country="Peru" 
use "${country}_covid_dataset.dta", clear
keep if region == `r'
label drop region
label def region 1"Coast" 2"Highlands" 3"Rainforest"
label var region region
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
	xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec total_pop urban mixtearea admin1_* *2020c || district: time  
} 
if "`i'" == "2021" {
	xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec total_pop urban mixtearea admin1_* *2021c || district: time  
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
xtmixed ${var} time feb mar apr may jun jul aug sep oct nov dec total_pop urban mixtearea admin1_* if time<39|| district: time 
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
if "`i'" == "2020" {
	gen covidperiod=1 if year==2020 & (month>=3 & month<.)
}
if "`i'" == "2021" {
	gen covidperiod=1 if year==2021 & (month>=1 & month<.)
}
gen diff${var}=tot_predicted_${var} - btot_predicted_${var} if time>38  & time<61
gen ratio${var}=100*tot_predicted_${var}/btot_predicted_${var} if time>38  & time<61
gen drop${var}=100*(tot_predicted_${var}-btot_predicted_${var})/btot_predicted_${var}
save "$c\\temp_${var}_`i'_`r'" , replace
}
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
**	  Percent change By natural region, 2020    	** 
**==================================================**	
global colors 	bar(1, fcolor(61 151 218) lcolor(black) lwidth(vthin))	///
				bar(2, fcolor(253 158 81) lcolor(black) lwidth(vthin)) 
global lab_preterm	-20(10)20
global lab_lbw		-30(10)10
global lab_sga		-20(10)20
forval r = 1/3 {
foreach x in preterm lbw sga {
global var 	= "`x'" 
use "$c\\temp_${var}_2020_`r'", clear
label drop region
label def region 1"Coast" 2"Highlands" 3"Rainforest"
label var region region
global region: label (region) `r' , strict
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
if  ustrregexm("lbw sga", "${var}") == 0 	graph bar (max) drop${var} tot_drop${var} ,  $colors over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}", size(vsmall) height(2)) scheme(s1color) legend(off) name(d_${var}_`r', replace)  nodraw
else  										graph bar (max) drop${var} tot_drop${var} ,  $colors over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}" , size(vsmall) height(3.5)) scheme(s1color) legend(off) name(d_${var}_`r', replace)  nodraw
}
}

** Combining graphs 
graph combine d_preterm_1 d_lbw_1 d_sga_1, cols(1) scheme(s1mono) name(g1, replace) nodraw title("A. Coast"		, position(11) size(small) )
graph combine d_preterm_2 d_lbw_2 d_sga_2, cols(1) scheme(s1mono) name(g2, replace) nodraw title("B. Highlands"	, position(11) size(small) )
graph combine d_preterm_3 d_lbw_3 d_sga_3, cols(1) scheme(s1mono) name(g3, replace) nodraw title("C. Amazon"	, position(11) size(small) )
graph combine 	g1 g2 g3, cols(3) scheme(s1mono) xsize(8) 
graph export 	"$d\Figure.png",  as(png) width(5000) replace


 
**==================================================**
**				(Suplementary)						**
**	  Percent change By natural region, 2021		** 
**==================================================**	
global colors 	bar(1, fcolor(61 151 218) lcolor(black) lwidth(vthin))	///
				bar(2, fcolor(253 158 81) lcolor(black) lwidth(vthin)) 
global lab_preterm	-25(10)25
global lab_lbw		-30(20)30
global lab_sga		-30(10)40
forval r = 1/3 {
foreach x in preterm lbw sga {
global var 	= "`x'" 
use "$c\\temp_${var}_2021_`r'", clear
label drop region
label def region 1"Coast" 2"Highlands" 3"Rainforest"
label var region region
global region: label (region) `r' , strict
keep if covidperiod==1
collapse (max) tot_predicted_${var} btot_predicted_${var}, by(month)
rename tot_predicted_${var} observed
rename btot_predicted_${var} expected 
lab var observed "Observed ${var}"
lab var expected "Expected ${var}"
set obs 13
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
if  ustrregexm("lbw sga", "${var}") == 0 	graph bar (max) drop${var} tot_drop${var} ,  $colors over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}", size(vsmall) height(2)) scheme(s1color) legend(off) name(d_${var}_`r', replace)  nodraw
else  										graph bar (max) drop${var} tot_drop${var} ,  $colors over(month, label(labsize(vsmall))) blabel(bar, format(%10.0f)  size(vsmall)) yline(0, lcolor(black) lw(vthin)) ylabel( ${lab_${var}}, format(%10.0f) nogrid labsize(vsmall)) ytitle("${per_${var}}" , size(vsmall) height(3.5)) scheme(s1color) legend(off) name(d_${var}_`r', replace)  nodraw
}
}

** Combining graphs 
graph combine d_preterm_1 d_lbw_1 d_sga_1, cols(1) scheme(s1mono) name(g1, replace) nodraw title("A. Coast"		, position(11) size(small) )
graph combine d_preterm_2 d_lbw_2 d_sga_2, cols(1) scheme(s1mono) name(g2, replace) nodraw title("B. Highlands"	, position(11) size(small) )
graph combine d_preterm_3 d_lbw_3 d_sga_3, cols(1) scheme(s1mono) name(g3, replace) nodraw title("C. Amazon"	, position(11) size(small) )
graph combine 	g1 g2 g3, cols(3) scheme(s1mono) xsize(8) 
graph export 	"$d\Figure_percentchange2021_region.png",  as(png) width(5000) replace


 