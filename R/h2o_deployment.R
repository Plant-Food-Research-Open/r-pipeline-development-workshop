#' Run H2O's AutoML algorithm
#'
#' @param training_recipe The model training recipe.
#' @param data_train The training data split.
#' 
#' @return The AutoML model.
#' @export
run_automl <- function(training_recipe, data_train) {
  auto_spec <-
    parsnip::auto_ml() |>
    parsnip::set_engine("h2o", max_runtime_secs = 20, seed = 1) |>
    parsnip::set_mode("regression")
  
  auto_wflow <-
    workflows::workflow() |>
    workflows::add_model(auto_spec) |>
    workflows::add_recipe(training_recipe)
  
  auto_fit <- workflows::fit(auto_wflow, data = data_train)
}