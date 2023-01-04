library('tidyverse')
library('hoopR')

# Functions to get specific player

df <- 
  hoopR::nba_playerindex(season = '2022-23') |>
  .$PlayerIndex


names(df$PlayerIndex)

get_player_id <- function(name) {
  all_names = stringr::str_split(name, ' ')[[1]]
  
  df |>
    mutate(
      f_name_match = PLAYER_FIRST_NAME %in% all_names, 
      l_name_match = PLAYER_LAST_NAME %in% all_names, 
      both_match = f_name_match == l_name_match
    ) |>
    filter(
      f_name_match | l_name_match
    ) |>
    arrange(desc(both_match)) |>
    select(PERSON_ID, PLAYER_LAST_NAME, PLAYER_FIRST_NAME)
}




