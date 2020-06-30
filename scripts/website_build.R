# Helper script for working on website.
#
# Build a new copy of the website; does not provide local previewing.

library(here)

setwd(here("website"))
blogdown::build_site(local = TRUE) # "local = TRUE" needed for relative paths
