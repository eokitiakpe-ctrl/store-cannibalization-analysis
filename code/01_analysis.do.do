/*******************************************************************************
Store Expansion and Sales Cannibalization Analysis

Research question:
Did the opening of a new retail location cannibalize sales at existing
stores within the same trading area?

Software: Stata
*******************************************************************************/

*===============================================================================
* 0. PROJECT SETUP
*===============================================================================

clear all
set more off

use "..\data\raw\Cannibalization_1_Transactions.dta", clear

*===============================================================================
* 1. DATA PREPARATION
*===============================================================================

gen date = date(daydate, "MDY")
format date %tdnn/dd/CCYY

collapse (sum) sales,by(date location)

*Store #6 Opening 11/8/12
display td(08nov2012)

line sales date,sort by(location,note("") graphregion(color(white))) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) xtitle("Date") ytitle("Daily Sales")

***************
*Time Series Setting the Data*

*tsset location date, daily

**Location must be numeric*
tab location

encode location,gen(store)
tab store
tab store,nolab

tsset store date ,daily
tsreport

table store,c(mean sales)

*To show numeric value for date*
format date %9.0g
list date in 1/5

format date %td

*Date-to-Numeric-for xline
display td(08nov2012)

tsline sales,sort by(location,note("") graphregion(color(white))) xtitle("Date") xline(19305) xlab(,labsize(vsmall)format(%tdnn/dd/CCYY) angle(0)) ytitle("Daily Sales")

graph export "..\figures\store_daily_sales.png", replace

*===============================================================================
* 2. EXPLORATORY SALES TRENDS AND SMOOTHING
*===============================================================================

*Smoothers*
tssmooth ma s_sales2=sales,window(2 1 2)

tsline sales s_sales2,sort by(location,note("") graphregion(color(white))) xline(19305) xlab(,labsize(tiny)format(%td)) ytitle("Daily Sales") legend(label(1 "Sales") label(2 "Smoothed Sales (2 1 2)"))

tsline sales s_sales2,sort by(store,note("") graphregion(color(white))) xtitle("") xline(19305) xlab(,labsize(tiny)) ylab(,labsize(vsmall)format(%15.0fc)angle(0)) ytitle("Daily Sales") legend(label(1 "Sales") label(2 "Smoothed Sales (2 1 2)"))


tssmooth ma s_sales3=sales, window(3 1 3)

tsline sales s_sales3,sort by(location, note("") graphregion(color(white))) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Daily Sales") legend(label(1 "Sales") label(2 "Smoothed Sales (3 1 3)"))

tsline sales s_sales3,sort by(store,note("") graphregion(color(white))) xtitle("") xline(19305) xlab(,labsize(tiny)) ylab(,labsize(vsmall)format(%15.0fc)angle(0)) ytitle("Daily Sales") legend(label(1 "Sales") label(2 "Smoothed Sales (2 1 2)"))

*Lowess (Locally Weighted Scatterplot Smoothing) Smoother
lowess sales date, sort by (location)

lowess sales date,sort by(location,note("") graphregion(color(white))) c(.  l) s(oh i) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Daily Sales")

*The bandwidth option specifies the fraction of the sample used in smoothing each point.
*The closer to 1, the greater the degree of smothing. Default is bwidth(.8)

lowess sales date,sort by(location,note("") yrescale graphregion(color(white))) c(.  l) s(oh i) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Daily Sales") bwidth(.4)

lowess sales date,sort by(location,note("") yrescale graphregion(color(white))) c(.  l) s(i i) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Daily Sales") bwidth(.4)


*Note, you can also save the smoothed values from the lowess regression using the gen() option.

lowess sales date,sort by(location) gen (lowess_sales)

tsline lowess_sales, sort by(location)

lowess sales date,sort by(location,note("") graphregion(color(white))) c(. l) s(i i) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Daily Sales") bwidth(.4) gen (lowess_sales)

tsline lowess_sales,sort by(location,note("") graphregion(color(white))) xline(19305) xlab(,labsize(tiny)) ylab(,labsize(tiny)format(%15.0fc)) ytitle("Lowess Smoothed Daily Sales")

graph export "..\figures\store_lowess_sales.png", replace

*===============================================================================
* 3. STORE-LEVEL STRUCTURAL CHANGE ANALYSIS
*===============================================================================

