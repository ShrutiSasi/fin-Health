# Reusable KPI card factory for consistent card layouts.

library(shiny)
library(bslib)

#' Build a KPI card with a consistent structure.
#'
#' @param header      Card header text.
#' @param value_id    Output ID for the main KPI value (textOutput).
#' @param trend_id    Output ID for the trend indicator (uiOutput), optional.
#' @param label_id    Output ID for the label row below the value (uiOutput), optional.
#' @param status_id   Output ID for a health status icon (uiOutput), optional.
kpi_card <- function(header, value_id, trend_id = NULL,
                     label_id = NULL, status_id = NULL) {
  value_children <- list(
    tags$h3(
      textOutput(value_id, inline = TRUE),
      class = "kpi-value",
      style = "display: inline;"
    )
  )

  if (!is.null(status_id)) {
    value_children <- c(value_children, list(
      uiOutput(status_id, inline = TRUE)
    ))
  }

  if (!is.null(trend_id)) {
    value_children <- c(value_children, list(
      uiOutput(trend_id, inline = TRUE)
    ))
  }

  label_row <- tags$div(
    if (!is.null(label_id)) uiOutput(label_id) else tags$span(),
    class = "kpi-label-row"
  )

  bslib::card(
    bslib::card_header(header),
    do.call(tags$div, c(value_children, list(class = "kpi-value-row"))),
    label_row
  )
}
