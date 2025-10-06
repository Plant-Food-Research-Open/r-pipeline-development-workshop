#' Get metrics for predictive accuracy
#'
#' @param df The dataframe.
#' @param model The machine learning model.
#' @param model_name The machine learning model name.
#' @param preds The model predictions.
#'
#' @returns The model metrics.
#'
#' @export
get_predictive_metrics <- function(df, model, model_name, preds) {
  df |>
    dplyr::mutate(predicted_mpg = preds  |>
                    purrr::pluck(".pred")) |>
    yardstick::metrics(truth = mpg, estimate = predicted_mpg) |>
    dplyr::mutate(.estimator = model_name) |>
    dplyr::rename_with( ~ stringr::str_replace_all(., "\\.", "") |>
                          
                          stringr::str_to_title())
}


#' Explain variance for each principal component
#'
#' @param pca_prep The PCA preparation recipe.
#' @param pc_num The number of principal components to explain.
#' @param step_num The step number in the recipe for PCA.
#'
#' @returns The variance explained for each principal component.
#'
#' @export
pca_var_explained <- function(pca_prep, pc_num, step_num) {
  pca_var <- pca_prep$steps[[step_num]]$res$sdev^2
  pca_var <- pca_var[1:pc_num]
  pca_var <- pca_var / sum(pca_var)
  pca_var
}
