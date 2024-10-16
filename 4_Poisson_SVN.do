**==================================================
* Declare working directory and files 
**==================================================
global path  "C:\Users\Preterm & ITS"
global a "$path\\a_Do"
global b "$path\\b_BD"
global c "$path\\c_Temp"
global d "$path\\d_Out"

**==========================================================
* Import dataset and collapse variables by years and months
**==========================================================
use "$b\Peru_covid_dataset.dta", clear
collapse (sum) preterm lbw sga  , by(year month)
gen date = ym(year, month)
format date %tm
tsset date, monthly
gen time=_n
ac preterm

**==============
* line plot 
**==============
twoway (tsline preterm)

**==================================
* Proposing the impact model
**==================================
#delimit ;
scatter preterm time, 	msymbol(triangle) 
					mcolor(black)
					msize(tiny)
					legend(label(1 "Observed value (ANC)"))
					connect(direct)
						lcolor(black)
						lwidth(vthin)
					xline(	26,
							lpattern(dash)
							lstyle(dash)
							lwidth(vthin)
							lcolor(red))	
					xline(	27,
							lwidth(vthin))
					xline(	36,
							lpattern(dash)
							lstyle(dash)
							lwidth(vthin)
							lcolor(red))
					xline(	37,
							lwidth(vthin))
					xlab(0(2)48) 
					ylab(0(20000)80000)
					scheme(s1color)
					xtitle(Period)
					ytitle(ANC1)
					;
#delimit cr

**==================================
** analysis
**==================================
gen covid_prd = (time>=39)
cap drop time_after_covid
gen time_after_covid=.
replace time_after_covid = 0 if covid_prd == 0
replace time_after_covid = time - 38 if time >= 39 & time <= 60

*** intervention in 2021: will take 0 fro pre intervention in 2021 and 1 for during intervention in 2021
gen covid_prd_2 = (time>=49)
gen time_after_covid_2 = .
replace time_after_covid_2 = 0 if covid_prd_2 == 0
replace time_after_covid_2 = time - 48 if time >= 49 & time <= 60

* Fourier term
gen degrees=(time/12)*360
fourier degrees, n(1)

* Heteroskedasticity and Autocorrelation Consistent
tsset time
glm lbw time ib0.covid_prd ib0.covid_prd_2 time_after_covid time_after_covid_2 cos* sin* , vce(hac nwest) family(poisson) link(log) eform 
dwstat
drop pred
predict pred

*Scatter plot and trends
#delimit ;
twoway (scatter preterm time, 	msymbol(circle) 
							mcolor(black)
							msize(tiny)
							legend(label(1 "Observed value (ANC)"))
							) 
       (line pred time if (time<27) , 	lcolor(red) 
										lwidth(thin) 
										legend(label(2 "Pre-pandemic period"))
										) 
	   (line pred time if (inlist(time, 26, 27)) , 	lcolor(red) 
													lwidth(thin) 
													lpattern(shortdash)
													legend(label(3 "COVID impact (2020)"))
													) 
       (line pred time if (time>=27) & (time<37), 	lcolor(green)  
													lwidth(medthin) 
													legend(label(4 "Post-pandemic trend (2020)"))
													)
	   (line pred time if (inlist(time, 36, 37)) , 	lcolor(green) 
													lwidth(thin) 
													lpattern(shortdash)
													legend(label(5 "COVID impact (2021)"))
													) 
       (line pred time if (time>=37), 	lcolor(orange)  
										lwidth(medthin) 
										legend(label(6 "Post-pandemic trend (2021)"))
										), 
		xlab(0(4)48) 
		ylab(10000(10000)60000)
		scheme(s1color)
		xtitle("Period")
		ytitle("Total ANC")
		title("Impact model used in ITS")
;   
#delimit cr

**==============================================================
*Interrupted time series - Segmented regression by month
**==============================================================
glm preterm time ib0.time_after_covid cos* sin* , vce(hac nwest) family(poisson) link(log) eform 
glm lbw time ib0.time_after_covid cos* sin* , vce(hac nwest) family(poisson) link(log) eform 
glm sga time ib0.time_after_covid cos* sin* , vce(hac nwest) family(poisson) link(log) eform 