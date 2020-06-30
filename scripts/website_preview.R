# Helper script for working on website.
#
# Builds and serves a copy of the website for local development and previewing.
# 
# "blogdown::serve_site()" will serve the website on a local webserver and
# continuously rebuild if changes are made; only needs to be run once while
# working on site.

library(here)

blogdown::stop_server()
setwd(here("website"))
blogdown::serve_site()
