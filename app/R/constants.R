model_choices <- Sys.getenv("MODEL_CHOICES", "random_forest,gompertz") |>
  strsplit(",") |>
  unlist()

model_endpoints <- Sys.getenv("MODEL_ENDPOINTS", "http://127.0.0.1:8088,http://127.0.0.1:8089") |>
  strsplit(",") |>
  unlist()
