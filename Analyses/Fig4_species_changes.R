#Communtiy change analyses
#Joshua G. Smith; jossmith@mbayaq.org

rm(list=ls())

librarian::shelf(tidyverse, here, ggplot2, mvabund, MBAcolors)

#devtools::install_github("MontereyBayAquarium/MBAcolors")


################################################################################
#set directories and load data
basedir <- here::here("output")
figdir <- here::here("figures")
tabdir <- here::here("tables")

#load raw dat
swath_raw <- read.csv(file.path(basedir, "monitoring_data/processed/kelp_swath_counts_CC.csv"))

upc_raw <- read.csv(file.path(basedir, "monitoring_data/processed/kelp_upc_cov_CC.csv")) 

fish_raw <- read.csv(file.path(basedir, "monitoring_data/processed/kelp_fish_counts_CC.csv"))

#load species attribute table
spp_attribute <- read.csv(file.path(tabdir,"TableS2_taxonomy_table.csv")) %>% janitor::clean_names() %>%
  dplyr::select(-x)

################################################################################
#calculate transect means to reduce memory 

#drop species that were never encountered
swath_build1 <- swath_raw %>% dplyr::select(where(~ any(. != 0)))
upc_build1 <- upc_raw %>% dplyr::select(where(~ any(. != 0)))
fish_build1 <- fish_raw %>% dplyr::select(where(~ any(. != 0)))


################################################################################
#swath mvabund

swath_mod_dat <- swath_build1 %>% 
  mutate(outbreak_period = ifelse(year <2014, "Before","After")) %>%
  dplyr::select(outbreak_period, everything()) %>%
  dplyr::group_by(year, outbreak_period, MHW, baseline_region, latitude, longitude, site,
                  affiliated_mpa, mpa_class, mpa_designation) %>%
  dplyr::summarize(across(3:59, mean, na.rm = TRUE)) %>%
  #define transition sites
  mutate(transition_site = ifelse(site == "HOPKINS_UC" | site == "CANNERY_UC" |
                                    site == "SIREN" | site == "CANNERY_DC","no","yes"))%>%
  dplyr::select(transition_site, everything())

swath_transition <- swath_mod_dat %>% filter(transition_site == "yes")
swath_persist <- swath_mod_dat %>% filter(transition_site == "no")

#####run model for transition sites
#create multivariate object
swath_t_spp <- mvabund(swath_transition[, 12:68]) #exclude grouping vars
#fit the model
swath_t_model <- manyglm(swath_t_spp ~ swath_transition$outbreak_period)
#test for significance
swath_t_result <- anova.manyglm(swath_t_model, p.uni = "adjusted")
swath_t_out <- as.data.frame(swath_t_result[["uni.p"]])
#examine output
swath_t_sig <- swath_t_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="swath",
         transition_site = "yes")


#####run model for persist sites
#create multivariate object
swath_p_spp <- mvabund(swath_persist[, 12:68]) #exclude grouping vars
#fit the model
swath_p_model <- manyglm(swath_p_spp ~ swath_persist$outbreak_period)
#test for significance
swath_p_result <- anova.manyglm(swath_p_model, p.uni = "adjusted")
swath_p_out <- as.data.frame(swath_p_result[["uni.p"]])
#examine output
swath_p_sig <- swath_p_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="swath",
         transition_site = "no")

#merge

swath_mvabund <- rbind(swath_t_sig, swath_p_sig) 


################################################################################
#upc mvabund


upc_mod_dat <- upc_build1 %>% 
  mutate(outbreak_period = ifelse(year <2014, "Before","After")) %>%
  dplyr::select(outbreak_period, everything()) %>%
  dplyr::group_by(year, outbreak_period, MHW, baseline_region, latitude, longitude, site,
                  affiliated_mpa, mpa_class, mpa_designation) %>%
  dplyr::summarize(across(3:41, mean, na.rm = TRUE)) %>%
  #define transition sites
  mutate(transition_site = ifelse(site == "HOPKINS_UC" | site == "CANNERY_UC" |
                                    site == "SIREN" | site == "CANNERY_DC","no","yes"))%>%
  dplyr::select(transition_site, everything())

upc_transition <- upc_mod_dat %>% filter(transition_site == "yes")
upc_persist <- upc_mod_dat %>% filter(transition_site == "no")

