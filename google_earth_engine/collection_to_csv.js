/*
NOA-Beyond Earth Observation Utilities
Google Earth Engine scripts for common operation
Original Author: Dimitris Bormpoudakis
*/

var polygons = ee.FeatureCollection("projects/ee-bormpd/assets/Parcelaire_edit");
var bounds = polygons.geometry().bounds();

/**
 * Function to mask clouds using the Sentinel-2 QA band
 * @param {ee.Image} image Sentinel-2 image
 * @return {ee.Image} cloud masked Sentinel-2 image
 */
function maskS2clouds(image) {
  var qa = image.select('QA60');

  // Bits 10 and 11 are clouds and cirrus, respectively.
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;

  // Both flags should be set to zero, indicating clear conditions.
  var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
      .and(qa.bitwiseAnd(cirrusBitMask).eq(0));
  return image.updateMask(mask).divide(10000).copyProperties(image, ['system:time_start']);
  }

var collection = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterDate('2015-01-01', '2018-01-01')
  // Pre-filter to get less cloudy granules.
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10))
  .filterBounds(bounds)
  .map(maskS2clouds)
  .map(function(raster) {
    // Calculate clrededge using the formula: clrededge = (NIR/REDEDGE)−1
    var clrededge = raster.expression(
      '(NIR / RE) - 1', {
        'NIR': raster.select('B7'), // NIR band
        'RE': raster.select('B5'), // RE band
      }).rename("ClRE");
    
    // Calculate MCARI using the formula: mcari = ((B05 - B04) - 0.2 * (B05 - B03)) * (B05 / B04);
    var mcari = raster.expression(
      '((RE - RED) - 0.2 * (RE - GREEN)) * (RE/RED)', {
        'RED': raster.select('B4'), // RED band
        'RE': raster.select('B5'), // RE band
        'GREEN': raster.select('B3'), // GREEN band
      }).rename("MCARI");
      
   // Calculate PSRI using the formula: psri = (B04 - B02)/B06
    var psri = raster.expression(
      '(RED - BLUE)/RRE', {
        'RED': raster.select('B4'), // RED band
        'RRE': raster.select('B6'), // RRE band
        'BLUE': raster.select('B2'), // BLUE band
      }).rename("PSRI");
    
   // Calculate SAVI using the formula: savi = (B8 - B4)/(B8 + B4 + L) * (1+L)
    var savi = raster.expression(
      '(RRRE - RED) / (RRRE + RED + 0.5) * 1.5', {
        'RED': raster.select('B4'), // RED band
        'RRRE': raster.select('B8'), // RRRE band
      }).rename("SAVI");
      
      
    var acquisition = raster.date().format("YYYY-MM-dd");
      raster = raster.set("acquisition", acquisition);
      raster = raster.addBands(clrededge);
      raster = raster.addBands(mcari);
      raster = raster.addBands(psri);
      raster = raster.addBands(savi);
      return raster;
  });

var acquisitions = collection.aggregate_array("acquisition").distinct().sort();
var clrededges = collection.select("ClRE");
var mcaris = collection.select("MCARI");
var psris = collection.select("PSRI");
var savis = collection.select("SAVI");


clrededges = clrededges.toList(clrededges.size());
mcaris = mcaris.toList(mcaris.size());
psris = psris.toList(psris.size());
savis = savis.toList(savis.size());


print(collection); // Print the collection to check if the error persists

// clrededge
var values = clrededges.map(function(clrededge){
  clrededge = ee.Image(clrededge);
  var geometry = clrededge.geometry();
  var overlappingPolygons = polygons.filterBounds(geometry);

  var features = clrededge.reduceRegions({
    collection: overlappingPolygons,
    reducer: ee.Reducer.median(),
    scale: 30
  });

  features = features.map(function(feature){
    return feature.set("acquisition", clrededge.getString("acquisition"));
  });

  return features;
});

var result = ee.FeatureCollection(values).flatten();

// mcari
var values_mcari = mcaris.map(function(mcari){
  mcari = ee.Image(mcari);
  var geometry = mcari.geometry();
  var overlappingPolygons = polygons.filterBounds(geometry);

  var features = mcari.reduceRegions({
    collection: overlappingPolygons,
    reducer: ee.Reducer.median(),
    scale: 30
  });

  features = features.map(function(feature){
    return feature.set("acquisition", mcari.getString("acquisition"));
  });

  return features;
});

var result_mcari = ee.FeatureCollection(values_mcari).flatten();

// psri
var values_psri = psris.map(function(psri){
  psri = ee.Image(psri);
  var geometry = psri.geometry();
  var overlappingPolygons = polygons.filterBounds(geometry);

  var features = psri.reduceRegions({
    collection: overlappingPolygons,
    reducer: ee.Reducer.median(),
    scale: 30
  });

  features = features.map(function(feature){
    return feature.set("acquisition", psri.getString("acquisition"));
  });

  return features;
});

var result_psri = ee.FeatureCollection(values_psri).flatten();

// savi
var values_savi = savis.map(function(savi){
  savi = ee.Image(savi);
  var geometry = savi.geometry();
  var overlappingPolygons = polygons.filterBounds(geometry);

  var features = savi.reduceRegions({
    collection: overlappingPolygons,
    reducer: ee.Reducer.median(),
    scale: 30
  });

  features = features.map(function(feature){
    return feature.set("acquisition", savi.getString("acquisition"));
  });

  return features;
});

var result_savi = ee.FeatureCollection(values_savi).flatten();


print("*counts*");
print("clrededges:", clrededges.size());
print("mcaris:", mcaris.size());
print("psris:", psris.size());
print("acquisitions:", acquisitions);

print(result.aggregate_array("acquisition").sort());
print(polygons);
print(result);

Map.centerObject(polygons);

Map.addLayer(bounds, {color: "white"}, "polygons bounds");
Map.addLayer(polygons, {color: "black"}, "polygons polygons");



Export.table.toDrive({
  collection: result,
  description:"Sentinel_France_clrededge",
  fileFormat: "CSV",
  selectors: ["id2", "acquisition", "median", /*".geo"*/]
});

Export.table.toDrive({
  collection: result_mcari,
  description:"Sentinel_France_mcari",
  fileFormat: "CSV",
  selectors: ["id2", "acquisition", "median", /*".geo"*/]
});

Export.table.toDrive({
  collection: result_psri,
  description:"Sentinel_France_psri",
  fileFormat: "CSV",
  selectors: ["id2", "acquisition", "median", /*".geo"*/]
});

Export.table.toDrive({
  collection: result_savi,
  description:"Sentinel_France_savi",
  fileFormat: "CSV",
  selectors: ["id2", "acquisition", "median", /*".geo"*/]
});
