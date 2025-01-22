/*
File: electricity_analysis.do
Author: Mariam Raheem
Date: January 22, 2025
Purpose: Analyze residential electricity consumption patterns in California and Texas
         using RECS 2020 data and calculate Value of Lost Load (VoLL)
*/

// Clear any existing data and settings
clear all
set more off

// Import the RECS 2020 dataset
	import delimited using "../Data/recs2020_public_v7.csv", clear

// Define labels for household income categories
	label define hh_income 		///
		1 "Less than $5,000"		///
		2 "$5,000 - $7,499"			///	
		3 "$7,500 - $9,999"			///
		4 "$10,000 - $12,499"		///
		5 "$12,500 - $14,999"		///
		6 "$15,000 - $19,999"		///
		7 "$20,000 - $24,999"		///
		8 "$25,000 - $29,999"		///
		9 "$30,000 - $34,999"		///
		10 "$35,000 - $39,999"		///
		11 "$40,000 - $49,999"		///
		12 "$50,000 - $59,999"		///
		13 "$60,000 - $74,999"		///
		14 "$75,000 - $99,999"		///
		15 "$100,000 - $149,999"	///
		16 "$150,000 or more", modify
	label values moneypy hh_income

// Generate income midpoints for each income category
	gen income_midpoint = .
		replace income_midpoint = 2500 if moneypy == 1
		replace income_midpoint = 7500 if moneypy == 2
		replace income_midpoint = 12500 if moneypy == 3
		replace income_midpoint = 17500 if moneypy == 4
		replace income_midpoint = 22500 if moneypy == 5
		replace income_midpoint = 27500 if moneypy == 6
		replace income_midpoint = 32500 if moneypy == 7
		replace income_midpoint = 37500 if moneypy == 8
		replace income_midpoint = 45000 if moneypy == 9
		replace income_midpoint = 55000 if moneypy == 10
		replace income_midpoint = 67500 if moneypy == 11
		replace income_midpoint = 87500 if moneypy == 12
		replace income_midpoint = 112500 if moneypy == 13
		replace income_midpoint = 137500 if moneypy == 14
		replace income_midpoint = 175000 if moneypy == 15
		replace income_midpoint = 200000 if moneypy == 16		

// Calculate the Value of Lost Load (VOLL)
replace dollarel = 0 if solar==1 & dollarel<0
gen elec_rate = dollarel / kwh
gen hourly_wage = income_midpoint / 8760

// Calculate kWh lost during power outages
gen saidi2020 = .
replace saidi2020 = 280.7 if state_name=="California"
replace saidi2020 = 419.4 if state_name=="Texas"
replace saidi2020 = saidi2020/60

gen daily_kwh = kwh / 365		
gen average_kwh_lost = daily_kwh * saidi2020

gen value_of_lost_load = .
replace value_of_lost_load = hourly_wage * 4.68 if state_name=="California"	
replace value_of_lost_load = hourly_wage * 6.99 if state_name=="Texas"	

// Total Cost of an outage
gen total_cost_of_outage = value_of_lost_load + (elec_rate * average_kwh_lost)

// Generate summary statistics for VOLL by income category
foreach state in "California" "Texas" {
	di "`state'"
	tabstat value_of_lost_load [aw=nweight] if state_name=="`state'", by(moneypy) statistics(min mean median max)
}

********************************************************************************	
********************************************************************************	
// Additional variable generation and analysis code...
********************************************************************************	
********************************************************************************	

// Regression analysis for California
	frame copy default ca_reg
	frame change ca_reg
	keep if state_name=="California"

// Run regression models and output results
* Run the first regression model
	regress value_of_lost_load ln_kwh
	eststo model1

* Run the second regression model with demographic variables
	regress value_of_lost_load ln_kwh has_child_under17 has_employment
	eststo model2

* Run the third regression model including financial assistance variables
	regress value_of_lost_load ln_kwh had_help energyasst reduce_bill_once_or_more
	eststo model3

