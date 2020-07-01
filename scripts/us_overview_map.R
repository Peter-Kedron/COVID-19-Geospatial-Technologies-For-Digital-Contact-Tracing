# Interactive map that provides an overview of current state status

library(here)
library(plotly)

state_data <- read.csv(here("data", "state_dctt_data.csv"))
state_data$map_hover_text <- with(state_data, paste("<b>", NAME, "</b>", "<br>", "Using DCTT:", DCTT_STATUS, "<br>", "Application Name:", APP_NAME, "<br>", "Technology:", TECHNOLOGY))

map_settings <- list(scope = 'usa', projection = list(type = 'albers usa'), showlakes = FALSE)

color_scale <- data.frame(z = c(0, 0.5, 0.5, 1), col = c("#b3cde3", "#b3cde3", "#ccebc5", "#ccebc5"))
#margins <- list(l = 0, r = 0, b = 0, t = 50, pad = 1)

map <- plot_geo(state_data, locationmode = "USA-states", name = "\n", colorscale = color_scale, width = 1000, height = 600)
map <- map %>% add_trace(z = ~DCTT_STATUS_NUM, locations = ~ABRV, hovertemplate = ~map_hover_text, color = ~DCTT_STATUS_NUM, colors = c("#b3cde3","#ccebc5"), showscale = TRUE)
map <- map %>% colorbar(title = list(text = "Using DCTT", font = list(size = 15)), tickmode = "array", tickvals = list(0.75, 0.25), ticktext = list("True", "False"), ticks = "", thickness = 15, len = 0.15)
map <- map %>% layout(title = "COVID-19 Digital Contact Tracing Technology (DCTT) Status", geo = map_settings)

map