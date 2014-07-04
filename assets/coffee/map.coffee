# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Jul-2014
# Last mod : 04-Jul-2014
# -----------------------------------------------------------------------------
window.microcreditDRC = {} unless window.microcreditDRC?
# -----------------------------------------------------------------------------
#
#    AFRICA MAP
#
# -----------------------------------------------------------------------------
class microcreditDRC.AfricaMap
	
	CONFIG = settings.map

	constructor: () ->
		@ui = $(".africa-container")
		@svg = d3.select(".africa-container")
			.insert("svg" , ":first-child")
		@group        = @svg.append("g")
		@groupPaths   = @group.append("g").attr("class", "all-path")
		@groupSymbols = @group.append("g").attr("class", "all-symbols")
		# load data
		q = queue()
		q.defer(d3.json, CONFIG.urls.geojson)
		q.await(@loadedDataCallback)
	
	loadedDataCallback: (error, geojson) =>
		@countries = topojson.feature(geojson, geojson.objects.Africa1).features
		@relayout()
		# Bind events
		$(window).resize @relayout

	relayout: =>
		# compute size
		@width  = @ui.width()
		@height = $(window).height() - @ui.offset().top
		@svg
			.attr("width" , @width)
			.attr("height", @height)
		@ui.css
			width : @width
			height: @height
		# Create projection
		@projection = d3.geo.mercator()
			.scale(1)
			.translate([0,0])
		b = [@projection(CONFIG.africa_bounds[0]), @projection(CONFIG.africa_bounds[1])]
		w = (b[1][0] - b[0][0]) / @width
		h = (b[1][1] - b[0][1]) / @height
		s =  .95 / Math.max(Math.abs(w), Math.abs(h))
		t = [-s * b[0][0], (@height - s * (b[1][1] + b[0][1])) / 2]
		@projection
			.scale(s)
			.translate(t)
		# Create the path
		@path = d3.geo.path().projection(@projection)
		@groupPaths.selectAll("path").remove()
		@groupPaths.selectAll("path")
			.data(@countries)
			.enter()
				.append("path")
				.attr("d", @path)

# EOF
