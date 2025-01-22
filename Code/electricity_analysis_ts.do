/*
File: electricity_analysis.do
Author: Mariam Raheem
Date: January 22, 2025
Purpose: Analyze electricity consumption patterns in California and Texas using EIA SEDS data
*/

clear all
set more off
pause on

	// Set the color scheme for graphs
	set scheme white_ptol

	// CHANGE DIRECTORY HERE
*	cd "[UPDATE PATH] /GitHub/energy-consumption-analysis/"

	if c(username) == "mariamraheem" {
		cd "~/Documents/GitHub/energy-consumption-analysis/"
	}
	
	// Define global macros for file paths
	gl raw     = "Raw/"
	gl clean   = "Output/"

	// Import the SEDS data
	import delimited "${raw}Complete_SEDS.csv", clear

	// Keep only California and Texas data
	keep if inlist(statecode,"CA", "TX")

	// Generate FIPS codes for CA and TX
	gen fips_code = .
	replace fips_code = 06 if statecode=="CA"
	replace fips_code = 48 if statecode=="TX"

	// Reshape the data from long to wide format
	reshape wide data, i(data_status statecode year) j(msn, string)

	// Set the panel data structure
	tsset fips_code year

	// Keep data from 2002 onwards
	keep if year >= 2002

	// Rename variables for clarity
		// estxp: Total energy consumption expenditures (ES = Energy Source, TX = Total, P = Physical units)
		// estxd: Total energy consumption (ES = Energy Source, TX = Total, D = Data in physical units)
		// estxv: Total energy consumption (ES = Energy Source, TX = Total, V = Value in million dollars)
		// lotcb: Total energy losses and co-products (LO = Losses, TC = Total Consumption, B = British thermal units)
		// esvhp: Total energy consumption per capita (ES = Energy Source, V = Value, H = Per capita, P = Physical units)
	ren (dataESTXP dataESTXD dataESTXV dataLOTCB dataESVHP) (estxp estxd estxv lotcb esvhp) 

	* Generate log variables for analysis
	gen ln_estxp = ln(estxp)  // Log of total end-use consumption
	gen ln_estxd = ln(estxd)  // Log of average price
	gen ln_estxv = ln(estxv)  // Log of total expenditures
	gen ln_lotcb = ln(lotcb)   // Log of total electrical system energy losses
	gen ln_esvhp = ln(esvhp)   // Log of electricity consumed for EV use

	label variable ln_estxp "Electricity Consumption (Million kWh)"
	label variable ln_estxd "Electricity Price (Dollars per Million Btu)"
	label variable ln_estxv "Electricity Expenditures (Million dollars)"
	label variable ln_lotcb "Electrical System Energy Losses (Billion Btu)"

* Step 3: Descriptive analysis
* Plot electricity consumption for California and Texas
tsline ln_estxp if statecode == "CA", title("California Electricity Consumption") ///
    ytitle("Log Consumption (Million kWh)") xtitle("Year")

tsline ln_estxp if statecode == "TX", title("Texas Electricity Consumption") ///
    ytitle("Log Consumption (Million kWh)") xtitle("Year")

* Plot electricity profiles for California and Texas
tsline ln_estxp ln_estxd ln_estxv ln_lotcb if statecode=="CA", ///
    title("Electricity Consumption, Price, Expenditures, and Losses") ///
    subtitle("California") ///
    ytitle("Log Values") xtitle("Year") tlabel(2000(5)2022) ///
    legend(label(1 "Consumption") label(2 "Price") label(3 "Expenditures") label(4 "Losses")) ///
    name(cal_profile1) ///
    ylabel(0(3)15) xscale(range(2000 2022))

tsline ln_estxp ln_estxd ln_estxv ln_lotcb if statecode=="TX", ///
    title("Electricity Consumption, Price, Expenditures, and Losses") ///
    subtitle("Texas") ///
    ytitle("Log Values") xtitle("Year") tlabel(2000(5)2022) ///
    legend(label(1 "Consumption") label(2 "Price") label(3 "Expenditures") label(4 "Losses")) ///
    name(tex_profile1) ///
    ylabel(0(3)15) xscale(range(2000 2022))
		
