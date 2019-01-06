source('code/load.R')

deflator = WDI(indicator = c('deflator' = 'NY.GDP.DEFL.ZS'),
               country = 'US', start = 1960, end = 2018) %>%
           dplyr::mutate(deflator = deflator / max(deflator)) %>%
           dplyr::arrange(year) %>%
           dplyr::select(year, deflator)

fn = paste0('data_clean/deflator_', Sys.Date(), '.csv')
write.csv(deflator, fn, row.names = FALSE)
