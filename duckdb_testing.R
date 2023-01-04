require('DBI')

# Create DuckDB database

con = DBI::dbConnect(
  duckdb::duckdb(), 
  dbdir = 'sq-db.duckdb', 
  read_only = FALSE
)

# Create tables
 
DBI::dbWriteTable(con, "teams", hoopR::nba_teams) # Teams

DBI::dbWriteTable(con, "players", hoopR::nba_playerindex(season = '2022-23') |> dplyr::as_tibble()) # Teams


#

res = DBI::dbGetQuery(
  con, 
  'DROP TABLE test'
)

DBI::dbExecute(
  con, 
  'DROP TABLE IF EXISTS test'
)

res

test_tib <-
  tibble(
    letters = c('E', 'F', "G", "H"), 
    numbers = 5:8
  )

DBI::dbWriteTable(
  con, 
  "test", 
  test_tib, 
  append = TRUE
) # Test