#####run model for transition sites
#create multivariate object
upc_t_spp <- mvabund(upc_transition[, 12:50]) #exclude grouping vars
#fit the model
upc_t_model <- manyglm(upc_t_spp ~ upc_transition$outbreak_period)
#test for significance
upc_t_result <- anova.manyglm(upc_t_model, p.uni = "adjusted")
upc_t_out <- as.data.frame(upc_t_result[["uni.p"]])
#examine output
upc_t_sig <- upc_t_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="upc",
         transition_site = "yes")


#####run model for persist sites
#create multivariate object
upc_p_spp <- mvabund(upc_persist[, 12:50]) #exclude grouping vars
#fit the model
upc_p_model <- manyglm(upc_p_spp ~ upc_persist$outbreak_period)
#test for significance
upc_p_result <- anova.manyglm(upc_p_model, p.uni = "adjusted")
upc_p_out <- as.data.frame(upc_p_result[["uni.p"]])
#examine output
upc_p_sig <- upc_p_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="upc",
         transition_site = "no")


#merge

upc_mvabund <- rbind(upc_t_sig, upc_p_sig)


################################################################################
#fish mvabund


fish_mod_dat <- fish_build1 %>% 
  mutate(outbreak_period = ifelse(year < 2014, "Before","After")) %>%
  dplyr::select(outbreak_period, everything()) %>%
  dplyr::group_by(year, outbreak_period, MHW, baseline_region, latitude, longitude, site,
                  affiliated_mpa, mpa_class, mpa_designation) %>%
  dplyr::summarize(across(4:55, mean, na.rm = TRUE)) %>%
  #define transition sites
  mutate(transition_site = ifelse(site == "HOPKINS_UC" | site == "CANNERY_UC" |
                                    site == "SIREN" | site == "CANNERY_DC","no","yes"))%>%
  dplyr::select(transition_site, everything())

fish_transition <- fish_mod_dat %>% filter(transition_site == "yes")
fish_persist <- fish_mod_dat %>% filter(transition_site == "no")

#####run model for transition sites
#create multivariate object
fish_t_spp <- mvabund(fish_transition[, 12:63]) #exclude grouping vars
#fit the model
fish_t_model <- manyglm(fish_t_spp ~ fish_transition$outbreak_period)
#test for significance
fish_t_result <- anova.manyglm(fish_t_model, p.uni = "adjusted")
fish_t_out <- as.data.frame(fish_t_result[["uni.p"]])
#examine output
fish_t_sig <- fish_t_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="fish",
         transition_site = "yes")


#####run model for persist sites
#create multivariate object
fish_p_spp <- mvabund(fish_persist[, 12:63]) #exclude grouping vars
#fit the model
fish_p_model <- manyglm(fish_p_spp ~ fish_persist$outbreak_period)
#test for significance
fish_p_result <- anova.manyglm(fish_p_model, p.uni = "adjusted")
fish_p_out <- as.data.frame(fish_p_result[["uni.p"]])
#examine output
fish_p_sig <- fish_p_out %>%
  pivot_longer(cols=1:ncol(.), names_to="species")%>%
  drop_na()%>%
  filter(value <= 0.05) %>%
  mutate(group="fish",
         transition_site = "no")


#merge

fish_mvabund <- rbind(fish_t_sig, fish_p_sig)



################################################################################
#filter data based on significant results

swath_filtered <- swath_mod_dat %>%
                    pivot_longer(12:68, names_to = "species", values_to = "counts")%>%
                  #dplyr::select(!(transition_site))%>%
                  #filter to significant species
                  left_join(swath_mvabund, by=c("transition_site","species"), relationship = "many-to-many")%>%
                  filter(!(is.na(group)))

upc_filtered <- upc_mod_dat %>%
  pivot_longer(12:50, names_to = "species", values_to = "counts")%>%
  #dplyr::select(!(transition_site))%>%
  #filter to significant species
  left_join(upc_mvabund, by=c("transition_site","species"), relationship = "many-to-many")%>%
  filter(!(is.na(group)))

fish_filtered <- fish_mod_dat %>%
  pivot_longer(12:63, names_to = "species", values_to = "counts")%>%
  #dplyr::select(!(transition_site))%>%
  #filter to significant species
  left_join(fish_mvabund, by=c("transition_site","species"), relationship = "many-to-many")%>%
  filter(!(is.na(group)))



################################################################################
#plot using dumbbell approach

means_before <- swath_filtered %>%
  filter(outbreak_period == "Before") %>%
  group_by(species, transition_site) %>%
  summarize(mean_counts_before = mean(counts, na.rm = TRUE))

