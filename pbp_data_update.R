require('DBI')
require('duckdb')
require('tibble')
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

# Get PBP Data

pbp_data <-
  hoopR::load_nba_pbp() |> 
  tibble::as_tibble()

DBI::dbWriteTable(
  con, 
  "pbp", 
  as_tibble(pbp_data), 
  overwrite = TRUE
)

# Close Connection

DBI::dbDisconnect(
  con, 
  shutdown = TRUE
)
