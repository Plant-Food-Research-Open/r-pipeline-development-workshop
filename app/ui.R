ui <- page_sidebar(
  title = "R Pipeline Development",
  
  theme = bs_theme(
    bootswatch = "lux",
    base_font = font_google("Inter"),
    navbar_bg = "#4a8273",
    font_scale = 0.8
  ),
  
  sidebar = sidebar(
    bg = "white",
    width = "25%",
    accordion(
      accordion_panel(
        "Inputs",
        selectInput(
          "model_choice",
          "Model",
          choices = model_choices,
          multiple = FALSE,
          selectize = TRUE
        ),
        selectInput(
          "x_ax",
          "X axis",
          character(0),
          selectize = TRUE
        ),
        selectInput(
          "y_ax",
          "Y axis",
          character(0),
          multiple = FALSE,
          selectize = TRUE
        ),
        selectInput(
          "plot_choice",
          "Plot",
          choices = c(),
          multiple = FALSE,
          selectize = TRUE
        )
      ),
      accordion_panel(
        "Predictions",
        tags$style(HTML("
        #predict {
          position: sticky;
          top: 10px;
          z-index: 1000;
        }
      ")),
        actionButton("predict", "Predict"),
        htmlOutput("dynamic_features"),
        actionButton("clear_predict", "Clear Predictions")
      ),
      accordion_panel(
        "Downloads",
        downloadButton("download_data", "Download Data"),
        downloadButton("download_card", "Download Card"),
        downloadButton("download_plot", "Download Plot")
      )
    )
  ),
  
  navset_card_underline(
    title = "Results",
    nav_panel(
      "Scatter", 
      card(
        plotlyOutput("scatter"),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Predictions", 
      card(
        plotlyOutput("predictions"),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Histograms", 
      layout_columns(
        card(
          plotlyOutput("histogram_x"),
          full_screen = TRUE
        ),
        card(
          plotlyOutput("histogram_y"),
          full_screen = TRUE
        )
      )
    ),
    nav_panel(
      "Data Table",
      card(
        dataTableOutput("table"),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Summary",
      card(
        dataTableOutput("summary"),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Model Card",
      card(
        htmlOutput("model_card"),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Plot",
      card(
        htmlOutput("dynamic_plot"),
        full_screen = TRUE
      )
    )
  )
)
 