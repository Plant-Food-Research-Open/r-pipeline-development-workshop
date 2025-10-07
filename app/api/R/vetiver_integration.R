vetiver_create_description.int_conformal_split <- function(model) {
  "A conformalised machine learning model."
}

vetiver_ptype.int_conformal_split <- function(model, ...) {
  vctrs::vec_ptype(model$training)
}

predict.int_conformal_split <- function(object, new_data, level = 0.95, ...) {
  rlang::check_dots_empty()
  
  new_pred <- predict(object$wflow, new_data)
  
  alpha <- 1 - level
  q_ind <- ceiling(level * (object$n + 1))
  q_val <- object$resid[q_ind]
  
  new_pred$.pred_lower <- new_pred$.pred - q_val
  new_pred$.pred_upper <- new_pred$.pred + q_val
  new_pred
}

handler_predict.int_conformal_split <- function(vetiver_model, ...) {
  ptype <- vetiver_model$prototype
  
  function(req) {
    newdata <- req$body
    newdata <- vetiver::vetiver_type_convert(newdata, ptype)
    newdata <- hardhat::scream(newdata, ptype)
    ret <- predict(vetiver_model$model, new_data = newdata, ...)
    list(.pred = ret)
  }
  
}

vetiver_create_meta.int_conformal_split <-
  function(model, metadata) {
    vetiver::vetiver_meta(metadata,
                          required_pkgs = c("probably", "workflows", "stacks", "workflowsets"))
  }

vetiver_create_description.brmsfit <- function(model) {
  "A brms Bayesian model."
}

vetiver_create_meta.brmsfit <- function(model, metadata) {
  vetiver::vetiver_meta(metadata, required_pkgs = "brms")
}

vetiver_ptype.brmsfit <- function(model, ...) {
  vctrs::vec_ptype(model$training)
}

handler_predict.brmsfit <- function(vetiver_model, ...) {
  ptype <- vetiver_model$prototype
  
  function(req) {
    newdata <- req$body
    newdata <- vetiver::vetiver_type_convert(newdata, ptype)
    newdata <- hardhat::scream(newdata, ptype)
    ret <- predict(vetiver_model$model, newdata = newdata, ndraws = 50, ...)
    
    list(.pred = list(
      list(
        .pred = ret[, "Estimate"] |> mean(),
        .pred_lower = ret[, "Q2.5"] |> mean(),
        .pred_upper = ret[, "Q97.5"] |> mean()
      )
    ))
  }
  
}

predict.cmdstanr_container <- function(model, new_data) {
  data <- list()
  variable_names <- model$model$variables()$data |>
    names()
  
  for (variable_name in variable_names) {
    if (variable_name == "N") {
      data["N"] <- nrow(new_data)
    } else {
      data[[variable_name]] <- new_data[[variable_name]]
      indx_var <- paste0(variable_name, "_J")
      if (indx_var %in% variable_names) {
        data[[indx_var]] <- model$data[[indx_var]]
      }
    }
  }
  
  model$model$generate_quantities(model$fit, data = data)$summary() |> dplyr::select(-variable)
}

vetiver_create_description.cmdstanr_container <- function(model) {
  "A cmdstanr Bayesian model."
}

vetiver_create_meta.cmdstanr_container <- function(model, metadata) {
  vetiver::vetiver_meta(metadata, required_pkgs = "cmdstanr")
}

vetiver_ptype.cmdstanr_container <- function(model, ...) {
  vctrs::vec_ptype(model$training)
}

handler_predict.cmdstanr_container <- function(vetiver_model, ...) {
  ptype <- vetiver_model$prototype
  
  function(req) {
    newdata <- req$body
    newdata <- vetiver::vetiver_type_convert(newdata, ptype)
    newdata <- hardhat::scream(newdata, ptype)
    ret <- predict(vetiver_model$model, new_data = newdata, ...)
    list(
      .pred = ret[, "mean"],
      "sd" = ret[, "sd"],
      "q5" = ret[, "q5"],
      "q95" = ret[, "q95"]
    )
  }
  
}
