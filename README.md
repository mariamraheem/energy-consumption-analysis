---
editor_options: 
  markdown: 
    wrap: 72
---

# Electricity Consumption Analysis: California vs Texas

## Project Overview

This repository contains research materials, data analysis scripts, and
findings for a comparative study on residential energy consumption in
California and Texas. The analysis focuses on the Value of Lost Load
(VoLL) and its implications for energy affordability across different
income levels.

## Repository Structure

-   `/Code`: Contains R and STATA analysis scripts
-   `/Raw`: Raw data files
-   `/Output`: Generated tables, graphs, and other outputs

## Code Files

### R Analysis (`electricity_analysis.Rmd`)

This R Markdown file performs the following tasks:

-   Data pre-processing and cleaning of RECS and SEDS datasets

-   Calculation of key metrics e.g. energy burden

-   Visualization of energy affordability across income levels

-   Statistical modeling of Value of Lost Load implications (see sample
    paper)

To run:

1.  Ensure you have R and required packages installed

2.  Set the EIA API key as an environment variable:
    `Sys.setenv(EIA_API_KEY = "your_api_key_here")`

3.  Set the output directory: `Sys.setenv(OUTPUT_DIR = "./Output")`

4.  Open the .Rmd file in RStudio and click 'Knit'

### STATA Analysis (`electricity_analysis.do`)

This STATA script conducts:

-   Time series analysis of electricity consumption trends

-   ARIMA modeling for consumption forecasting

-   Structural break tests and unit root analysis

-   Correlation and volatility comparisons between states

-   *Note: The micro-level analysis including regressions and
    willingness to pay estimates can be provided upon request*

To run:

1.  Ensure STATA is installed

2.  Open STATA and navigate to the `/Code` directory

3.  Run the command: `do electricity_analysis.do`

### Data Sources

-   U.S. Energy Information Administration (EIA) State Energy Data
    System (SEDS)
-   Residential Energy Consumption Survey (RECS) 2020
-   American Community Survey (ACS) 2018-2022
-   System Average Interruption Duration Index (SAIDI)

### Author

Mariam Raheem

### License

This project is licensed under the MIT License - see the LICENSE.md file
for details.

### Acknowledgments

-   EIA for providing comprehensive energy data
-   Professor Don Coursey for designing and teaching the Environmental
    Science & Policy course at Harris School of Public Policy
