source('code/load.R')

# load projects data
pro = read_csv_last('data_clean/projects_2')

# support_type -> sector dummies
sec_raw = pro$sector_clean %>% unique %>% na.omit %>% sort 
sec_clean = sec_raw %>% 
            make.names %>%
            paste0('sec_', .) %>%
            str_to_lower %>% 
            str_replace_all('\\.+', '_') %>% 
            str_trunc(40, 'right', ellipsis = '_')
for (i in seq_along(sec_raw)) {
    pro[[sec_clean[i]]] = as.numeric(pro$sector_clean == sec_raw[i])
}

# collapse to investor-country-year 
pro = pro %>% 
      # split support_type into three distinct columns
      dplyr::mutate(finance = ifelse(support_type == 'Finance', 1, 0),
                    insurance = ifelse(support_type == 'Insurance', 1, 0),
                    fund = ifelse(support_type == 'Investment Funds', 1, 0),
                    project = 1) %>%
      # select a minimal set of variables
      dplyr::select(investor = investor_us_clean, 
                    dplyr::matches('iso|year$|finance|fund|insurance|project|^sec_')) %>%
      # total number of projects per support_type per investor-country-year
      dplyr::select(-project_id) %>%
      dplyr::group_by(investor, iso3c, year) %>%
      dplyr::summarize_all(sum, na.rm = TRUE) %>%
      dplyr::ungroup()

# rectangular investor-iso3c-year panel
a = data.frame('year' = min(pro$year):max(pro$year))
b = pro[, c('investor', 'iso3c')] %>% unique
rec = merge(b, a, all = TRUE)
pro = dplyr::left_join(rec, pro, c('investor', 'iso3c', 'year')) 

# trail sector dummies
trail = function(x) zoo::na.locf(x, na.rm = FALSE)
fillna = function(x) ifelse(is.na(x), 0, x)
binary = function(x) ifelse(x > 0, 1, 0)
pro = pro %>%
      dplyr::arrange(investor, iso3c, year) %>%
      dplyr::group_by(investor, iso3c) %>%
      dplyr::mutate_at(vars(dplyr::matches('^sec_')), trail) %>% 
      dplyr::mutate_at(vars(dplyr::matches('^sec_')), fillna) %>% 
      dplyr::mutate_at(vars(dplyr::matches('^sec_')), binary) 

# number of years since the last project/insurance contract
pro = pro %>%
      dplyr::arrange(investor, iso3c, year) %>%
      dplyr::group_by(investor, iso3c) %>%
      dplyr::mutate(project = ifelse(is.na(project), 0, project),
                    finance = ifelse(is.na(finance), 0, finance),
                    fund = ifelse(is.na(fund), 0, fund),
                    insurance = ifelse(is.na(insurance), 0, insurance),
                    project_cumsum = cumsum(project),
                    insurance_cumsum = cumsum(insurance)) %>%
      # insurance_cumsum changes whenever new contracts are issued for a given
      # investor-country unit. We use that information to reset the contract
      # duration counter.
      dplyr::group_by(investor, iso3c, project_cumsum) %>%
      dplyr::mutate(project_duration = 1:n()) %>%
      dplyr::group_by(investor, iso3c, insurance_cumsum) %>%
      dplyr::mutate(insurance_duration = 1:n()) %>%
      dplyr::ungroup() %>%
      # insurance_duration = NA before the first contract is issued
      dplyr::mutate(project_duration = ifelse(project_cumsum == 0, NA, project_duration)) %>%
      dplyr::mutate(insurance_duration = ifelse(insurance_cumsum == 0, NA, insurance_duration)) %>%
      dplyr::select(-project_cumsum, -insurance_cumsum) %>%
      tidyr::drop_na(project_duration)

# merge claims
f = function(x) ifelse(is.na(x), 0, x)
cla = read_csv_last('data_clean/claims_2')
cla = cla %>% 
      dplyr::mutate(year = ifelse(!is.na(year_event), year_event, year_fiscal - 1),
                    claim = 1,
                    claim_inconvertibility = ifelse(claim_type == 'Inconvertibility', 1, 0),
                    claim_expropriation = ifelse(claim_type == 'Expropriation', 1, 0),
                    claim_war = ifelse(claim_type == 'War damage', 1, 0),
                    claim_violence = ifelse(claim_type == 'Political violence', 1, 0)
                    ) %>%
      dplyr::select(investor = investor_project, iso3c, year, dplyr::matches('^claim'), -claim_type) %>%
      dplyr::filter(!is.na(investor)) %>%
      # multiple claims per year
      dplyr::group_by(investor, iso3c, year) %>%
      dplyr::summarize_all(funs(sum)) %>%
      dplyr::ungroup()

dat = pro %>% left_join(cla, by = c('investor', 'iso3c', 'year')) %>%
      dplyr::mutate_at(vars(dplyr::matches('^claim')), funs(f))

# clean and write to file
dat = dat %>%
      dplyr::arrange(investor, iso3c, year) %>%
      dplyr::select(investor, iso3c, year, order(names(.)))

fn = paste0('data_clean/panel_', Sys.Date(), '.csv')
readr::write_csv(dat, fn)
