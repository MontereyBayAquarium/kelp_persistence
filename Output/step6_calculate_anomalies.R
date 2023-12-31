##Joshua G. Smith
#May 15, 2023

rm(list=ls())
librarian::shelf(tidyverse)

# Set Directories
basedir <-here::here("output")
figdir <- here::here("figures")

# load data
cb_orig <- readRDS(file.path(basedir,"environmental_data/processed/1988_2022_cuti_beuti_daily_by_PISCO_site.Rds"))
sst_orig <- readRDS(file.path(basedir,"environmental_data/processed/2002_2022_mursst_monthly_by_PISCO_site.Rds"))

################################################################################
#process cuti and beuti

#establish annual baseline at each site
cb_annual_baseline <- cb_orig %>%
                filter(year <=2012) %>%
                group_by(site)%>%
                dplyr::summarize(cuti_annual_baseline = mean(cuti, na.rm=TRUE),
                                 cuti_annual_sd = sd(cuti, na.rm=TRUE),
                                 beuti_annual_baseline = mean(beuti, na.rm=TRUE),
                                 beuti_annual_baseline = sd(beuti, na.rm=TRUE))


#establish baseline for each month at each site
cb_month_base <- cb_orig %>%
  filter(year <=2012) %>%
  group_by(site, month)%>%
  dplyr::summarize(cuti_month_baseline = mean(cuti, na.rm=TRUE),
                   cuti_month_sd = sd(cuti, na.rm=TRUE),
                   beuti_month_baseline = mean(beuti, na.rm=TRUE),
                   beuti_month_baseline_sd = sd(beuti, na.rm=TRUE))


#calculate average monthly observed and anomalies
cb_monthly_obs <- cb_orig %>%
                    group_by(year, month, site)%>%
                    dplyr::summarize(cuti_month_obs = mean(cuti, na.rm=TRUE),
                                     cuti_month_obs_sd = sd(cuti, na.rm=TRUE),
                                     beuti_month_obs = mean(beuti, na.rm=TRUE),
                                     beuti_month_obs_sd = sd(beuti, na.rm=TRUE)) %>%
                    #join baselines
                    left_join(cb_annual_baseline, by=c("site"))%>%
                    left_join(cb_month_base, by=c("site","month")) %>%
                    #calcualte anomalies
                    mutate(cuti_month_anom = cuti_month_obs - cuti_month_baseline,
                           beuti_month_anom = beuti_month_obs - beuti_month_baseline)

################################################################################
#process sst

#establish annual baseline
sst_annual_baseline <- sst_orig %>%
  mutate(year = lubridate::year(date),
         month = lubridate::month(date),
         day=lubridate::month(date))%>%
  data.frame()%>%
  filter(year <=2012) %>%
  group_by(site)%>%
  dplyr::summarize(sst_annual_baseline = mean(sst_c, na.rm=TRUE),
                   sst_annual_baseline_sd = sd(sst_c, na.rm=TRUE))

#establish monthly baseline
sst_month_baseline <- sst_orig %>%
  mutate(year = lubridate::year(date),
         month = lubridate::month(date),
         day=lubridate::month(date))%>%
  data.frame()%>%
  filter(year <=2012) %>%
  group_by(site, month)%>%
  dplyr::summarize(sst_month_baseline = mean(sst_c, na.rm=TRUE),
                   sst_month_baseline_sd = sd(sst_c, na.rm=TRUE))

#calculate monthly observed and anomalies
sst_monthly_obs <- sst_orig %>%
  mutate(year = lubridate::year(date),
         month = lubridate::month(date),
         day=lubridate::month(date))%>%
  data.frame()%>%
  group_by(year, month, site)%>%
  dplyr::summarize(sst_month_obs = mean(sst_c, na.rm=TRUE),
                   sst_month_obs_sd =mean(sst_c, na.rm = TRUE)) %>%
  #join baselines
  left_join(sst_annual_baseline, by=c("site"))%>%
  left_join(sst_month_baseline, by=c("site","month")) %>%
  #calcualte anomalies
  mutate(sst_month_anom = sst_month_obs - sst_month_baseline)

################################################################################
#join beuti, cuti, and sst

envr_dat <- left_join(cb_monthly_obs, sst_monthly_obs, by=c("year","month","site"))


# Export data
saveRDS(envr_dat, file.path(basedir, "environmental_data/processed/beuti_cuti_sst_monthly_anoms_by_PISCO_site.Rds"))




