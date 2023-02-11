library('tidyverse')
library('hoopR')

###
# All Play By Play
###

df_pbp <-
  hoopR::load_nba_pbp() |> 
  mutate(team_id = as.numeric(team_id))


###
# Scoring Play By Play
###

scoring_pbp <-
  df_pbp %>%
  filter(
    shooting_play == TRUE &
      !((stringr::str_detect(type_text, "No Shot") |
           (stringr::str_detect(type_text, "Free Throw") &
              (stringr::str_detect(type_text, "Technical") |
                 stringr::str_detect(type_text, "Flagrant") |
                 stringr::str_detect(type_text, "Clear Path")))))
  ) %>%
  arrange(game_id, game_play_number) %>%
  mutate(sequence = row_number()) %>%
  mutate(
    g_type_text = case_when(
      stringr::str_detect(type_text, "Free Throw") ~ as.character(NA), 
      TRUE ~ type_text
    )
  ) %>%
  tidyr::fill(g_type_text, .direction = "down")


###
# League Average Quality
###

league_averages <- 
  scoring_pbp %>%
  group_by(g_type_text) %>%
  summarise(
    total_points = sum(score_value), 
    total_possessions = n()
  ) |> 
  mutate(
    ppp = total_points / total_possessions
  )

###
# All Player Averages
###

player_averages <- 
  scoring_pbp %>%
  group_by(participants_0_athlete_id, g_type_text) |> 
  summarise(
    a_total_points = sum(score_value), 
    a_total_possessions = n(), 
    .groups = 'drop'
  ) |> 
  mutate(
    a_ppp = a_total_points / a_total_possessions
  ) |> 
  rename(athlete_id = participants_0_athlete_id)



