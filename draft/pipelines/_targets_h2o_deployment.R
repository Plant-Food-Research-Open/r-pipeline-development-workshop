box::use(
  here[here],
  targets[tar_target, tar_source],
  readr[read_csv],
  dplyr[select],
  pins[board_s3, pin_upload],
  vetiver[vetiver_model, vetiver_pin_write],
  agua,
  h2o[h2o.connect]
)

options(box.path = here())

box::use(R/tidymodels_deployment, R/h2o_deployment)

tar_source(here("R"))

list(
  tar_target(
    connection, h2o.connect(
      ip = "h2o.k8s.dev.co.nz", port = 443, https = TRUE
    )
  ),
  tar_target(
    mtcars, read_csv("https://raw.githubusercontent.com/plotly/datasets/refs/heads/master/mtcars.csv") |>
      select(-manufacturer)
  ),
  tar_target(
    data_split, tidymodels_deployment$get_split(mtcars)
  ),
  tar_target(
    data_train, data_split$train
  ),
  tar_target(
    data_test, data_split$test
  ),
  tar_target(
    training_recipe, tidymodels_deployment$get_training_recipe(data_train)
  ),
  tar_target(
    auto_fit, h2o_deployment$run_automl(training_recipe, data_train)
  ),
  tar_target(
    conformalised_stack, tidymodels_deployment$conformalise_model(auto_fit, data_train)
  ),
  tar_target(
    dalex_explainer,
    {
      box::use(DALEX[explain])
      box::use(h2o[h2o.predict, as.h2o])
      # Define custom predict function
      predict_function <- function(model, data) {
        as.vector(h2o.predict(model, as.h2o(data)))
      }
      explain(
        model = auto_fit$fit$fit,
        data = data_train |> dplyr::select(-mpg),
        y = data_train$mpg,
        predict_function = predict_function,
        label = "H2O AutoML"
      )
    }
  ),
  tar_target(
    board, board_s3(
      "data", 
      access_key = "user", 
      secret_access_key = "password", 
      region = "us-east-2",
      endpoint = "https://minio-api.k8s.dev.co.nz"
    )
  ),
  tar_target(
    v_conformalised_stack, vetiver_model(conformalised_stack, "conformalised_h2o_stack")
  ),
  tar_target(
    pinned_model, board |> vetiver_pin_write(v_conformalised_stack)
  )
)