#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#
# https://github.com/rstudio/plumber/issues/75
# plumber::plumb("plumber.R")$run(port = 4321)
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# 
# cd ./dropbox/compactness shared/compactness
# curl -v -F foo=bar -F upload=@ls.shp http://localhost:4321/echo
#
# I might want to rewrite slightly so that I only need the coordinates

library(plumber)
library(compactness)
library(Rook)
library(textcat)

#* Log system time, request method and HTTP user agent of the incoming request
#* @filter logger
function(req){
  cat("System time:", as.character(Sys.time()), "\n",
      "Request method:", req$REQUEST_METHOD, req$PATH_INFO, "\n",
      "HTTP user agent:", req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
  plumber::forward()
}

# So this works -- maybe I need compact to be post, not get?
# curl -X POST --form 'a=1' https://compactness.herokuapp.com/api/echo
#* @post /echo
function(req){
  list(formContents = Rook::Multipart$parse(req))
}

#* Get compactness
#* @post /compact
#* @serializer json
function(req, returnFile = FALSE) {
  tmp = Rook::Multipart$parse(req)
  shp = tmp$data$filename
  namecol = tmp$namecol
  #print(shp)
  #print(shp$data$filename)
  shp2 = read_shapefiles(shp = shp, namecol = namecol)
  feats = generate_features(shp2)
  preds = generate_predictions(features=feats, namecol = namecol)
  #if(returnFile == FALSE){
  #  list(preds)
  #} else {
  #  as_attachment(preds, "preds.csv") # https://www.rplumber.io/reference/as_attachment.html
  #}
}


## to post:
## curl -X POST --form data=@D:/Github/compactness_api/evenlyspaced20_v2.shp --form namecol=GEOID https://compactness.herokuapp.com/api/compact
## curl -X POST --form data=@D:/Github/compactness_api/evenlyspaced20_v2.shp --form namecol=GEOID http://localhost:6831/compact
## to check logs: https://dashboard.heroku.com/apps/compactness/logs