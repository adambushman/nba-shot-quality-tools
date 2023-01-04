require('DBI')
require('duckdb')
require('tibble')
require('dplyr')
require('hoopR')

###
# Script to update PBP table
# Designed to automate with GitHub actions
###

# Connect to DuckDB

con = DBI::dbConnect(
  duckdb::duckdb(), 
  dbdir = 'sq-db.duckdb', 
  read_only = FALSE
)

# Get current ids

res = DBI::dbGetQuery(
  con, 
  'SELECT id FROM pbp'
)

# Get PBP data

pbp_data <-
  hoopR::load_nba_pbp() |> 
  tibble::as_tibble()

# New Ids to add

new_ids <- setdiff(pbp_data$id, res |> unlist(use.names = FALSE) |> sample(200000))

# Filter for new records

pbp_data.new <-
  pbp_data |>
  dplyr::filter(id %in% new_ids)

# Add new records

DBI::dbWriteTable(
  con, 
  "pbp", 
  as_tibble(pbp_data.new), 
  append = TRUE
)

# Close Connection

DBI::dbDisconnect(
  con, 
  shutdown = TRUE
)