# Calculate the mean counts for "After" outbreak
means_after <- swath_filtered %>%
  filter(outbreak_period == "After") %>%
  group_by(species, transition_site) %>%
  summarize(mean_counts_after = mean(counts, na.rm = TRUE))

# Merge the mean counts for "Before" and "After"
means <- merge(means_before, means_after, by = c("species", "transition_site"))


################################################################################
#prep data for plotting

# Calculate percent change for each species within each transition site
swath_pc <- swath_filtered %>%
  group_by(transition_site, outbreak_period, species)%>%
  dplyr::summarize(mean_counts = mean(counts, na.rm=TRUE)+0.0001)%>% #ddd a small constant to avoid -Inf
  pivot_wider(names_from = outbreak_period,
              values_from = mean_counts) %>%
  mutate(perc_change = ((After - Before)/Before * 100))

# Calculate the average perc_change for each species
avg_perc_change <- swath_pc %>%
  group_by(species) %>%
  summarize(avg_change = mean(perc_change, na.rm = TRUE)) %>%
  arrange(desc(avg_change))

# Reorder the levels of the species factor based on avg_perc_change
swath_pc$species <- factor(swath_pc$species, levels = avg_perc_change$species)



# Calculate percent change for each species within each transition site
upc_pc <- upc_filtered %>%
  group_by(transition_site, outbreak_period, species)%>%
  dplyr::summarize(mean_counts = mean(counts, na.rm=TRUE))%>%
  pivot_wider(names_from = outbreak_period,
              values_from = mean_counts) %>%
  mutate(perc_change = ((After - Before)/Before * 100))

# Calculate the average perc_change for each species
avg_perc_change <- upc_pc %>%
  group_by(species) %>%
  summarize(avg_change = mean(perc_change, na.rm = TRUE)) %>%
  arrange(desc(avg_change))

# Reorder the levels of the species factor based on avg_perc_change
upc_pc$species <- factor(upc_pc$species, levels = avg_perc_change$species)




# Calculate percent change for each species within each transition site
fish_pc <- fish_filtered %>%
  group_by(transition_site, outbreak_period, species)%>%
  dplyr::summarize(mean_counts = mean(counts, na.rm=TRUE))%>%
  pivot_wider(names_from = outbreak_period,
              values_from = mean_counts) %>%
  mutate(perc_change = ((After - Before)/Before * 100))

# Calculate the average perc_change for each species
avg_perc_change <- fish_pc %>%
  group_by(species) %>%
  summarize(avg_change = mean(perc_change, na.rm = TRUE)) %>%
  arrange(desc(avg_change))

# Reorder the levels of the species factor based on avg_perc_change
fish_pc$species <- factor(fish_pc$species, levels = avg_perc_change$species)



plot_merge <- rbind(swath_pc, fish_pc, upc_pc) %>%
  mutate(species = str_to_sentence(gsub("_", " ", species)))%>%
  #join with species attributes
  left_join(spp_attribute, by=c("species" = "taxa")) %>%
  #drop sea stars
  filter(!(species == "Pycnopodia helianthoides" | species == "Orthasterias koehleri" |
             species == "Pisaster giganteus" | species == "Patiria miniata" | species == "Cirripedia" |
             species == "Mediaster aequalis")) %>%
  #rename common names
  mutate(common_name = str_to_sentence(common_name),
         trophic_ecology = str_to_sentence(trophic_ecology),
         common_name = case_when(
           common_name == "Red algae (leaflike)" ~ "Red algae (leaf-like)",
           common_name == "Tube snail, scaled worm shell" ~ "Tube snail",
           common_name == "Purple urchin" ~ "Purple sea urchin",
           common_name == "Decorator crab, moss crab" ~ "Decorator or moss crab",
           common_name == "Red algae (leaflike)" ~ "Red algae (leaf-like)",
           common_name == "Tunicate colonial,compund,social" ~ "Tunicate (colony-forming)",
           TRUE ~ common_name
         ),
         species = case_when(
           species == "Tunicate colonial compund social" ~ "Tunicate (colony-forming)",
           TRUE ~ species
         )
        ) %>%
  mutate(trophic_ecology = ifelse(trophic_ecology == "Autotroph","Primary producer",trophic_ecology))%>%
  #set order
  mutate(trophic_ecology = factor(trophic_ecology, levels = c(
    "Planktivore","Detritivore (algal)","Primary producer","Herbivore",
    "Microinvertivore","Macroinvertivore","Piscivore"
  )))


################################################################################
#Plot