foreach var in ln_estxp ln_estxd ln_estxv ln_lotcb {
    local title: variable label `var'
    tsline `var' if statecode=="CA" || tsline `var' if statecode=="TX", ///
        title("`title'", size(medsmall)) ///
        ytitle("Log Values") xtitle("Year") tlabel(2000(5)2022) ///
        legend(label(1 "California") label(2 "Texas")) ///
        name(`var'_comparison, replace)
}

graph combine ln_estxp_comparison ln_estxd_comparison ln_estxv_comparison ln_lotcb_comparison, ///
    rows(2) cols(2) title("Electricity Market Comparison")

********************************************************************************
	
arima ln_estxp if statecode == "CA", arima(1,1,1)
arima ln_estxp if statecode == "TX", arima(1,1,1)

foreach state in "CA" "TX" {
    arima ln_estxp if statecode == "`state'", arima(1,1,1)
    predict fitted_`state' if statecode == "`state'", y
}

twoway (line ln_estxp year if statecode == "CA") ///
       (line fitted_CA year if statecode == "CA") ///
       (line ln_estxp year if statecode == "TX") ///
       (line fitted_TX year if statecode == "TX"), ///
       title("Electricity Consumption: CA vs TX") ///
       ytitle("Log Consumption") xtitle("Year") ///
       legend(label(1 "CA Actual") label(2 "CA Fitted") ///
              label(3 "TX Actual") label(4 "TX Fitted")) ///
	    note("Fitted lines represent ARIMA(1,1,1) model predictions") ///
       caption("Source: EIA State Energy Data System.", size(small)) ///
	   name(ln_estxp, replace)

********************************************************************************
* Long-term Trend Analysis
foreach var in ln_estxp ln_estxd ln_estxv ln_lotcb {
    local varlabel : variable label `var'
    reg `var' year if statecode == "CA"
   
	predict trend_ca_`var' if statecode == "CA"
    reg `var' year if statecode == "TX"
    predict trend_tx_`var' if statecode == "TX"
    
    twoway (scatter `var' year if statecode == "CA") (line trend_ca_`var' year if statecode == "CA") ///
           (scatter `var' year if statecode == "TX") (line trend_tx_`var' year if statecode == "TX"), ///
           title("`varlabel'") legend(label(1 "CA Actual") label(2 "CA Trend") ///
           label(3 "TX Actual") label(4 "TX Trend")) name(viz_`var', replace)
}


* Correlation Analysis
foreach state in CA TX {
    correlate ln_estxp ln_estxd ln_estxv ln_lotcb if statecode == "`state'"
}

* Volatility Comparison
foreach var in ln_estxp ln_estxd ln_estxv ln_lotcb {
    foreach state in CA TX {
        summarize `var' if statecode == "`state'", detail
        display "Coefficient of Variation for `var' in `state': " r(sd)/r(mean)
    }
}

* Structural Break Test
foreach var in ln_estxp ln_estxd ln_estxv ln_lotcb {
    foreach state in CA TX {
        reg `var' year if statecode == "`state'"
        estat sbsingle
    }
}	

foreach var in ln_estxp ln_estxd ln_estxv ln_lotcb {
	foreach state in CA TX {
		display "`state' - `var'" 
		dfuller `var' if statecode=="`state'"
	} 
}

********************************************************************************
// Based on the Dickey-Fuller test results, we'll model the California and Texas electricity consumption series differently. Here's how we can approach this:
// For California (Stationary Series):
// We can use an ARMA (AutoRegressive Moving Average) model, as the series is stationary.
* For California
arima ln_estxp if statecode=="CA", arima(1,0,1)
predict ca_forecast if statecode=="CA", dynamic(2023)

// For Texas (Non-Stationary Series):
// We'll use an ARIMA (AutoRegressive Integrated Moving Average) model, typically starting with first-order differencing.
* For Texas
arima ln_estxp if statecode=="TX", arima(1,1,1)
predict tx_forecast if statecode=="TX", dynamic(2023)

// After fitting these models, we can compare their forecasts:
tsline ln_estxp ca_forecast if statecode=="CA", title("California Forecast")
tsline ln_estxp tx_forecast if statecode=="TX", title("Texas Forecast") name(t)


********************************************************************************
********************************************************************************
* California Correlogram
ac ln_estxp if statecode=="CA", lags(20) title("California") name(ca_ac, replace)

* Texas Correlogram
ac ln_estxp if statecode=="TX", lags(20) title("Texas") name(tx_ac, replace)

graph combine ca_ac tx_ac, ///
    title("Correlograms for Log Electricity Consumption") ///
    subtitle("California and Texas, 2002-2022") ///
    note("AC: Autocorrelation") ///
    rows(1) ysize(10) xsize(20) name(combined_correlograms0, replace)

* Export the combined graph
graph export "$clean/combined_correlograms_cons.png", replace width(1600) height(900)

********************************************************************************

* California Correlogram
ac ln_estxd if statecode=="CA", lags(20) title("California") name(ca_ac, replace)

* Texas Correlogram
ac ln_estxd if statecode=="TX", lags(20) title("Texas") name(tx_ac, replace)

graph combine ca_ac tx_ac, ///
    title("Correlograms for Log Electricity Price") ///
    subtitle("California and Texas, 2002-2022") ///
    note("AC: Autocorrelation") ///
    rows(1) ysize(10) xsize(20) name(combined_correlograms1, replace)

* Export the combined graph
graph export "$clean/combined_correlograms_price.png", replace width(1600) height(900)

********************************************************************************

* California Correlogram
ac ln_estxv if statecode=="CA", lags(20) title("California") name(ca_ac, replace)

* Texas Correlogram
ac ln_estxv if statecode=="TX", lags(20) title("Texas") name(tx_ac, replace)

graph combine ca_ac tx_ac, ///
    title("Correlograms for Log Electricity Expenditure") ///
    subtitle("California and Texas, 2002-2022") ///
    note("AC: Autocorrelation") ///
    rows(1) ysize(10) xsize(20) name(combined_correlograms2, replace)

* Export the combined graph
graph export "$clean/combined_correlograms_exp.png", replace width(1600) height(900)

********************************************************************************
********************************************************************************

* Generate autocorrelation plot with annotations
ac ln_estxp if statecode=="CA", lags(20) ///
    title("Autocorrelation Function for California Log Electricity Consumption", size(small)) ///
    subtitle("2002-2022") ///
    ytitle("Autocorrelation") ///
    xtitle("Lag") ///
    ylabel(-1(0.2)1) ///
    xlabel(0(2)20) ///
    yline(0) /// Add a horizontal line at y=0
    text(0.75 1 "Strong positive" "autocorrelation", size(vsmall) place(e)) ///
    text(-0.2 4 "Becomes negative", size(vsmall) place(w)) ///
    text(-0.4 12 "Possible seasonal" "pattern", size(vsmall) place(w)) ///
    text(0.4 20 "Weak long-term" "dependencies", size(vsmall) place(w)) ///
    name(ca_ac_annotated, replace)

* Export the graph
graph export "$clean_california_acf_annotated.png", replace width(1600) height(900)
/* 
Remarks:
1. The strong positive autocorrelation at lag 1 suggests high persistence in the series.
2. The quick decay in autocorrelation indicates a relatively short memory process.
3. The oscillating pattern and negative autocorrelations around lags 4-6 and 11-13 
   hint at possible seasonal effects, which could be quarterly or annual.
4. Autocorrelations become small after lag 13, indicating weak long-term dependencies.
5. The overall pattern suggests an ARMA model might be appropriate, possibly with 
   seasonal components.
6. The statistically significant Q statistic (not shown in the graph) up to lag 20 
   confirms that the series is not white noise.
*/


*********************************************************************************

* Generate autocorrelation plot for Texas
ac ln_estxp if statecode=="TX", lags(20) ///
    title("Autocorrelation Function for Texas Log Electricity Consumption", size(small)) ///
    subtitle("2002-2022") ///
    ytitle("Autocorrelation") ///
    xtitle("Lag") ///
    ylabel(-1(0.2)1) ///
    xlabel(0(2)20) ///
    yline(0) /// Add a horizontal line at y=0
	text(0.9 1.1 "Strong positive" "autocorrelation", size(vsmall) place(e)) /// Highlight strong positive correlation at lag 1
    text(-0.5 19 "Weak negative trend" "emerging", size(vsmall) place(w)) /// Indicate weak negative trend at lag 19
    name(tx_ac_annotated, replace)

* Export the graph
graph export "$clean_texas_acf_annotated.png", replace width(1600) height(900)

/* 
Remarks:
1. The strong positive autocorrelation at lag 1 (0.8026) indicates a high persistence in the series.
2. The autocorrelation values decrease but remain significant through lag 6, suggesting a strong short-term memory.
3. The transition to negative autocorrelations by lag 8 indicates a shift in the relationship, possibly reflecting seasonal effects or structural changes.
4. The sustained negative autocorrelations from lag 9 onward suggest that past values have a diminishing effect on future values, indicating potential mean-reverting behavior.
5. The statistically significant Q statistic across lags confirms that the series is not white noise and exhibits significant temporal dependence.
*/
