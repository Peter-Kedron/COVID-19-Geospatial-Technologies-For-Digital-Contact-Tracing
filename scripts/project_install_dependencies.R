# Installs all dependencies needed for the project.

# Website
install.packages("blogdown")
blogdown::install_hugo()

# For easy paths
install.packages("here")

# Interactive map
install.packages("plotly")
install.packages("ggplot2")

# For mobile application review scraping
install.packages("RSelenium")