my_theme <-  theme(axis.text=element_text(size=9, color = "black"),
                   axis.text.y = element_text(angle = 90, hjust = 0.5, color = "black"),
                   axis.title=element_text(size=9, color = "black"),
                   plot.tag=element_text(size=9, face="plain", color = "black"),
                   plot.title =element_text(size=10, face="bold", color = "black"),
                   # Gridlines 
                   panel.grid.major = element_blank(), 
                   panel.grid.minor = element_blank(),
                   panel.background = element_blank(), 
                   axis.line = element_line(colour = "black"),
                   # Legend
                   legend.key = element_blank(),
                   legend.background = element_rect(fill=alpha('blue', 0)),
                   legend.key.height = unit(1, "lines"), 
                   legend.text = element_text(size = 9, color = "black"),
                   legend.title = element_text(size = 9, color = "black"),
                   #legend.spacing.y = unit(0.75, "cm"),
                   #facets
                   strip.background = element_blank(),
                   strip.text = element_text(size = 10 ,face="bold", color = "black", hjust=0),
)

exhibits <- list(
  mba3 = rbind(c('#1B9E77','#6BA4AF', '#E5C200', '#7570b3','#6C2D1C', '#EE69AD','#E7A070','#E7298A'),c(1,2,3,4,5,6,7,8)))

mba_colors <- function(exhibit, n_colors, type = c("discrete", "continuous"), rev = FALSE) {
  
  # Retrieve the palette based on the provided name
  custom_pal <- exhibits[[exhibit]]
  
  # Check if the palette exists
  if (is.null(custom_pal)){
    stop("Palette not found.")
  }
  
  # Check if we need to reverse the palette
  if (rev) {
    custom_pal[1,] <- rev(custom_pal[1,])
  }
  
  # If n_colors is not provided, set it to the length of the palette
  if (missing(n_colors)) {
    n_colors <- length(custom_pal[1,])
  }
  
  # If type is not provided, determine it based on the number of colors
  if (missing(type)) {
    if (n_colors > length(custom_pal[1,])) {
      type <- "continuous"
    } else {
      type <- "discrete"
    }
  }
  type <- match.arg(type)
  
  # Check if the requested number of colors is valid for a discrete palette
  if (type == "discrete" && n_colors > length(custom_pal[1,])) {
    stop("Number of requested colors greater than what the discrete palette can offer. Use as continuous instead.")
  }
  
  # Generate the color palette based on the type
  palette_colors <- switch(type,
                           continuous = grDevices::colorRampPalette(custom_pal[1,])(n_colors),
                           discrete = custom_pal[1,][custom_pal[2,] %in% c(1:n_colors)]
  )
  
  # Return the palette with its class and name attributes
  structure(palette_colors, class = "MBAPalette", name = exhibit)
}




col_pal <- setNames(mba_colors("mba3"), levels(factor(plot_merge$trophic_ecology)))

resist_dat <- plot_merge %>% filter(transition_site == "no")
resist_dat$label <- with(resist_dat, ifelse(method == "UPC", paste0("(", round(Before, 2), ", ", round(After, 2), ") *"), paste0("(", round(Before, 2), ", ", round(After, 2), ") \u2020")))

# Calculate the number of unique species where perc_change < 0 and perc_change > 0
n_negative <- sum(resist_dat$perc_change < 0)
n_positive <- sum(resist_dat$perc_change > 0)

