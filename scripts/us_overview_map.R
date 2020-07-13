# Interactive map that provides an overview of current state status

library(ggplot2)
library(plotly)
library(here)

# Read the state status data
state_data <- read.csv(here("data", "State DCT Apps - Website Data.csv"))

# Read the status data for Teton County, WY
wy_teton <- jsonlite::fromJSON(here("data", "wy_teton.json"))

# Generate the hover text for all states
state_data$map_hover_text <- with(state_data, paste("<b>", State, "</b>", "<br>", "App Planned:", App.Planned, "<br>", "App Name:", App.Name, "<br>", "Technology:", Technology))

# Generate the hover text for Teton County, WY; it should be at the 51 index
teton_county_hover <- state_data$map_hover_text[51]

# Generate the new App.Planned.Num column dummy column to shade the choropleth map
state_data$App.Planned.Num <- ifelse(state_data$App.Planned == "Yes" | state_data$App.Planned == "Statewide App" | state_data$App.Planned == "Countywide App", 1, 0)

# Set map settings
map_settings <- list(scope = 'usa', projection = list(type = 'albers usa'), showlakes = FALSE)

# Use this color scale for the map
color_scale <- data.frame(z = c(0, 0.5, 0.5, 1), col = c("#f8f8f8", "#f8f8f8", "#800000", "#800000"))

# Create the map, add one trace for the states and another for Teton County, WY, set the colorbar, and set the title.
map <- plot_geo(state_data, name = "\n", colorscale = color_scale, width = 1000, height = 600)
map <- map %>% add_trace(locationmode = "USA-states", z = ~App.Planned.Num, locations = ~Abrv, hovertemplate = ~map_hover_text, color = ~App.Planned.Num, colors = c("#f8f8f8","#800000"), showscale = TRUE)
map <- map %>% add_trace(name = "\n\n", geojson = wy_teton, z = ~App.Planned.Num[51], locations = "56039", hovertemplate = teton_county_hover, colors = c("#f8f8f8","#800000"), showscale = FALSE)
map <- map %>% colorbar(title = list(text = "DCT App Planned", font = list(size = 15)), tickmode = "array", tickvals = list(0.75, 0.25), ticktext = list("Yes", "No"), ticks = "", thickness = 15, len = 0.15)

# Have to use HTML to add a subtitle in plotly
map <- map %>% layout(geo = map_settings, title = list(text = paste0("COVID-19 Digital Contact Tracing (DCT) Status", "<br>", "<sup>", "As of July 3rd, 2020", "</sup>")))

# Modify the modebar to remove unnecessary buttons
map <- map %>% config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d", "pan2d", "hoverClosestGeo"))

# Display the map
map
