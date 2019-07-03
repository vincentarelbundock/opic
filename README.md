# Political Risk Insurance and Finance Dataset

This project aims to make available firm-level information about every insurance contract issued, financing project initiated, and insurance claim settled by the US Overseas Private Investment Corporation.

http://www.opic.gov (2019-01-06):

> The Overseas Private Investment Corporation (OPIC) is a self-sustaining U.S. Government agency that helps American businesses invest in emerging markets. Established in 1971, OPIC provides businesses with the tools to manage the risks associated with foreign direct investment, fosters economic development in emerging market countries, and advances U.S. foreign policy and national security priorities. OPIC helps American businesses gain footholds in new markets, catalyzes new revenues and contributes to jobs and growth opportunities both at home and abroad. OPIC fulfills its mission by providing businesses with financing, political risk insurance, advocacy and by partnering with private equity investment fund managers.

# Download

The dataset will be modified with updates and corrections as needed. We recommend that you use one of the "official" tagged versions of this project in your research: https://github.com/vincentarelbundock/opic/releases

# Licence and citation

The contents of this repository are licensed under Attribution 4.0 International (CC BY 4.0), which allows you to copy, share, and adapt, as long as you give appropriate credit and indicate if changes were made.

Appropriate credit is given by citing:

Arel-Bundock, Vincent, Clint Peinhardt, and Amy Pond. Forthcoming. "Political Risk Insurance: A New Firm-Level Dataset" *Journal of Conflict Resolution*.

Preprint copy of this article: https://osf.io/uz4tx/

```
@article{ArePeiPonForthcoming,
  title={Political Risk Insurance: A New Firm-Level Dataset},
  author={Arel-Bundock, Vincent and Peinhardt, Clint and Pond, Amy},
  journal={Journal of Conflict Resolution},
  volume={},
  issue={},
  pages={},
  year={Forthcoming},
  doi={}
}
```

Note that the `claims_annual_report` and `projects_historical` files in the `data_raw` folder were produced by OPIC. We do not own the rights to these files.

# Temporal coverage

* The `projects` dataset combines data from three separate sources which cover the years: 1961-1971, 1974-2009, 2010-2017.
* The `claims` dataset covers the years 1966-2017.

# Files

## data_clean/

* `projects_DATE.csv`
    - Created by the `clean_projects.R` script in the `code` folder by combining 3 databases:
        + `projects_historical_DATE.xlsx`
        + `projects_opic_web_scrape_DATE.csv`
        + `projects_usaid_DATE.pdf`
* `claims_DATE.csv`
    - Created using OCR and manual editting from the annual claims file (see `data_raw`).
* `panel_DATE.csv`
    - "Rectangular" panel date at the investor-country-year
* `deflator_DATE.csv`
    - US GDP deflator from the World Bank's World Development Indicators

## data_raw/

* `projects_historical_DATE.xlsx`
    - List of historical OPIC projects emailed to Vincent Arel-Bundock by OPIC staff on 2011-05-10.
    - Coverage: 1974-2009
* `projects_opic_web_scrape_2018-04-25.csv`
    - List of active OPIC projects scraped from OPIC's website on two different occasion by Vincent Arel-Bundock (see dates in the CSV).
    - Coverage: 2010-2017
* `projects_usaid_2015-06-11.pdf`
    - List of historical USAID projects emailed to Amy Pond on 2015-06-11 in response to her FOIA request.
    - Coverage: 1961-1971
* `projects_usaid_2015-06-11.csv`
    - PDF converted to CSV by OCR, with some entries corrected manually.
* `claims_annual_report_2017.pdf`
    - Annual claims report downloaded from the OPIC website
* `firms_2019-01-04.csv`
    - Firm names appear in slightly different variations in the original OPIC files. To normalize firm names, we created this "dictionary" in several steps using both fuzzy matching and manual edits.
* `sectors_2019-01-04.csv`
    - Sector information was incomplete in the original OPIC files. We filled-in the missing entries manually based on project descriptions, but kept the original OPIC codings where possible.

## code/

* `projects.R`: Merge and harmonize the three projects databases
* `panel.R`: A convenience script to merge the claims and projects file to create a "rectangular" investor-country-year panel dataset.
* `deflator.R`: A convenience script to download US GDP deflator data.
* `tests.R`: Unit testing to make sure that merge and cleanup work OK

# Variables

## data_clean/projects_DATE.csv

* investor_us
* investor_us_clean
    - Normalized investor names
* investor_foreign
    - Normalized investor name to facilitate merging with the claims data. Corresponds to the `investor_project` column in the clean claims CSV.
* iso3c
    - ISO country code
* year
* amount
* country
* country_development 
    - As reported on OPIC's website
* country_environment
    - As reported on OPIC's website
* country_income
    - As reported on OPIC's website
* country_labor
    - As reported on OPIC's website
* date_ant
    - Source: USAID PDF
* date_effective
    - Source: USAID PDF
* date_term
    - Source: USAID PDF
* project_id
    - As reported on OPIC's website
* region
    - As reported on OPIC's website
* sector
* sector_clean 
* source
    - Indicates the source of the data for each entry.
* support_type 
* url
    - URL of the project description.

## data_clean/claims_DATE.csv

* amount_cash
* amount_guaranty
* amount_settlement
* claim_type
* country
* industry
    - As written in OPIC's annual claims report
* investor_claim
    - Investor name as written in OPIC's annual claims report
* investor_doubt
    - TRUE if there remains important doubt about the match between an insurance claim and its underlying contract (i.e., `investor_project` and `investor_us`).
* investor_note
* investor_project
    - Investor name as written in OPIC's projects files. Corresponds to the `investor_us` column in the clean projects CSV.
* iso3c
    - ISO country code (+ the non-standard YUG, CZE, KSV)
* note_year
    - Note about the event date
* year_fiscal
    - OPIC's annual claims report records claims under the fiscal year when they were settled, *not* under the year of the actual event.
* year_event
    - Year of the actual event, according to Kantor et al. Unfortunately, this variable remains highly incomplete. In the sample where where we have found the year of event the modal and median gaps between year_event and year_fiscal is 1. Users could choose to impute their missing data as `year_event = year_fiscal - 1`. 
* year_note
    - Note about the event year.

## data_clean/panel_DATE.csv

* investor
* iso3c
* year
* claim
    - Did an event occur in tha tyear which led to a claim?
* claim_expropriation
* claim_inconvertibility
* claim_violence
* claim_war
* finance
    - Did OPIC launch a finance project with investor during that year?
* fund
    - Did OPIC launch an investment funds project with investor during that year?
* insurance
    - Did an OPIC insurance contract become effective during that year?
* insurance_duration
    - Number of years since the most recent insurance contract came into effect. NA means that no insurance contract exists at that point in time. 1 means an insurance contract came in the same year.
* sec_*
    - Binary variable which indicates if there has been a finance or insurance project in the past for that investor-country unit.

# Did you find an error? Do you want to contribute?

The best way to suggest error corrections to the database is to creat a Pull Request on GitHub. If you modify a CSV file, please make sure that you don't modify all rows by accident (e.g., with weird Excel linebreaks). This will make it easier for us to check the file differences and merge any change.

If you do not feel comfortable with git but still want to contribute, please email: vincent.arel-bundock@umontreal.ca

# References

Kantor, Mark, Michael D. Nolan, and Karl P Sauvant. 2011. Reports of Overseas Private Investment Corporation Determinations. Oxford University Press.
