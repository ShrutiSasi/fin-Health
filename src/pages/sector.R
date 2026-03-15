# Page 1: Sector Analysis — UI layout and server logic.

library(shiny)
library(bslib)
library(dplyr)
library(DT)
library(plotly)

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

sectorUI <- function() {
  sidebar <- bslib::sidebar(
    tags$h4("Analytics Filters"),
    sliderInput(
      inputId = "p1_year_range",
      label   = "Period",
      min     = as.integer(min(df$Year)),
      max     = as.integer(max(df$Year)),
      value   = c(as.integer(min(df$Year)), as.integer(max(df$Year))),
      step    = 1,
      sep     = ""
    ),
    selectizeInput(
      inputId  = "p1_sector",
      label    = "Sector",
      choices  = ALL_SECTORS,
      selected = NULL,
      multiple = TRUE,
      options  = list(placeholder = "All sectors")
    ),
    selectizeInput(
      inputId  = "p1_metric",
      label    = "Metric",
      choices  = names(METRIC_CHOICES),
      selected = "Net Profit Margin"
    ),
    actionButton("p1_reset", "Reset Filters"),
    open  = "desktop",
    width = 320
  )

  # KPI cards
  card_avg_margin <- kpi_card(
    header   = "Avg Profit Margin",
    value_id = "p1_avg_margin",
    trend_id = "p1_margin_trend",
    label_id = "p1_margin_badge"
  )
  card_revenue_growth <- kpi_card(
    header   = "Revenue Growth",
    value_id = "p1_revenue_growth_value",
    trend_id = "p1_revenue_trend",
    label_id = "p1_revenue_growth_label"
  )
  card_top_sector <- kpi_card(
    header   = "Top Sector",
    value_id = "p1_top_sector",
    label_id = "p1_top_sector_period"
  )
  card_index_perf <- kpi_card(
    header   = "Top Sector: Index Performance",
    value_id = "p1_index_perf_value",
    label_id = "p1_index_perf_label"
  )
  kpi_row <- tags$div(
    bslib::layout_columns(
      card_avg_margin,
      card_revenue_growth,
      card_top_sector,
      card_index_perf,
      col_widths = c(3, 3, 3, 3)
    ),
    class = "kpi-card-row"
  )

  # Chart cards
  card_sector_profitability <- bslib::card(
    bslib::card_header("Sector Comparison"),
    plotly::plotlyOutput("p1_chart_a", height = "400px"),
    full_screen = TRUE
  )
  card_trend <- bslib::card(
    bslib::card_header("Historical Trend"),
    plotly::plotlyOutput("p1_chart_b", height = "400px"),
    full_screen = TRUE
  )
  chart_row <- bslib::layout_columns(
    card_sector_profitability,
    card_trend,
    col_widths = c(6, 6)
  )

  # Peer + Table cards
  card_peer <- bslib::card(
    bslib::card_header("Peer Benchmarking"),
    plotly::plotlyOutput("p1_chart_c", height = "400px"),
    full_screen = TRUE
  )
  card_details <- bslib::card(
    bslib::card_header("Company Details"),
    DT::DTOutput("p1_table_d")
  )
  peer_row <- bslib::layout_columns(
    card_peer,
    card_details,
    col_widths = c(6, 6)
  )

  bslib::layout_sidebar(
    tags$h2("US Corporate Profitability Analytics"),
    kpi_row,
    chart_row,
    peer_row,
    sidebar = sidebar,
    fillable = FALSE
  )
}

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

