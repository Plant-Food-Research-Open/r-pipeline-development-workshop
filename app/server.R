server <- function(input, output, session) {
  model_choice <- reactive({
    input$model_choice
  }) 
  
  plot_choice <- reactive({
    input$plot_choice
  })
  
  x_ax <- reactive({
    input$x_ax
  })  
  
  y_ax <- reactive({
    input$y_ax
  })  
  
  axes_choices <- reactive({
    df() |>
      colnames()
  })
  
  model_endpoint <- reactive({
    val <- model_choice()
    idx <- match(val, model_choices)
    model_endpoints[[idx]]
  })
  
  df_features <- reactive({
    paste(model_endpoint(), "prototype", sep = "/") |>
      GET() |>
      content("text") |>
      fromJSON()
  }) |>
    bindCache(input$model_choice)
  
  df <- reactive({
    paste(model_endpoint(), "data", sep = "/") |>
      GET() |>
      content("text") |>
      fromJSON() |>
      as_tibble()
  }) |>
    bindCache(input$model_choice)
  
  prediction_df <- reactiveVal(tibble())
  
  model_card <- reactive({
    paste(model_endpoint(), "card", sep = "/") |>
      GET() |>
      content("text") |>
      fromJSON()
  }) |>
    bindCache(input$model_choice)
  
  s3_list <- reactive({
    paste(model_endpoint(), "s3-objects", sep = "/") |>
      GET() |>
      content("text") |>
      fromJSON()
  }) |>
    bindCache(input$model_choice)
  
  s3_object <- reactive({
    val <- plot_choice()
    idx <- match(val, plot_choices())
    if(is.na(idx)) {
      return()
    }
    s3_list()[idx]
  })
  
  plot_choices <- reactive({
    s3_list() |>
      basename() |>
      file_path_sans_ext()
  })
  
  model_card_content <- reactive({
    doc <- GET(model_card()) |>
      content("text", encoding = "UTF-8") |>
      read_html() 
    
    xml_remove(xml_find_all(doc, ".//style"))
    xml_remove(xml_find_all(doc, ".//script"))
    
    as.character(doc) |>
    HTML()
  }) |>
    bindCache(input$model_choice)
  
  observeEvent(input$model_choice, {
    output$table <- renderDataTable({
      df()
    })
    
    output$summary <- renderDataTable({
      summary(df()) |>
        as.data.frame() |>
        mutate(Variable = Var2, Statistic = Freq) |>
        select(Variable, Statistic) 
    })
    
    output$model_card <- renderUI({
      model_card_content()
    })
    
    output$dynamic_features <- renderUI({
      lapply(names(df_features()), function(feature_name) {
        feature_type <- df_features()[[feature_name]]$type
        switch(feature_type,
               character = textInput(feature_name, label = feature_name, value = "None"),
               numeric = numericInput(feature_name, label = feature_name, value = 0),
               select = selectInput(feature_name, label = feature_name, choices = c()),
               NULL
        )
      })
    })

    updateSelectizeInput(
      session, "plot_choice", choices = plot_choices(), server = FALSE,
      selected = plot_choices()[1]
    )
    
    axes_choices <- axes_choices()
    updateSelectizeInput(
      session, "x_ax", choices = axes_choices, server = FALSE,
      selected = axes_choices[1]
    )
    
    updateSelectizeInput(
      session, "y_ax", choices = axes_choices, server = FALSE,
      selected = axes_choices[2]
    )
    
  })
  
  observeEvent(input$plot_choice, { 
    output$dynamic_plot <- renderUI({
      src <- s3_object() |>
        GET() |>
        content("text", encoding = "UTF-8")

      tags$iframe(
        srcdoc= src,
        width = "100%",
        height = "100%",
        frameborder = "0"
      ) 
    })
  })
  
  observeEvent(input$clear_predict, { 
    prediction_df(tibble())
  })
  
  observeEvent(input$predict, {
    req_body <- reactiveValuesToList(input)[names(df_features())] |>
      as.tibble()

    preds <- paste(model_endpoint(), "predict", sep = "/") |>
      POST(
        body = req_body,
        encode = "json"
      ) |>
      content("text") |>
      fromJSON()
    
    req_body$.pred <- preds$.pred$.pred
    req_body$.pred_lower <- preds$.pred$.pred_lower
    req_body$.pred_upper <- preds$.pred$.pred_upper
    print(req_body)
    prediction_df(bind_rows(prediction_df(), req_body))
    
    output$predictions <- renderPlotly({
      axes_choices <- axes_choices()
      x_ax <- x_ax()
      
      if((!x_ax %in% axes_choices)) {
        return()  
      }
      
      if(nrow(prediction_df()) == 0) {
        return()
      }
      
      (
        prediction_df() |>
          ggplot(aes(x=.data[[x_ax]], y=.data[[".pred"]])) +
          geom_point() +
          geom_line() +
          geom_errorbar(aes(ymin = .data[[".pred_lower"]], ymax = .data[[".pred_upper"]]), width = 0.3)
      ) |>
        ggplotly()
    })
  })
  
  output$scatter <- renderPlotly({
    axes_choices <- axes_choices()
    x_ax <- x_ax()
    y_ax <- y_ax()
    
    if((!x_ax %in% axes_choices) || ( !y_ax %in% axes_choices)) {
      return()  
    }
    
    (
      df() |>
        ggplot(aes(x=.data[[x_ax]], y=.data[[y_ax]])) +
        geom_point() +
        geom_line()
    ) |>
    ggplotly()
      
  }) 
  
  render_histogram <- function(df, axes_choices, ax) {
    if((!ax %in% axes_choices)) {
      return()  
    }
    
    (
      df |>
        ggplot(aes(x=.data[[ax]])) +
        geom_histogram()
    ) |>
      ggplotly()
  }
  
  output$histogram_x <-  renderPlotly({
    render_histogram(df(), axes_choices(), x_ax())
  }) 
  
  output$histogram_y <-  renderPlotly({
    render_histogram(df(), axes_choices(), y_ax())
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste(model_choice(), "-data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(df(), file, row.names = FALSE)
    }
  )
  
  output$download_card <- downloadHandler(
    filename = function() {
      paste(model_choice(), "-card-", Sys.Date(), ".html", sep = "")
    },
    content = function(file) {
      GET(model_card()) |>
        content("text", encoding = "UTF-8") |>
        writeLines(file)
    }
  )
  
  output$download_plot <- downloadHandler(
    filename = function() {
      paste(model_choice(), "-plot-", Sys.Date(), ".html", sep = "")
    },
    content = function(file) {
      GET(s3_object()) |>
        content("text", encoding = "UTF-8") |>
        writeLines(file)
    }
  )
}
