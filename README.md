
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tornado- Plot

<!-- badges: start -->
<!-- badges: end -->

Tornado Plots are a special type of Bar chart, where the data categories
are listed vertically instead of the standard horizontal presentation,
and the categories are ordered so that the largest bar appears at the
top of the chart, the second largest appears second from the top, and so
on. They are so named because the final chart visually resembles either
one half of or a complete tornado.

## Installation

You can install the development version of tornadoPlot like so:

``` r
devtools::install_github('safetyGraphics/tornadoPlot', ref="main")
```

Or run in safetyGraphics:

``` r
library(torndadoPlot)

# Load standard graphics from safetyCharts + Volcano plot
charts<-c(
    safetyGraphics::makeChartConfig(),
    safetyGraphics::makeChartConfig(packages="torndadoPlot")
)

# Add default treatment columns
mapping <- list(dm=list('treatment_values--group1'="Placebo", 'treatment_values--group2'="Xanomeline High Dose"))

#Initialize SafetyGraphics app. 
safetyGraphics::safetyGraphicsApp(charts=charts, mapping=mapping)
```
