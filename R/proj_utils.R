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

#' Upload S3 file.
#'
#' @param model The statistical/machine learning model.
#' @param board The pins board.
#' @param endpoint The S3 endpoint.
#' @param filepath The object file path.
#' @param file_name The file name.
#' @param object_name The S3 object name.
#' @param is_card Whether the object is a model card.
#'
#' @returns The statistical/machine learning model.
#'
#' @export
model_s3_upload <- function(model,
                            board,
                            endpoint,
                            filepath,
                            file_name,
                            object_name,
                            is_card = FALSE) {
  board |>
    pins::pin_upload(here::here(filepath, file_name), object_name)
  
  if (is.null(model$s3_objects)) {
    model$s3_objects <- c()
  }
  
  pin_version <- pins::pin_meta(board, object_name)$local$version
  s3_url <- paste(endpoint,
                  board$bucket,
                  object_name,
                  pin_version,
                  file_name,
                  sep = "/")
  
  if(is_card) {
    model$card <- s3_url
  } else {
    model$s3_objects <- c(model$s3_objects, s3_url)
  }
  model
}