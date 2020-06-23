# Helper script for working on website.
#
# Build a new copy of the website; does not provide local previewing.

current_dir = getwd()

if(grepl("website", current_dir, fixed = TRUE) != TRUE) {
  setwd("./website")
}

blogdown::build_site(local = TRUE) # "local = TRUE" needed for relative paths
