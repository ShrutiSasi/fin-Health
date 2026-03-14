# Pure ggplot2 + plotly chart builder functions — no Shiny imports.
# All functions return a plotly object.

library(ggplot2)
library(dplyr)
library(plotly)
library(tidyr)

# Okabe-Ito colour-blind-safe categorical palette (matches Python PALETTE)
PALETTE <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442",
  "#0072B2", "#D55E00", "#CC79A7", "#334155"
)

# Shared ggplot2 theme applied to every chart
.fin_theme <- function() {
  ggplot2::theme_minimal(base_family = "sans") +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = "transparent", colour = NA),
      panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      panel.grid.major = ggplot2::element_line(colour = "#e2e8f0"),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(colour = "#475569", size = 9),
      axis.title       = ggplot2::element_text(colour = "#0f172a", size = 10),
      plot.title       = ggplot2::element_text(colour = "#0f172a", size = 11,
                                               face = "bold"),
      legend.text      = ggplot2::element_text(colour = "#475569", size = 8),
      legend.title     = ggplot2::element_text(colour = "#0f172a", size = 9)
    )
}

# Empty-state plotly for when filtered data has no rows
empty_chart <- function(message = "Data Unavailable") {
  plotly::plot_ly() |>
    plotly::add_annotations(
      text      = message,
      x         = 0.5, y = 0.5,
      xref      = "paper", yref = "paper",
      showarrow = FALSE,
      font      = list(size = 16, color = "#475569")
    ) |>
    plotly::layout(
      xaxis = list(visible = FALSE),
      yaxis = list(visible = FALSE),
      paper_bgcolor = "transparent",
      plot_bgcolor  = "transparent"
    )
}

