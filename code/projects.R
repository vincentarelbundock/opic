source('code/load.R')

# 1961-1971
usaid = readr::read_csv('data_raw/projects_usaid_2015-06-11.csv') %>%
        setNames(c('investor_us', 'country',
                   'investor_foreign', 'country2',
                   'project', 'date_effective',
                   'date_term', 'date_ant',
                   'page', 'automatic')) %>%
        dplyr::select(-page, -automatic) %>%
        dplyr::mutate(date_effective = lubridate::mdy(date_effective),
                      date_term = lubridate::mdy(date_term),
                      date_ant = lubridate::mdy(date_ant),
                      year = lubridate::year(date_effective),
                      country = ifelse(is.na(country), country2, country),
                      # to the best of our knowledge, all entries refere to
                      # insurance contracts
                      support_type = 'Insurance', 
                      source = 'USAID FOIA request 2015-06-11') %>%
        dplyr::select(-country2) %>%
        unique

# 1974-2009
historical = read_excel('data_raw/projects_historical_2011-05-10.xlsx') %>%
             setNames(c('year', 'country',
                        'investor_us', 'investor_foreign',
                        'sector', 'project',
                        'amount', 'support_type')) %>%
             dplyr::mutate(source = 'historical projects list xlsx 2011-05-10',
                           year = stringr::str_extract(year, '\\d{4}'),
                           year = as.numeric(year)) %>%
             # drop non-project rows
             dplyr::filter(!str_detect(year, '^Total')) %>%
             unique

# 2010-2017
webscrape = readr::read_csv('data_raw/projects_opic_web_scrape_2018-04-25.csv') %>%
            dplyr::mutate(year = lubridate::year(date_effective)) %>%
            unique

# Combine different time periods
dat = dplyr::bind_rows(usaid, historical, webscrape)

# Merge sector data
sec = readr::read_csv('data_raw/sectors_2019-01-04.csv') %>%
      dplyr::rename(sector_clean = sector)
dat = dat %>%
      # string normalization 
      dplyr::mutate(project = toupper(project),
                    project = stringr::str_trim(project)) %>%
      # join
      dplyr::left_join(sec)

# Merge firm names
fir = readr::read_csv('data_raw/firms_2019-01-04.csv') %>%
      unique
dat = dat %>%
      # string normalization 
      dplyr::mutate(investor_us = toupper(investor_us),
                    investor_us = stringr::str_trim(investor_us),
                    investor_us = stringr::str_replace_all(investor_us, ',', ''),
                    investor_us = stringr::str_replace_all(investor_us, '\\.', ''),
                    investor_us = stringr::str_replace(investor_us, '\\s+\\[', '')
                    ) %>%
      # join
      dplyr::left_join(fir)

# Remaining missing firm names
dat$investor_us_clean = ifelse(is.na(dat$investor_us_clean), dat$investor_us, dat$investor_us_clean)
dat$investor_us_clean = ifelse(is.na(dat$investor_us_clean), dat$investor_foreign, dat$investor_us_clean)

# Country codes
dat = dat %>% 
      dplyr::mutate(country = stringr::str_trim(country),
                    country = stringr::str_replace(country, 'HAITL', 'HAITI'),
                    country = stringr::str_replace(country, 'ETHOPIA', 'ETHIOPIA'),
                    country = stringr::str_replace(country, 'PROT OF SPAIN ', ''),
                    country = stringr::str_replace(country, 'PORT OF SPAIN ', ''),
                    iso3c = if_else(country == 'YUGOSLAVIA', 'YUG', iso3c),
                    iso3c = if_else(country == 'KOSOVO', 'KSV', iso3c),
                    iso3c = if_else(country == 'CZECHOSLOVAKIA', 'CZE', iso3c),
                    iso3c = if_else(country == 'YEMEN ARAB REPUBLIC', 'YEM', iso3c),
                    iso3c = if_else(is.na(iso3c), 
                                   countrycode(country, 'country.name', 'iso3c'),
                                   iso3c))

# Merge GDP deflator
dat = read.csv('data_clean/deflator_2019-01-09.csv') %>%
      dplyr::right_join(dat, by = 'year') %>%
      dplyr::mutate(amount_real = amount / deflator)

# Cleanup, sort, and write
dat = dat %>%
      dplyr::mutate(support_type = stringr::str_trim(support_type),
                    support_type = ifelse(support_type == "Funds", "Investment Funds", support_type)) %>%
      dplyr::arrange(year, investor_us, iso3c, country) %>%
      dplyr::select(investor_us, investor_foreign, iso3c, year, order(names(.)))
fn = paste0('data_clean/projects_', Sys.Date(), '.csv')
write.csv(dat, fn, row.names = FALSE)
