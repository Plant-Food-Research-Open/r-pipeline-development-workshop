#' Create description for the brms Stan model.
#'
#' @param model The brms Stan model.
#'
#' @return The model description.
#' @export
vetiver_create_description.brmsfit <- function(model) {
  "A brms Bayesian model."
}

#' Create metadata for the brms Stan model.
#'
#' @param model The brms Stan model.
#' @param metadata The model metadata.
#'
#' @return Vetiver model metadata.
#' @export
vetiver_create_meta.brmsfit <- function(model, metadata) {
  vetiver::vetiver_meta(metadata, required_pkgs = "brms")
}

#' Determine the vector data types.
#'
#' @param model The brms Stan model.
#' @param ... Additional arguments.
#'
#' @return The vector data types.
#' @export
vetiver_ptype.brmsfit <- function(model, ...) {
  vctrs::vec_ptype(model$training)
}

#' Make predictions with the brms Stan model.
#'
#' @param vetiver_model The brms Stan model.
#' @param ... Additional arguments.
#'
#' @return The model predictions.
#' @export
handler_predict.brmsfit <- function(vetiver_model, ...) {
  ptype <- vetiver_model$prototype
  
  function(req) {
    newdata <- req$body
    newdata <- vetiver::vetiver_type_convert(newdata, ptype)
    newdata <- hardhat::scream(newdata, ptype)
    ret <- predict(vetiver_model$model, new_data = newdata, ndraws = 50, ...)
    
    list(.pred = list(
      list(
        .pred = ret[, "Estimate"] |> mean(),
        .pred_lower = ret[, "Q2.5"] |> mean(),
        .pred_upper = ret[, "Q97.5"] |> mean()
      )
    ))
  }
  
}
