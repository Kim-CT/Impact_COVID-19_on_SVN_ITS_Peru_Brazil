**==================================================
* Declare working directory and files 
**==================================================
global path  "C:\Users\Preterm & ITS"
global a "$path\\a_Do"
global b "$path\\b_BD"
global c "$path\\c_Temp"
global d "$path\\d_Out"

	/* Note: The working directory is organized as follows:
			 - a_Do 	: Contains the dofiles used in the analysis.
			 - b_BD 	: Stores the original databases used as input.
			 - c_Temp 	: Holds the temporal databases created during the analysis.
			 - d_Out 	: Stores all output files, such as PNG images, TIFF files and Excel tables.
			Please ensure that the working directory structure remains intact when running this code. */

**==================================================**
**	            	Create working file        	  	**
**==================================================**	
cd "$b"
global country = "Peru" 
foreach x in preterm lbw sga {
use "${country}_covid_dataset.dta", clear
global var = "`x'"  
sort	district year month
bysort 	year month: egen ${var}_total_month=sum(${var})
lab var ${var}_total_month "Total ${var} by month"
bysort year: egen annual_${var}_nat_tot=sum(${var})
gen yr2017_${var}_nat_tot= annual_${var}_nat_tot if year==2017
gen yr2018_${var}_nat_tot= annual_${var}_nat_tot if year==2018
gen yr2019_${var}_nat_tot= annual_${var}_nat_tot if year==2019
gen yr2020_${var}_nat_tot= annual_${var}_nat_tot if year==2020
gen yr2021_${var}_nat_tot= annual_${var}_nat_tot if year==2021
gen 	quarter=1 if month==1|month==2|month==3
replace quarter=2 if month==4|month==5|month==6
replace quarter=3 if month==7|month==8|month==9
replace quarter=4 if month==10|month==11|month==12
lab var quarter "Quarter of the year"
lab def quarter 1"Quarter-1" 2"Quarter-2" 3"Quarter-3" 4"Quarter-4"
lab val quarter quarter 
label drop region
label def region 1"Coast" 2"Highlands" 3"Rainforest"
label var region region
save "$c\\tmpdatafile_${var}", replace 
}

**================================================== 
* Useful globals
**================================================== 
global name_preterm 	"Number of preterm births"
global name_lbw 		"Number of low birthweight" "newborns"
global name_sga 		"Number of small for" "gestational age newborns"
global id_preterm 		"a"
global id_lbw  			"b"
global id_sga   		"c"