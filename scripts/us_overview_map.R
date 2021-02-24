# Interactive map that provides an overview of current state status

library(ggplot2)
library(plotly)
library(here)

# Read the state status data
state_data <- read.csv(here("data", "State-DCT-Apps-Website-Data.csv"))

# Read the status data for the DC app
dc <- jsonlite::fromJSON(here("data", "dc.json"))

# Generate the hover text for all states
state_data$map_hover_text <- with(state_data, paste("<b>", State, "</b>", "<br>", "App Planned:", App.Planned, "<br>", "App Name:", App.Name, "<br>", "Technology:", Technology.Used, "<br>", "Google-Apple Tech:", Google.Apple.Technology))

# Generate the hover text for DC app
dc_hover <- state_data$map_hover_text[51]

# Generate the new App.Planned.Num column dummy column to shade the choropleth map
state_data$App.Planned.Num <- ifelse(state_data$App.Planned == "Yes", 0.5, 0)
state_data$App.Planned.Num <- ifelse(state_data$App.Released.As.Of.Review.Date == "Yes", 1, state_data$App.Planned.Num)

# Set map settings
map_settings <- list(scope = 'usa', projection = list(type = 'albers usa'), showlakes = FALSE)

# Use this color scale for the map
color_scale <- data.frame(z = c(0, 0.33 , 0.33, 0.66, 0.66, 1), col = c("#f8f8f8", "#f8f8f8", "#E3B022", "#E3B022", "#800000", "#800000"))

# Create the map, add one trace for the states and others for county apps, set the colorbar, and set the title.
map <- plot_geo(state_data, name = "\n", colorscale = color_scale, width = 950)

map <- map %>% add_trace(locationmode = "USA-states", z = ~App.Planned.Num, locations = ~Abbreviation, hovertemplate = ~map_hover_text, color = ~App.Planned.Num, colors = c("#f8f8f8", "#E3B022", "#800000"), showscale = TRUE)
map <- map %>% add_trace(name = "\n\n", geojson = dc, z = ~App.Planned.Num[51], locations = "11001", hovertemplate = dc_hover, colors = c("#f8f8f8", "#E3B022", "#800000"), showscale = FALSE, color = I("White"))

map <- map %>% colorbar(title = list(text = "DCT App Planned", font = list(size = 15)), tickmode = "array", tickvals = list(0.80, 0.50, 0.20), ticktext = list("Yes, Released", "Yes, Limited Release", "No"), ticks = "", thickness = 15, len = 0.20, x = 0, y = 1)

# Have to use HTML to add a subtitle in plotly
map <- map %>% layout(geo = map_settings, title = list(text = paste0("COVID-19 Digital Contact Tracing Technology (DCTT) Status", "<br>", "<sup>", "As of February 15, 2021", "</sup>")))

# Modify the modebar to remove unnecessary buttons
map <- map %>% config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d", "pan2d", "hoverClosestGeo"))

# Display the map
map

