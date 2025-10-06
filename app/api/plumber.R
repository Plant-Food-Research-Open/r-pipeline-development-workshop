if(pins::pin_exists(board, Sys.getenv("MODEL_CARD_NAME", "__undefined_model_card__"))) {
  card <- board |>
    pins::pin_download(Sys.getenv("MODEL_CARD_NAME")) |>
    readr::read_file()
} else 
{
  card <- NA
}

#* Get the model card.
#* @get /card
function() {
  loaded_v$model$card
}

#* Get the S3 objects list.
#* @get /s3-objects
function() {
  loaded_v$model$s3_objects
}


#* Get the rendered model card.
#* @serializer html
#* @get /render-card
function() {
  card
}

#* Get the training data.
#* @get /data
function() {
  loaded_v$model$training
}