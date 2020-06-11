library(dplyr)
library(PRISMAstatement)


df <-
  read.csv("data/results/LSRallincludedstudies7thJuneFINAL.csv",
           stringsAsFactors = FALSE)

# Get number pre-deduplication
df_total <- nrow(df)+253

# Add missing exclusion reasons as provided by DG via email
df2 <- rio::import("data/early_exclusion_reasons.xlsx") %>%
  filter(expert_decision == "Exclude") %>%
  select(ID, exclusion_reason)

# Merge with main dataset by ID and fix weird comments
df <- merge(df, df2, by = "ID", all.x = TRUE) %>%
  mutate(exclusion_reason.x = ifelse(
    !is.na(exclusion_reason.y),
    exclusion_reason.y,
    exclusion_reason.x
  )) %>%
  dplyr::select(-exclusion_reason.y) %>%
  mutate(exclusion_reason.x = ifelse(
    exclusion_reason.x %in% c(
      "PLEASE INCLUDE",
      "PLEASE INCLUDE - 2 CASE REPORTS SO FULFILS OUR INCLUSION CRITEREA",
      "Case series <5 cases"
    ),
    "",
    exclusion_reason.x
  ))

# Fix small error where intial and expert decision don't both equal "Include
df$initial_decision[which(df$ID == "383")] <- "Include"

colnames(df)[27] <- "exclusion_reason"
df$q13 <- stringr::str_to_upper(df$q13)

# Create non-deduplicated copy
df1 <- df

# Replace mispelled exclusion
df$expert_decision <- gsub("Exclue","Exclude",df$expert_decision)

# Correct missing exclusion reason
df$exclusion_reason[which(df$ID == "383")] <- "No original data presented"

# Remove duplicates, as specificed by DG/AJ in email correspondence
df <- df %>%
  filter(!ID %in% c("20",
                    "248",
                    "315",
                    "382","483","689",
                    "489",
                    "500","629",
                    "554", "625",
                    "563","630",
                    "399",
                    "369",
                    "723",
                    "1379",
                    "637"
                    ))

View(df %>% filter(expert_decision == "Exclude" & exclusion_reason == ""))
View(df %>% filter(ID == "1198"))


prsm <- prisma(found = df_total,
       found_other = 0,
       no_dupes = nrow(df),
       screened = nrow(df),
       screen_exclusions = length(df$title[which(df$expert_decision == "")]), 
       full_text = length(df$title[which(df$expert_decision != "")]),
       full_text_exclusions = 130,
       qualitative = length(df$title[which(df$expert_decision == "Include")]), 
       quantitative = 0,
       font_size = 8,
       dpi = 72,
       labels = list(quantitative = "No quantitative synthesis was performed.",
                     full_text_exclusions = paste0("Full-text articles excluded\n (n=",
                                                   length(df$title[which(df$expert_decision == "Exclude" )]),
                                                   ")", 
                                                   "\nSuicide / self-harm not addressed: ",
                                                   length(df$title[which(df$expert_decision == "Exclude" & df$exclusion_reason == "Suicide / self-harm not addressed")]),
                                                   "\nSingle case report: ",
                                                   length(df$title[which(df$expert_decision == "Exclude" & df$exclusion_reason == "Single case report")]),
                                                   "\nNo original data presented: ",
                                                   length(df$title[which(df$expert_decision == "Exclude" & df$exclusion_reason == "No original data presented")]),
                                                   "\nOther: ",
                                                   length(df$title[which(df$expert_decision == "Exclude" & df$exclusion_reason == "Other")])))
)

PRISMAstatement:::prisma_pdf(prsm,"prisma.pdf")
