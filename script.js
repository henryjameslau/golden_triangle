const Fs = require('fs');
const Turf = require('turf');
// const D3Dsv = require('d3-dsv');
let eastMidlands = JSON.parse(Fs.readFileSync('./processed/east_midlands.geojson'))
grid = JSON.parse(Fs.readFileSync('./data/grid.geojson'))

console.log(grid.features[0].properties)
grid.features.map(d => d.properties.band1 = +d.properties.band1)

centroids = grid.features.map(function(d) {
  var point = Turf.polygon(d.geometry.coordinates)
  return Turf.centroid(point, d.properties)
})
console.log(centroids[0])

let totalPop = grid.features.reduce(function(prev, curr) {
  return prev = (+prev) + (+curr.properties.band1)
}, 0)
console.log(totalPop)


// Loop through all the isochrones

// and then loop through all the points to see which centroids are in that isochrones
for (i = 0; i < centroids.length; i++) {
  // add up the population along the way

}
