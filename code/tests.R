source('code/load.R')

context('Basic post-merge tests')

claims = read_csv_last('data_clean/claims_2')
projects = read_csv_last('data_clean/projects_2')
panel = read_csv_last('data_clean/panel_2')

test_that('there are some rows', {
    expect_true(nrow(claims) > 0)
    expect_true(nrow(projects) > 0)
    expect_true(nrow(panel) > 0)
})

test_that('duplicate observations in the panel', {
    tmp = panel %>% 
          janitor::get_dupes(investor, iso3c, year) %>%
          nrow
    expect_true(tmp == 0)
})