* Run the fourth full model with all relevant variables
	regress value_of_lost_load ln_kwh has_child_under17 has_adult_under65 has_solar had_help energyasst, robust
	eststo model4

* Run the fifth model with additional controls
	regress value_of_lost_load ln_kwh has_child_under17 has_adult_under65 has_adult_over65 has_employment backup powerout has_solar has_highceil ln_sqft_en energyasst keep_unhealthy_temp disconnection_notice
	eststo model5

* Create a combined table of all models
	esttab model1 model2 model3 model4 model5 using "../Output/combined_regression_table_ca.rtf", ///
		title("Combined Regression Results") ///
		label replace se star(* 0.05 ** 0.01 *** 0.001) ///
		stats(r2 F, labels("R-squared" "F-statistic")) ///
		addnote("Standard errors in parentheses") ///
		nonotes
********************************************************************************	

// Regression analysis for Texas
	frame copy default tx_reg
	frame change tx_reg
	keep if state_name=="Texas"

// Run regression models and output results
* Run the first regression model
	regress value_of_lost_load ln_kwh
	eststo model1

* Run the second regression model with demographic variables
	regress value_of_lost_load ln_kwh has_child_under17 has_employment
	eststo model2

* Run the third regression model including financial assistance variables
	regress value_of_lost_load ln_kwh had_help energyasst reduce_bill_once_or_more
	eststo model3

* Run the fourth full model with all relevant variables
	regress value_of_lost_load ln_kwh has_child_under17 has_adult_under65 has_solar had_help energyasst, robust
	eststo model4

* Run the fifth model with additional controls
	regress value_of_lost_load ln_kwh has_child_under17 has_adult_under65 has_adult_over65 has_employment backup powerout has_solar has_highceil ln_sqft_en energyasst keep_unhealthy_temp disconnection_notice
	eststo model5

* Create a combined table of all models
	esttab model1 model2 model3 model4 model5 using "../Output/combined_regression_table_ca.rtf", ///
		title("Combined Regression Results") ///
		label replace se star(* 0.05 ** 0.01 *** 0.001) ///
		stats(r2 F, labels("R-squared" "F-statistic")) ///
		addnote("Standard errors in parentheses") ///
		nonotes
		
********************************************************************************	
	
// Label variables
	label variable dollarel "Total electricity bill"
	label variable kwh "Total electricity consumption (in kWh)"
	label variable moneypy "Household income category (coded)"
	label variable income_midpoint "Midpoint of household income category"
	label variable elec_rate "Average electricity rate (dollars per kWh)"
	label variable hourly_wage "Hourly wage calculated from income midpoint"
	label variable saidi2020 "System Average Interruption Duration Index for 2020 (in hours)"
	label variable daily_kwh "Daily electricity consumption (kWh)"
	label variable average_kwh_lost "Average kWh lost during power outages"
	label variable value_of_lost_load "Value of Lost Load (VoLL)"
	label variable total_cost_of_outage "Total cost of an outage"
	label variable has_child_under17 "Indicator for households with children under 17"
	label variable has_adult_under65 "Indicator for households with adults under 65"
	label variable has_adult_over65 "Indicator for households with adults over 65"
	label variable has_solar "Indicator for households with solar panels"
	label variable has_highschool "Indicator for households with at least a high school education"
	label variable has_college "Indicator for households with at least some college education"
	label variable has_bachelors "Indicator for households with a bachelor's degree"
	label variable had_help "Indicator for households that received financial assistance"
	label variable has_highceil "Indicator for households with high ceilings"
	label variable has_employment "Indicator for employment status of household members"
	label variable reduce_bill_once_or_more "Indicator for households that have reduced their bill at least once"
	label variable keep_unhealthy_temp "Indicator for households keeping unhealthy temperatures"
	label variable disconnection_notice "Indicator for households that received a disconnection notice"
	label variable ln_totaldol "Natural logarithm of total dollars spent on electricity"
	label variable ln_kwh "Natural logarithm of total kWh consumed"
	label variable ln_sqft_en "Natural logarithm of total square footage of the household"
		
********************************************************************************	
