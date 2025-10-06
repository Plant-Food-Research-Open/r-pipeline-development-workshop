box::use(
  crew[crew_controller_local],
  here[here],
  targets[tar_target, tar_source, tar_option_set, tar_cue]
)

options(box.path = here())

box::use(R/tidymodels_deployment, R/h2o_deployment)

tar_source(here("R"))

tar_option_set(
  packages = c("pins", "vetiver", "dplyr", "readr", "here", "h2o", "agua")
)

list(
  tar_target(
    connection, h2o.init(max_mem_size = "512M", nthreads = 1, startH2O = TRUE),
    cue = tar_cue("always")
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
    model_set_data, tidymodels_deployment$get_workflow_set(data_train, training_recipe)
  ),
  tar_target(
    tuned_model_set, tidymodels_deployment$optimise_hyperparams(
      model_set_data$model_set, 
      model_set_data$lr_recipe, 
      model_set_data$rf_recipe, 
      model_set_data$svm_recipe
    )
  ),
  tar_target(
    auto_fit, h2o_deployment$run_automl(training_recipe, data_train)
  ),
  tar_target(
    conformalised_stack, tidymodels_deployment$conformalise_model(auto_fit, data_train)
  ),
  tar_target(
    board, board_temp()
  ),
  tar_target(
    v_conformalised_stack, vetiver_model(conformalised_stack, "automl_model")
  ),
  tar_target(
    pinned_model, board |> vetiver_pin_write(v_conformalised_stack)
  )
)
