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
library(uuid)
library(sf)

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
#* @param shp The shp file
#* @param dbf The dbf file
#* @param shx The shx file
#* @param prj The projection file
#* @param namecol A string denoting the identifier column
#* @post /compact
#* @serializer json
function(req) {
  tmp = Rook::Multipart$parse(req)
  #print(str(tmp))

  fn = uuid::UUIDgenerate()
  
  shx1 = tmp$shx$tempfile
  shp1 = tmp$shp$tempfile
  dbf1 = tmp$dbf$tempfile
  prj1 = tmp$prj$tempfile
  
  ## rename shx1 and shp1
  shx2 = stringr::str_replace(shx1, "Multipart.*", paste0(fn, ".shx"))
  shp2 = stringr::str_replace(shp1, "Multipart.*", paste0(fn, ".shp"))
  dbf2 = stringr::str_replace(dbf1, "Multipart.*", paste0(fn, ".dbf"))
  prj2 = stringr::str_replace(prj1, "Multipart.*", paste0(fn, ".prj"))
  
  file.rename(shx1, shx2)
  file.rename(shp1, shp2)
  file.rename(dbf1, dbf2)
  file.rename(prj1, prj2)
  
  #shp = tmp$data$tempfile
  namecol = tmp$namecol
  print(namecol)
  
  if(is.null(tmp$returnfile)){
    returnFile=FALSE
  } else if(toupper(tmp$returnfile) %in% c("F", "FALSE")){
    returnFile = FALSE
  } else{
    returnFile = TRUE
  }
  
  #print(shp)
  #print(shp$data$filename)
  #namecol = "GEOID"
  shp3 = read_shapefiles(shp = shp2, namecol = namecol)
  feats = generate_features(shp3)
  idx = apply(feats, 2, FUN=function(x) any(is.na(x)))
  feats = feats[,!idx]
  preds = generate_predictions(features=feats, namecol = namecol)
  if(returnFile == FALSE){
    list(preds)
  } else {
    as_attachment(preds, "preds.csv") # https://www.rplumber.io/reference/as_attachment.html
  }
}


## to post:
## curl -X POST --form shp=@D:/Github/compactness_api/evenlyspaced20_v2.shp --form shx=@D:/Github/compactness_api/evenlyspaced20_v2.shx --form dbf=@D:/Github/compactness_api/evenlyspaced20_v2.dbf --form prj=@D:/Github/compactness_api/evenlyspaced20_v2.prj--form namecol="district" https://compactness.herokuapp.com/api/compact
## curl -X POST --form shp=@D:/Github/compactness_api/evenlyspaced20_v2.shp --form shx=@D:/Github/compactness_api/evenlyspaced20_v2.shx --form dbf=@D:/Github/compactness_api/evenlyspaced20_v2.dbf --form prj=@D:/Github/compactness_api/evenlyspaced20_v2.prj --form namecol="GEOID" http://localhost:7571/compact
## to check logs: https://dashboard.heroku.com/apps/compactness/logs


#test = read_shapefiles("D:/Github/compactness_api/evenlyspaced20_v2.shp", namecol="GEOID")
#test = read_shapefiles("C:/Users/inter/AppData/Local/Temp/RtmpIDcwt7/evenlyspaced20_v2.shp", namecol="GEOID")


## Changes to make:
#1) Add a param decorator to the method: '#* @param shp:file'?
#2) There is no filename (probably). You need to generate filename
#    in the API that is random so people don't overwrite each other.
#    Then, write to that file using $shp[1] (data uploaded) -- uuid library