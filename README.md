# fin-Health

| | |
| --- | --- |
| Build | [![Build/Deploy Docs](https://github.com/ShrutiSasi/fin-Health/actions/workflows/docs-preview.yml/badge.svg)](https://github.com/ShrutiSasi/fin-Health/actions/workflows/docs-publish.yml) |
| Project | [![R Shiny](https://img.shields.io/badge/R-Shiny-blue)](https://shiny.posit.co/) [![Repo Status](https://img.shields.io/badge/repo%20status-Active-brightgreen)](https://github.com/ShrutiSasi/fin-Health) |
| Meta | [![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md) [![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) |

## Project Synopsis

`fin-Health` is an interactive dashboard that visualizes the financial health of publicly traded companies. It allows users to explore key financial metrics such as revenue, profitability, debt ratios, and cash flow across companies and time periods. fin-Health supports investors and analysts in making data-driven comparisons and evaluating corporate financial performance across sectors and time.

## Motivation
Investment analysts and portfolio managers often need to compare financial performance across sectors and individual companies to support data-driven investment decisions. However, extracting insights from financial statements typically requires manually compiling data and creating ad-hoc visualizations, a process that can be both time-consuming and prone to errors.

`fin-Health` addresses this challenge by providing a centralized, interactive dashboard that enables users to explore financial performance efficiently. By allowing users to filter data by time period, sector, and financial metrics, the dashboard facilitates rapid analysis of profitability trends, peer benchmarking, and key financial indicators.

## Features and User Interface
- **Sector Analysis (Strategic Overview)**
    - **Peer Benchmarking**: Visualize sector profitability and revenue growth using reactive ggplot2/plotly scatter plots and bar charts.
    - **Trend Indicators**: Real-time KPI cards showing margin trends with visual directional cues (▲/▼).

## Demo

Below is a short preview of the dashboard interface.
![Dashboard demo](img/demo.gif)

## Deployment

| Build | URL |
|-------|-----|
| Stable (`main`) | [https://019ceef7-68e4-5346-4909-7d59e76f82a5.share.connect.posit.cloud/](https://019ceef7-68e4-5346-4909-7d59e76f82a5.share.connect.posit.cloud/) |
| Preview (`dev`) | [https://019ceeab-da38-fe19-be20-c31d0b3abe3d.share.connect.posit.cloud/](https://019ceeab-da38-fe19-be20-c31d0b3abe3d.share.connect.posit.cloud/)|

## Developer Setup

### Dependencies

-   R (version 4.3 or higher)
-   R packages: `shiny`, `bslib`, `here`, `readr`, `dplyr`, `stringr`, `ggplot2`, `plotly`, `tidyr`, `DT`
-   (Optional) `conda` for environment management

For a more comprehensive guide on development guidelines for this project, check out our contributing page [here](./CONTRIBUTING.md).

1. Install [R](https://cran.r-project.org/) (>= 4.3) as a prerequisite. Optionally install [`conda`](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) for environment management.

2. Open terminal and run the following commands.

3. Clone the repository:

```bash
git clone https://github.com/ShrutiSasi/fin-Health.git
cd fin-Health
```

4. Create and activate the conda environment (optional):

```bash
conda env create -f environment.yml
conda activate fin-Health
```

5. Run fin-Health Shiny for R dashboard locally:

```bash
Rscript -e 'shiny::runApp("src/app.R", launch.browser = TRUE)'
```

## Contributing

Interested in contributing? Check out the contributing guidelines [here](./CONTRIBUTING.md). Please note that this project is released with a Code of Conduct. By contributing to this project, you agree to abide by its terms.

## License

- Copyright © 2026 Shruti Sasi

- Free software distributed under the [MIT License](./LICENSE.md).
- Documentation made available under **Creative Commons By 4.0 - Attribution 4.0 International** ([CC-BY-4.0](./LICENSE.md))
