# fin-health dashboard — R Shiny entry point.
# Mirrors src/app.py

library(shiny)
library(bslib)
library(here)

# Load shared data and constants
source(here::here("src", "data.R"))

# Load chart builders
source(here::here("src", "charts", "ggplot_charts.R"))

# Load reusable UI components
source(here::here("src", "components", "kpi_card.R"))

# Load page modules
source(here::here("src", "pages", "sector.R"))

# ---------------------------------------------------------------------------
# Custom CSS
# ---------------------------------------------------------------------------

css_path   <- here::here("assets", "custom_styles.css")
custom_css <- tags$style(paste(readLines(css_path, warn = FALSE), collapse = "\n"))

# R-specific structural overrides — loaded AFTER custom_styles.css to
# neutralize Python-Shiny layout rules that break R bslib's DOM.
r_css_path   <- here::here("assets", "r_overrides.css")
r_layout_css <- tags$style(paste(readLines(r_css_path, warn = FALSE), collapse = "\n"))

# ---------------------------------------------------------------------------
# App UI
# ---------------------------------------------------------------------------

# Last-updated date from git log (falls back gracefully if git is unavailable)
last_updated <- tryCatch(
  substr(system2("git", c("log", "-1", "--format=%ci"),
                 stdout = TRUE, stderr = FALSE)[1], 1, 10),
  error = function(e) "N/A"
)

footer <- tags$footer(
  tags$div(
    tags$p(
      "US Corporate Financial Health Dashboard | ",
      "Shruti Sasi | ",
      tags$a("GitHub Repo", href = "https://github.com/ShrutiSasi/fin-Health"),
      paste0(" | Last updated: ", last_updated),
      style = "text-align: center; font-size: 0.85em; color: #888;"
    ),
    class = "footer-container"
  )
)

# page_navbar IS the full page — inject CSS via the `header` argument and
# append the footer via `footer`. Do NOT wrap it in tagList().
app_ui <- bslib::page_navbar(
  bslib::nav_panel("Sector Analysis",  sectorUI()),
  title    = "fin-Health",
  id       = "main_nav",
  fillable = FALSE,
  header   = tagList(custom_css, r_layout_css),
  footer   = footer
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

server <- function(input, output, session) {
  sectorServer(input, output, session)
}

# ---------------------------------------------------------------------------
# Launch
# ---------------------------------------------------------------------------

shinyApp(ui = app_ui, server = server)