sectorServer <- function(input, output, session) {

  # Safe metric getter — falls back to default if input is cleared
  p1_selected_metric <- reactive({
    m <- input$p1_metric
    if (is.null(m) || nchar(m) == 0 || !(m %in% names(METRIC_CHOICES))) {
      "Net Profit Margin"
    } else {
      m
    }
  })

  # Reset all filters to their initial values
  observeEvent(input$p1_reset, {
    updateSliderInput(session, "p1_year_range",
                      value = c(as.integer(min(df$Year)), as.integer(max(df$Year))))
    updateSelectizeInput(session, "p1_sector",   selected = character(0))
    updateSelectizeInput(session, "p1_metric",   selected = "Net Profit Margin")
  })

  # Filter dataset by selected year range and sector
  p1_filtered_data <- reactive({
    year_min <- input$p1_year_range[1]
    year_max <- input$p1_year_range[2]
    sector   <- input$p1_sector

    filtered <- df |> dplyr::filter(Year >= year_min, Year <= year_max)

    if (length(sector) > 0) {
      filtered <- filtered |> dplyr::filter(Category %in% sector)
    }
    filtered
  })

  # ---------------------------------------------------------------------------
  # KPI: Avg Profit Margin
  # ---------------------------------------------------------------------------

  output$p1_avg_margin <- renderText({
    d <- p1_filtered_data()
    if (nrow(d) == 0) return("Data Unavailable")
    sprintf("%.1f%%", mean(d[["Net Profit Margin"]], na.rm = TRUE))
  })

  output$p1_margin_trend <- renderUI({
    d <- p1_filtered_data()
    if (nrow(d) == 0) return(tags$span())

    years <- sort(unique(d$Year))
    if (length(years) < 2) return(tags$span())

    cur_margin  <- mean(d[d$Year == years[length(years)],     "Net Profit Margin", drop = TRUE], na.rm = TRUE)
    prev_margin <- mean(d[d$Year == years[length(years) - 1], "Net Profit Margin", drop = TRUE], na.rm = TRUE)

    if (is.na(cur_margin) || is.na(prev_margin)) return(tags$span())

    is_positive <- cur_margin >= prev_margin
    trend_char  <- if (is_positive) "\u25b2" else "\u25bc"
    trend_class <- if (is_positive) "trend-indicator up" else "trend-indicator down"
    tags$span(trend_char, class = trend_class)
  })

  output$p1_margin_badge <- renderUI({
    d <- p1_filtered_data()
    if (nrow(d) == 0) return(tags$span())
    n <- dplyr::n_distinct(d$Company)
    tags$p(
      paste("BASED ON", n, "COMPANIES"),
      class = "kpi-label",
      style = "margin-top: 0.5rem;"
    )
  })

  # ---------------------------------------------------------------------------
  # KPI: Top Sector
  # ---------------------------------------------------------------------------

  output$p1_top_sector <- renderText({
    d <- p1_filtered_data()
    if (nrow(d) == 0) return("Data Unavailable")
    d |>
      dplyr::group_by(Category) |>
      dplyr::summarise(avg = mean(`Net Profit Margin`, na.rm = TRUE), .groups = "drop") |>
      dplyr::slice_max(avg, n = 1, with_ties = FALSE) |>
      dplyr::pull(Category)
  })

  output$p1_top_sector_period <- renderUI({
    yr <- input$p1_year_range
    tags$p(
      paste(yr[1], "\u2013", yr[2]),
      class = "kpi-label",
      style = "margin-top: 0.5rem;"
    )
  })

  p1_index_margin <- reactive({
    d <- p1_filtered_data()
    if (nrow(d) == 0) return(0)
    total_rev <- sum(d$Revenue, na.rm = TRUE)
    total_ni  <- sum(d[["Net Income"]], na.rm = TRUE)
    if (total_rev == 0) return(0)
    (total_ni / total_rev) * 100
  })

  output$p1_index_perf_value <- renderText({
    sprintf("%.1f%%", p1_index_margin())
  })

  output$p1_index_perf_label <- renderUI({
    tags$p("NET PROFIT MARGIN", class = "kpi-label", style = "margin-top: 0.5rem;")
  })

  # ---------------------------------------------------------------------------
  # KPI: Revenue Growth
  # ---------------------------------------------------------------------------

  p1_revenue_change <- reactive({
    d <- p1_filtered_data()
    yearly <- d |>
      dplyr::group_by(Year) |>
      dplyr::summarise(rev = sum(Revenue, na.rm = TRUE), .groups = "drop") |>
      dplyr::arrange(dplyr::desc(Year))

    if (nrow(yearly) < 2) return(NULL)

    current  <- yearly$rev[1]
    previous <- yearly$rev[2]

    if (is.na(current) || is.na(previous) || previous == 0) return(NULL)

    growth <- (current - previous) / previous * 100
    list(value = growth, is_positive = growth >= 0)
  })

  output$p1_revenue_growth_value <- renderText({
    change <- p1_revenue_change()
    if (is.null(change)) return("Data Unavailable")
    sign <- if (change$is_positive) "+" else ""
    sprintf("%s%.1f%%", sign, change$value)
  })

  output$p1_revenue_growth_label <- renderUI({
    tags$p("YEAR OVER YEAR", class = "kpi-label", style = "margin-top: 0.5rem;")
  })

  output$p1_revenue_trend <- renderUI({
    change <- p1_revenue_change()
    if (is.null(change)) return(tags$span())
    trend_char  <- if (change$is_positive) "\u25b2" else "\u25bc"
    trend_class <- if (change$is_positive) "trend-indicator up" else "trend-indicator down"
    tags$span(trend_char, class = trend_class)
  })

  # ---------------------------------------------------------------------------
  # Charts
  # ---------------------------------------------------------------------------

  output$p1_chart_a <- plotly::renderPlotly({
    build_sector_bar(p1_filtered_data(), p1_selected_metric(),
                     METRIC_CHOICES[[p1_selected_metric()]])
  })

  output$p1_chart_b <- plotly::renderPlotly({
    build_metric_trend(p1_filtered_data(), p1_selected_metric(),
                       METRIC_CHOICES[[p1_selected_metric()]])
  })

  output$p1_chart_c <- plotly::renderPlotly({
    build_peer_scatter(p1_filtered_data(), p1_selected_metric(),
                       METRIC_CHOICES[[p1_selected_metric()]])
  })

  # ---------------------------------------------------------------------------
  # Company Details table
  # ---------------------------------------------------------------------------

  output$p1_table_d <- DT::renderDT({
    d <- p1_filtered_data()
    cols <- c("Company", "Category", "Year", "Revenue", "Net Income", "Net Profit Margin")
    DT::datatable(
      d[, cols],
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
}
