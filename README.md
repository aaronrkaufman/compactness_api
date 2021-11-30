# compactness_api
plumber run to host the Kaufman, King, & Komisarchik legislative district compactness API

To run this API, use the following CURL command:
curl -X POST --form shp=@[name_of_shapefile.shp] --form shx=@[name_of_shapefile.shx] --form dbf=@[name_of_shapefile.dbf] --form prj=@[name_of_shapefile.prj] --form namecol=["identifier_column_name_in_quotes"] https://compactness.herokuapp.com/api/compact 

For example, download the evenlyspaced20_v2 shapefiles (.shp, .shx, .dbf, .prj), open your terminal in the same directory as those files, and enter:
curl -X POST --form shp=@evenlyspaced20_v2.shp --form shx=@evenlyspaced20_v2.shx --form dbf=@evenlyspaced20_v2.dbf --form prj=@evenlyspaced20_v2.prj --form namecol="GEOID" https://compactness.herokuapp.com/api/compact 

