#' Get the data split
#'
#' @param df The tibble.
#' @param prop The train-test proportion.
#'
#' @return The data split.
#' @export
get_split <- function(df, prop = 0.90) {
  data_split <- df |>
    rsample::initial_split(prop = prop)
  
  data_train <- rsample::training(data_split)
  data_test  <- rsample::testing(data_split)
  
  return(list(train = data_train, test = data_test))
}

#' Get the data training recipe
#'
#' @param data_train The training split.
#'
#' @return The training recipe.
#'
#' @export
get_training_recipe <- function(data_train) {
  training_recipe <- recipes::recipe(data_train) |>
    recipes::update_role(rsample::everything(), new_role = "predictor") |>
    recipes::update_role(mpg, new_role = "outcome") |>
    recipes::step_zv() |>
    recipes::step_nzv() |>
    recipes::step_normalize(recipes::all_numeric(), -recipes::all_outcomes()) |>
    recipes::step_impute_knn()
  
  training_recipe
}


#' Get a model workflow set
#'
#' @param data_train The training data split.
#' @param n_folds The number of folds for cross-validation.
#' @param no_improve The patience for expected improvement.
#' @param iter The number of iterations for Bayesian optimisation.
#' @param initial The initial design size.
#'
#' @return The workflow set.
#'
#' @export
get_workflow_set <-
  function(data_train,
           training_recipe,
           n_folds = 5,
           no_improve = 5,
           iter = 5,
           initial = 5) {
    metric <- yardstick::metric_set(yardstick::rmse, yardstick::mae)
    
    folds <- rsample::vfold_cv(data_train, v = n_folds)
    
    ctrl_grid <- tune::control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      extract = identity,
      parallel_over = "resamples",
      allow_par = TRUE
    )
    
    lr_recipe <-
      parsnip::linear_reg(mixture = tune::tune(), penalty = tune::tune()) |>
      parsnip::set_engine("glmnet") |>
      parsnip::set_mode("regression")
    
    rf_recipe <- parsnip::rand_forest(trees = tune::tune()) |>
      parsnip::set_engine("ranger") |>
      parsnip::set_mode("regression")
    
    svm_recipe <- parsnip::svm_linear(margin = tune::tune()) |>
      parsnip::set_engine("kernlab") |>
      parsnip::set_mode("regression")
    
    model_set <- workflowsets::workflow_set(
      preproc = list(standard = training_recipe),
      models = list(lr = lr_recipe, rf = rf_recipe, svm = svm_recipe),
      cross = TRUE
    ) |>
      workflowsets::option_add(
        metrics = metric,
        control = ctrl_grid,
        resamples = folds
      )
    
    list(
      model_set = model_set,
      lr_recipe = lr_recipe,
      rf_recipe = rf_recipe,
      svm_recipe = svm_recipe
    )
  }


#' Perform hyperparameter optimisation
#'
#' @param model_set The candidate model set.
#' @param lr_recipe The linear regression recipe.
#' @param rf_recipe The random forest recipe.
#' @param svm_recipe The support vector machine recipe.
#'
#' @return The optimised model set.
#'
#' @export
optimise_hyperparams <- function(model_set,
                                 lr_recipe,
                                 rf_recipe,
                                 svm_recipe) {
  lr_params <- tune::extract_parameter_set_dials(lr_recipe) |>
    recipes::update(mixture = dials::mixture(c(0, 1)),
                    penalty = dials::penalty(c(0, 5)))
  
  rf_params <- tune::extract_parameter_set_dials(rf_recipe) |>
    recipes::update(trees = dials::trees(c(1, 250)))
  
  svm_params <- tune::extract_parameter_set_dials(svm_recipe) |>
    recipes::update(margin = dials::svm_margin(c(0, 0.25)))
  
  model_set <- model_set |>
    workflowsets::option_add_parameters() |>
    workflowsets::option_add(param_info = lr_params, id = "standard_lr") |>
    workflowsets::option_add(param_info = rf_params, id = "standard_rf") |>
    workflowsets::option_add(param_info = svm_params, id = "standard_svm")
  
  tuned_model_set <- model_set |>
    workflowsets::workflow_map("tune_grid", seed = 1000)
  
}

#' Create a stacking ensemble
#'
#' @param tuned_model_set The tuned model candidate set.
#'
#' @return The stacking ensemble.
#'
#' @export
stack_model_set <- function(tuned_model_set) {
  stack_reg <- stacks::stacks() |>
    stacks::add_candidates(tuned_model_set)
  
  invisible(
    utils::capture.output(
      stack_reg <- stack_reg |>
        stacks::blend_predictions(
          penalty =  10^(-10:-1),
          mixture = 0,
          times = 10
        ) |>
        stacks::fit_members()
    )
  )
  
  stack_reg
}


#' Patch the tidymodel properties
#'
#' @param tidymodel_reg The tidymodel regressor.
#' @param training_recipe The model training recipe.
#' @param data_train The training data split.
#'
#' @return The patched tidymodel regressor.
#'
#' @export
patch_tidymodel <- function(tidymodel_reg,
                            training_recipe,
                            data_train) {
  dummy_reg_spec <-
    parsnip::linear_reg() |>
    parsnip::set_engine("lm")
  
  dummy_reg_wflow <-
    workflows::workflow() |>
    workflows::add_model(dummy_reg_spec) |>
    workflows::add_recipe(training_recipe)
  
  set.seed(1000)
  dummy_reg <-
    workflows::fit(dummy_reg_wflow, data = data_train)
  
  
  class(tidymodel_reg) <- c(class(tidymodel_reg), "workflow")
  
  tidymodel_reg$trained <- dummy_reg$trained
  tidymodel_reg$pre <- dummy_reg$pre
  tidymodel_reg$training <- data_train
  
  tidymodel_reg
}



#' Conformalise the tidymodel.
#'
#' @param tidymodel_reg The tidymodel regressor.
#' @param data_train The training data split.
#'
#' @return The conformalised model
#'
#' @export
conformalise_model <- function(tidymodel_reg, data_train) {
  conformalised_reg <- probably::int_conformal_split(tidymodel_reg, data_train)
  conformalised_reg$training <- data_train
  
  conformalised_reg
}