# Bar chart of average metric by sector.
build_sector_bar <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  avg_by_sector <- data |>
    dplyr::group_by(Category) |>
    dplyr::summarise(avg = mean(.data[[metric]], na.rm = TRUE), .groups = "drop")

  if (nrow(avg_by_sector) == 0) return(empty_chart())

  p <- ggplot2::ggplot(
    avg_by_sector,
    ggplot2::aes(
      x    = reorder(Category, -avg),
      y    = avg,
      fill = Category,
      text = paste0(Category, ": ", round(avg, 2), " ", unit)
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = PALETTE) +
    ggplot2::guides(fill = "none") +
    ggplot2::labs(
      title = paste("Average", metric, "by Sector"),
      x     = "Sector",
      y     = trimws(paste(metric, unit))
    ) +
    .fin_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Line chart of metric trend over time by sector.
build_metric_trend <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  observed_trend <- data |>
    dplyr::group_by(Year, Category) |>
    dplyr::summarise(avg = mean(.data[[metric]], na.rm = TRUE), .groups = "drop")

  if (nrow(observed_trend) == 0) return(empty_chart())

  p <- ggplot2::ggplot(
    observed_trend,
    ggplot2::aes(
      x      = Year,
      y      = avg,
      colour = Category,
      group  = Category,
      text   = paste0(Category, " (", Year, "): ", round(avg, 2), " ", unit)
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_manual(values = PALETTE) +
    ggplot2::labs(
      title  = paste(metric, "Trend by Sector"),
      x      = "Year",
      y      = trimws(paste(metric, unit)),
      colour = "Sector"
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Scatter plot of Revenue vs selected metric.
build_peer_scatter <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x      = Revenue,
      y      = .data[[metric]],
      colour = Category,
      text   = paste0(
        "Company: ", Company, "<br>",
        "Year: ", Year, "<br>",
        "Revenue: ", formatC(Revenue, format = "f", digits = 0, big.mark = ","), "<br>",
        metric, ": ", round(.data[[metric]], 2), " ", unit
      )
    )
  ) +
    ggplot2::geom_point(size = 2.5, alpha = 0.8) +
    ggplot2::scale_colour_manual(values = PALETTE) +
    ggplot2::scale_x_continuous(labels = function(x) {
      dplyr::case_when(
        abs(x) >= 1e9  ~ paste0("$", round(x / 1e9, 1), "B"),
        abs(x) >= 1e6  ~ paste0("$", round(x / 1e6, 1), "M"),
        abs(x) >= 1e3  ~ paste0("$", round(x / 1e3, 1), "K"),
        TRUE           ~ paste0("$", x)
      )
    }) +
    ggplot2::labs(
      title  = paste("Revenue vs", metric),
      x      = "Revenue ($)",
      y      = trimws(paste(metric, unit)),
      colour = "Sector"
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Grouped bar chart of Revenue and Net Income over time (Page 2).
build_revenue_over_time <- function(data, company) {
  if (nrow(data) == 0) return(empty_chart())

  melted <- data |>
    dplyr::select(Year, Revenue, `Net Income`) |>
    tidyr::pivot_longer(
      cols      = c("Revenue", "Net Income"),
      names_to  = "Metric",
      values_to = "Amount"
    )

  p <- ggplot2::ggplot(
    melted,
    ggplot2::aes(
      x    = factor(Year),
      y    = Amount,
      fill = Metric,
      text = paste0(Metric, " (", Year, "): $", formatC(Amount, format = "f",
                                                         digits = 0, big.mark = ","), "M")
    )
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::scale_fill_manual(
      values = c("Revenue" = "#2563eb", "Net Income" = "#009e73")
    ) +
    ggplot2::labs(
      title = paste("Revenue & Net Income \u2014", company),
      x     = "Year",
      y     = "$ millions",
      fill  = NULL
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Line + shaded-area chart of a ratio metric over time for a single company (Page 2).
build_ratio_over_time <- function(data, company, metric) {
  if (nrow(data) == 0) return(empty_chart())

  p <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x    = Year,
      y    = .data[[metric]],
      text = paste0(metric, " (", Year, "): ", round(.data[[metric]], 2))
    )
  ) +
    ggplot2::geom_area(alpha = 0.08, fill = "#2563eb") +
    ggplot2::geom_line(colour = "#2563eb", linewidth = 1.2) +
    ggplot2::geom_point(colour = "#2563eb", size = 2.5) +
    ggplot2::labs(
      title = paste(metric, "Over Time \u2014", company),
      x     = "Year",
      y     = metric
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Grouped bar chart of Operating, Investing, Financing cash flows (Page 2).
build_cash_flows <- function(data, company) {
  if (nrow(data) == 0) return(empty_chart())

  cf_rename <- c(
    "Cash Flow from Operating"            = "Operating",
    "Cash Flow from Investing"            = "Investing",
    "Cash Flow from Financial Activities" = "Financing"
  )

  melted <- data |>
    dplyr::select(Year, dplyr::all_of(names(cf_rename))) |>
    tidyr::pivot_longer(
      cols      = dplyr::all_of(names(cf_rename)),
      names_to  = "Flow Type",
      values_to = "Amount"
    ) |>
    dplyr::mutate(`Flow Type` = cf_rename[`Flow Type`])

  p <- ggplot2::ggplot(
    melted,
    ggplot2::aes(
      x    = factor(Year),
      y    = Amount,
      fill = `Flow Type`,
      text = paste0(`Flow Type`, " (", Year, "): $",
                    formatC(Amount, format = "f", digits = 0, big.mark = ","), "M")
    )
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::scale_fill_manual(
      values = c("Operating" = "#2563eb", "Investing" = "#c0392b", "Financing" = "#f59e0b")
    ) +
    ggplot2::labs(
      title = paste("Cash Flows \u2014", company),
      x     = "Year",
      y     = "Cash Flow ($ millions)",
      fill  = NULL
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Bar chart comparing companies on a metric (used when 1 sector or 1 year).
build_company_comparison_bar <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  avg_by_company <- data |>
    dplyr::group_by(Company) |>
    dplyr::summarise(avg = mean(.data[[metric]], na.rm = TRUE), .groups = "drop")

  p <- ggplot2::ggplot(
    avg_by_company,
    ggplot2::aes(
      x    = reorder(Company, -avg),
      y    = avg,
      fill = Company,
      text = paste0(Company, ": ", round(avg, 2), " ", unit)
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = rep(PALETTE, length.out = nrow(avg_by_company))) +
    ggplot2::guides(fill = "none") +
    ggplot2::labs(
      title = paste(metric, "by Company"),
      x     = "Company",
      y     = trimws(paste(metric, unit))
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Horizontal bar of key metrics for a single company / single year.
build_single_company_summary <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  key_metrics <- c("Revenue", "Net Income", "EBITDA", "ROE", "ROA", "Net Profit Margin")
  available   <- intersect(key_metrics, names(data))
  row         <- data[1, available, drop = FALSE]
  company     <- if ("Company" %in% names(data)) data$Company[1] else "Company"

  melted <- data.frame(
    Metric = available,
    Value  = as.numeric(row[1, available])
  )

  p <- ggplot2::ggplot(
    melted,
    ggplot2::aes(
      x    = Value,
      y    = reorder(Metric, Value),
      fill = Metric,
      text = paste0(Metric, ": ", round(Value, 2))
    )
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = rep(PALETTE, length.out = nrow(melted))) +
    ggplot2::guides(fill = "none") +
    ggplot2::labs(
      title = paste("Key Metrics \u2014", company),
      x     = "Value",
      y     = NULL
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}

# Trend lines coloured by company (used when few companies, many years).
build_company_trend <- function(data, metric, unit) {
  if (nrow(data) == 0) return(empty_chart())

  trend <- data |>
    dplyr::group_by(Year, Company) |>
    dplyr::summarise(avg = mean(.data[[metric]], na.rm = TRUE), .groups = "drop")

  p <- ggplot2::ggplot(
    trend,
    ggplot2::aes(
      x      = Year,
      y      = avg,
      colour = Company,
      group  = Company,
      text   = paste0(Company, " (", Year, "): ", round(avg, 2), " ", unit)
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_manual(values = rep(PALETTE, length.out = dplyr::n_distinct(trend$Company))) +
    ggplot2::labs(
      title  = paste(metric, "Trend by Company"),
      x      = "Year",
      y      = trimws(paste(metric, unit)),
      colour = "Company"
    ) +
    .fin_theme()

  plotly::ggplotly(p, tooltip = "text") |>
    plotly::layout(paper_bgcolor = "transparent", plot_bgcolor = "transparent")
}