p1 <- ggplot(resist_dat,
             aes(x = perc_change, y = reorder(species, -perc_change))) +
  geom_point(aes(color = trophic_ecology)) +
  geom_segment(aes(x = 0, xend = perc_change, yend = species, color = trophic_ecology), linetype = "solid", size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  # add genus species labels
  geom_text(
    aes(x = ifelse(resist_dat$perc_change >= 0, 0.1, -0.1), label = species, fontface = "italic"),
    hjust = ifelse(resist_dat$perc_change >= 0, 0, 1),
    color = "black",
    size = 2,
    position = position_nudge(y = -0.1),
    data = resist_dat
  ) +
  # add common name labels
  geom_text(
    aes(x = ifelse(resist_dat$perc_change >= 0, 0.1, -0.1), label = common_name),
    hjust = ifelse(resist_dat$perc_change >= 0, 0, 1),
    color = "black",
    size = 3,
    position = position_nudge(y = 0.1),
    data = resist_dat
  ) +
  # add pre-post densities
  geom_text(
    aes(
      x = ifelse(resist_dat$perc_change >= 0, -8, 8),
      label = label
    ),
    color = "black",
    size = 3,
    data = resist_dat
  ) +
  scale_x_continuous(
    trans = ggallin::pseudolog10_trans,
    breaks = c(-20000, -10000, -1000, -100, -10, -1, 1, 10, 100, 1000, 10000),
    labels = c(-20000, -10000, -1000, -100, -10, -1, 1, 10, 100, 1000, 10000)
  ) +
  scale_color_manual(values = col_pal) +
  #scale_color_manual(values = mba3_palette) +
  xlab("") +
  ylab("") +
  labs(tag = "A", color = "Trophic function") +
  ggtitle("Persistent") +
  theme_bw() +
  my_theme +
  guides(color = "none")+
  theme(axis.text.y = element_blank())+
  #add text for the number of taxa
  annotate("text", x = -Inf, y = Inf, label = paste("n =", n_negative), vjust = 1.2, hjust = -0.1, 
           color = "black", size = 3) +
  annotate("text", x = Inf, y = Inf, label = paste("n =", n_positive), vjust = 1.2, hjust = 1.1, 
           color = "black", size = 3)

p1


transition_dat <- plot_merge %>% filter(transition_site == "yes") %>% filter(!(species == "Leptasterias hexactis" | species == "Cirripidia")) %>%
                    #drop UPC macro
                   filter(!(method == "UPC" & species == "Macrocystis pyrifera")) %>%
                  filter(!(method == "Swath" & species == "Macrocystis pyrifera" & Before < 2)) 

# Create a new column for formatted labels
transition_dat$label <- with(transition_dat, ifelse(method == "UPC", paste0("(", round(Before, 2), ", ", round(After, 2), ") *"), paste0("(", round(Before, 2), ", ", round(After, 2), ") \u2020" )))


# Calculate the number of unique species where perc_change < 0 and perc_change > 0
n_negative <- sum(transition_dat$perc_change < 0)
n_positive <- sum(transition_dat$perc_change > 0)

p2 <- ggplot(transition_dat,
             aes(x = perc_change, y = reorder(species, -perc_change))) +
  geom_point(aes(color = trophic_ecology)) +
  geom_segment(aes(x = 0, xend = perc_change, yend = species, color = trophic_ecology), linetype = "solid", size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  # add genus species labels
  geom_text(
    aes(x = ifelse(transition_dat$perc_change >= 0, 0.1, -0.1), label = species, fontface = "italic"),
    hjust = ifelse(transition_dat$perc_change >= 0, 0, 1),
    color = "black",
    size = 2,
    position = position_nudge(y = -0.2)
  ) +
  # add common name labels
  geom_text(
    aes(x = ifelse(transition_dat$perc_change >= 0, 0.1, -0.1), label = common_name),
    hjust = ifelse(transition_dat$perc_change >= 0, 0, 1),
    color = "black",
    size = 3,
    position = position_nudge(y = 0.3)
  ) +
  # add pre-post densities
  geom_text(
    aes(
      x = ifelse(transition_dat$perc_change >= 0, -10, 10),
      label = label
    ),
    color = "black",
    size = 3
  ) +
  scale_x_continuous(
    trans = ggallin::pseudolog10_trans,
    breaks = c(-10000, -1000, -100, -10, -1, 1, 10, 100, 1000, 10000),
    labels = c(-10000, -1000, -100, -10, -1, 1, 10, 100, 1000, 10000),
    limits = c(-10000, 20000)
  ) +
  scale_color_manual(values = col_pal) +
  xlab("") +
  ylab("") +
  labs(tag = "B", color = "Trophic function") +
  ggtitle("Transitioned") +
  theme_bw() +
  my_theme +
  theme(axis.text.y = element_blank())+
  #add text for the number of taxa
  annotate("text", x = -Inf, y = Inf, label = paste("n =", n_negative), vjust = 1.2, hjust = -0.1, 
           color = "black", size = 3) +
  annotate("text", x = Inf, y = Inf, label = paste("n =", n_positive), vjust = 1.2, hjust = 1.1, 
           color = "black", size = 3)

p2



combined_plot <- ggpubr::ggarrange(p1, p2, common.legend = TRUE, align = "h") 

combined_plot_annotated <- ggpubr::annotate_figure(combined_plot,
                bottom = ggpubr::text_grob("Percent change", 
                                   hjust = 3.9, x = 1, size = 12, vjust=-1),
                left = ggpubr::text_grob("", rot = 90, size = 10, vjust=2)
)

combined_plot

ggsave(combined_plot_annotated, filename=file.path(figdir, "Fig4_mvabund.png"), bg = "white",
       width=8.5, height=10.5, units="in", dpi=600) 






