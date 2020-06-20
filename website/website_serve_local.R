# Helper script for working on website.
#
# Builds and serves a copy of the website for local development and previewing.
# 
# "blogdown::serve_site()" will serve the website on a local webserver and
# continuously rebuild if changes are made; only needs to be run once while
# working on site.

blogdown::stop_server()
current_dir = getwd()

if(grepl("website", current_dir, fixed = TRUE) != TRUE) {
  setwd("./website")
}

blogdown::serve_site()
