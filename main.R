library('tidyverse')
library('hoopR')

# What's missing
  # Gotta fix the "possession" stuff
  # Use DuckDB somehow
  # Turn into a Shiny App somehow
  # Design visualizations and tables




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
# All Games
###

games <- 
  hoopR::load_nba_schedule() |>
  select(date, game_id, home_id, home_name, away_id, away_name, status_type_name)

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

###
# Individual Game
###

my_game <- 
  games |> 
  filter(home_name == 'Jazz' | away_name == 'Jazz') |> 
  filter(status_type_name == 'STATUS_FINAL') |>
  select(game_id) |>
  head(1) |>
  unlist(use.names = FALSE)

game_res <- 
  scoring_pbp %>%
  filter(
    game_id == my_game &
      shooting_play == TRUE
  ) %>%
  group_by(team_id, participants_0_athlete_id, g_type_text) |>
  summarise(
    g_total_points = sum(score_value), 
    # HERE: GOTTA FIX THE # OF POSS
    g_total_possessions = n_distinct(g_type_text), 
    .groups = 'drop'
  ) |> 
  mutate(
    g_ppp = g_total_points / g_total_possessions
  ) |> 
  rename(athlete_id = participants_0_athlete_id) |>
  left_join( 
    player_averages, 
    by = c(
      'athlete_id' = 'athlete_id', 
      'g_type_text' = 'g_type_text'
    )
  ) |>
  inner_join(
    nba_teams, 
    by = c('team_id' = 'espn_team_id')
  )


# Game Overall Comparison
game_res |>
  mutate(
    alt_total_points = round(g_total_possessions * a_ppp, 0)
  ) |>
  group_by(TeamName) |>
  summarise(
    score = sum(g_total_points), 
    game_poss = sum(g_total_possessions), 
    game_ppp = round(sum(g_total_points) / sum(g_total_possessions), 3), 
    avg_ppp = round(sum(alt_total_points) / sum(g_total_possessions), 3)
  )

# Game Play Comparison
game_res |>
  group_by(TeamName, type_text) |>
  summarise(
    game_ppp = round(sum(g_total_points) / sum(g_total_possessions), 3), 
    avg_ppp = round(sum(a_total_points) / sum(a_total_possessions), 3), 
    .groups = 'drop'
  ) |> 
  mutate(
    diff_ppp = game_ppp - avg_ppp
  ) |>
  arrange(desc(diff_ppp))
