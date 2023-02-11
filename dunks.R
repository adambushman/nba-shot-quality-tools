library('tidyverse')
library('hoopR')

pbp <- hoopR::load_nba_pbp()
boxes <- hoopR::load_nba_player_box()

top_dunks <-
  pbp |>
  filter(stringr::str_detect(
    stringr::str_to_lower(type_text), "dunk")) |>
  filter(scoring_play == TRUE) |>
  group_by(participants_0_athlete_id) |>
  summarise(
    count = n(), 
    .groups = 'drop'
  )

top_dunks |>
  inner_join(
    boxes, 
    by = c(
      "participants_0_athlete_id" = "athlete_id", 
      "game_id" = "game_id"
    )
  ) |>
  select(game_date, athlete_display_name)


camcorder::gg_record(
  dir = "C:/Users/Adam Bushman/Pictures/_test",
  device = "png",
  width = 16,
  height = 9,
  dpi = 300,
  units = "cm"
)


dunks_3s <- 
  boxes |>
  separate(col = fg3, into = c("fgm", "fga"), sep = "-") |>
  group_by(
    athlete_display_name, 
    athlete_id, 
    athlete_headshot_href
  ) |>
  summarise(
    total_3 = sum(as.numeric(fgm)), 
    .groups = "drop"
  ) |>
  inner_join(
    top_dunks, 
    by = c("athlete_id" = "participants_0_athlete_id")
  ) |>
  mutate(
    rank_3 = dense_rank(desc(total_3)), 
    rank_d = dense_rank(desc(count)), 
    my_label = case_when(
      rank_3 <= 10 | rank_d <= 10 ~ athlete_display_name, 
      rank_3 <= 200 & rank_d <= 20 ~ athlete_display_name,
      TRUE ~ ""
    ), 
    my_col = ifelse(my_label == "", "darkgray", "red3")
  )

dunks_3s |>
  filter(total_3 > 0 & count > 0) |>
  
  ggplot(
    aes(x = total_3, y = count, color = my_col, label = my_label)
  ) +
  geom_point() +
  ggrepel::geom_text_repel(
    size = 2
  ) +
  scale_color_identity() +
  annotate(
    "text", x = 112, y = 90, color = "blue3", size = 2.5, 
    hjust = 1, label = "The Real NBA Unicorn?"
  ) +
  annotate(
    "segment", xend = 117, yend = 77, x = 113, y = 88, color = "blue3", 
    arrow = arrow(length = unit(0.1,"cm"), type = "closed")
  ) +
  labs(
    title = "DUNKS & THREES", 
    subtitle = "Which players attack with force at the rim, finesse from deep, or both", 
    x = "Total Made Threes", 
    y = "Total Made Dunks"
  ) +
  theme_minimal() +
  theme(
    plot.background = element_rect(
      fill = 'white', 
      color = NA
    ), 
    plot.title = element_text(
      face = 'bold', 
      size = 18, 
      color = 'red3'
    ), 
    plot.subtitle = element_text(
      face = 'italic', 
      size = 11, 
      color = 'darkgray'
    )
  )


top_10_sort <- 
  dunks_3s |>
  filter(total_3 > 0 & count > 0) |>
  mutate(
    total_3_log = log(total_3), 
    count_d_log = log(count)
  ) |>
  dplyr::mutate_at(
    .vars = c("total_3_log", "count_d_log"), 
    .funs = scale
  ) |>
  mutate(combo_z = (total_3_log + count_d_log) / 2) |>
  arrange(desc(combo_z)) |>
  select(
    athlete_headshot_href, 
    athlete_display_name, 
    total_3, 
    count
  ) |>
  head(10)


gt(top_10_sort) |>
  tab_header(
    title = md("**DUNKS & THREES**"), 
    subtitle = md(
      "Top 10 players who attack with force at the rim and finesse from deep  
      Sorted by the logged, normalized combination of total dunks & threes"
    )
  ) |>
  cols_label(
    athlete_headshot_href = "", 
    athlete_display_name = "Player Name", 
    total_3 = "Total Threes", 
    count = "Total Dunks"
  ) |>
  cols_width(
    athlete_headshot_href ~ px(80), 
    athlete_display_name ~ px(200), 
    total_3 ~ px(100), 
    count ~ px(100)
  ) |>
  gt_img_rows(
    columns = athlete_headshot_href, 
    height = 40
  ) |>
  tab_source_note(
    "Data Souce: NBA.com accessed via {hoopR} package"
  ) |>
  tab_options(
    heading.subtitle.font.size = 12, 
    column_labels.background.color = "darkgray", 
    heading.background.color = "red3", 
    source_notes.background.color = "darkgray", 
    data_row.padding = 2
  ) |>
  gtsave(
    filename = "dunks-and-threes.png", 
    path = "C:/Users/Adam Bushman/Pictures"
  )