gen GO=1 if date>=td(08nov2012)
replace GO=0 if date<td(08nov2012)

bysort location (date): gen time=_n

gen GOtime=GO*time

tab store
tab store,nolab

reg sales time GO GOtime if store==1
outreg2 using "..\output\regression_results.xls", replace excel ctitle(Store #1)

reg sales time GO GOtime if store==2
outreg2 using "..\output\regression_results.xls", append excel ctitle(Store #2)

reg sales time GO GOtime if store==3
outreg2 using "..\output\regression_results.xls", append excel ctitle(Store #3)

reg sales time GO GOtime if store==4
outreg2 using "..\output\regression_results.xls", append excel ctitle(Store #4)

reg sales time GO GOtime if store==5
outreg2 using "..\output\regression_results.xls", append excel ctitle(Store #5)

*-------------------------------------------------------------------------------
* 3.1 LOG-SALES SPECIFICATION
*-------------------------------------------------------------------------------

gen log_sales = log(sales)
replace log_sales = . if sales <= 0

reg log_sales time GO GOtime if store==1
outreg2 using "..\output\regression_results2.xls", replace excel ctitle(Store #1)

reg log_sales time GO GOtime if store==2
outreg2 using "..\output\regression_results2.xls", append excel ctitle(Store #2)

reg log_sales time GO GOtime if store==3
outreg2 using "..\output\regression_results2.xls", append excel ctitle(Store #3)

reg log_sales time GO GOtime if store==4
outreg2 using "..\output\regression_results2.xls", append excel ctitle(Store #4)

reg log_sales time GO GOtime if store==5
outreg2 using "..\output\regression_results2.xls", append excel ctitle(Store #5)

*-------------------------------------------------------------------------------
* 3.2 ANNUALIZED SALES GROWTH RATES
*-------------------------------------------------------------------------------
* Convert estimated daily log-sales growth rates to annualized percentage
* growth rates (daily growth rate x 365) for each incumbent store.
* Original calculations were completed by hand.


*===============================================================================
* 4. TRADING-AREA ANALYSIS
*===============================================================================

collapse (sum) sales, by(date)
twoway (line sales date), xline(19305, lcolor(red) lpattern(dash)) title("Total Daily Sales in Trading Area") xtitle("Date") ytitle("Total Sales") legend(off)
graph export "..\figures\trading_area_sales.png", replace

*-------------------------------------------------------------------------------
* 4.1 STRUCTURAL CHANGE IN TOTAL TRADING-AREA SALES
*-------------------------------------------------------------------------------

collapse (sum) sales, by(date)

gen post = 1 if date>=td(08nov2012)
replace post=0 if date<td(08nov2012) // Dummy for post-opening period
gen time = date - date[1]   // Creates a sequential time trend
gen post_time = post * time       

reg sales time post post_time 
outreg2 using "..\output\structural_change.xls", replace excel ctitle(Total Sales Trend)

*-------------------------------------------------------------------------------
* 4.2 ACTUAL VS. FITTED SALES
*-------------------------------------------------------------------------------

predict fitted_sales

twoway (scatter sales time, msize(small) mcolor(blue))(line fitted_sales time, lcolor(red) lwidth(medium)),xline(19305, lcolor(black) lpattern(dash))title("Actual vs. Fitted Sales Over Time")legend(label(1 "Actual Sales") label(2 "Fitted Sales"))xtitle("Time (Days)") ytitle("Total Sales")
graph export "..\figures\trading_area_actual_vs_fitted.png", replace

twoway (line sales time, msize(small) mcolor(blue))(line fitted_sales time, lcolor(red) lwidth(medium)),xline(19305, lcolor(black) lpattern(dash))title("Actual vs. Fitted Sales Over Time")legend(label(1 "Actual Sales") label(2 "Fitted Sales"))xtitle("Time (Days)") ytitle("Total Sales")

*-------------------------------------------------------------------------------
* 4.3 LOG-SALES SPECIFICATION
*-------------------------------------------------------------------------------

gen log_sales = log(sales)
 
replace log_sales = . if sales < 0
replace log_sales = . if sales <= 0

reg log_sales time post post_time
outreg2 using "..\output\log_sales_results.xls", replace excel ctitle(Total Sales Log Model)
































































