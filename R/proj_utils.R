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
    dplyr::rename_with(~ stringr::str_replace_all(., "\\.", "") |> 
                         
                         stringr::str_to_title())
}