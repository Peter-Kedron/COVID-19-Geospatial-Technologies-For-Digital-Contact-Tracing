# Interactive map that provides an overview of current state status

library(ggplot2)
library(plotly)
library(here)

state_data <- read.csv(here("data", "State DCT Apps - Website Data.csv"))
state_data$map_hover_text <- with(state_data, paste("<b>", State, "</b>", "<br>", "App Planned:", App.Planned, "<br>", "App Name:", App.Name, "<br>", "Technology:", Technology))

state_data$App.Planned.Num <- ifelse(state_data$App.Planned == "Yes" | state_data$App.Planned == "Statewide App" | state_data$App.Planned == "Countywide App", 1, 0)

map_settings <- list(scope = 'usa', projection = list(type = 'albers usa'), showlakes = FALSE)

color_scale <- data.frame(z = c(0, 0.5, 0.5, 1), col = c("#f8f8f8", "#f8f8f8", "#800000", "#800000"))
#margins <- list(l = 0, r = 0, b = 0, t = 100, pad = 1)

map <- plot_geo(state_data, locationmode = "USA-states", name = "\n", colorscale = color_scale, width = 1000, height = 600)
map <- map %>% add_trace(z = ~App.Planned.Num, locations = ~Abrv, hovertemplate = ~map_hover_text, color = ~App.Planned.Num, colors = c("#f8f8f8","#800000"), showscale = TRUE)
map <- map %>% colorbar(title = list(text = "DCT App Planned", font = list(size = 15)), tickmode = "array", tickvals = list(0.75, 0.25), ticktext = list("Yes", "No"), ticks = "", thickness = 15, len = 0.15)
map <- map %>% layout(title = "COVID-19 Digital Contact Tracing (DCT) Status", geo = map_settings)

map
