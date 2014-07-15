# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Jul-2014
# Last mod : 14-Jul-2014
# -----------------------------------------------------------------------------
window.microcreditDRC = {} unless window.microcreditDRC?
# -----------------------------------------------------------------------------
#
#    AFRICA MAP
#
# -----------------------------------------------------------------------------
class microcreditDRC.AfricaMap extends serious.Widget

	CONFIG = microcreditDRC.settings.map

	constructor: ->
		@ready = false
		@data  =
			africa     : undefined
			geocoded   : undefined
			kivus      : undefined
			geojson    : undefined
		# load data
		q = queue()
		for data_name, data_file of CONFIG.data
			do (data_file) ->
				if data_file.indexOf(".json") > -1
					q.defer(d3.json, data_file)
				else if data_file.indexOf(".csv") > -1
					q.defer(d3.csv, data_file)
		q.awaitAll(@dataLoaded)

	bindUI: (ui) =>
		@container = $(".africa-container", ui)
		@svg = d3.select(".africa-container")
			.insert("svg" , ":first-child")
		@group        = @svg.append("g")
		@groupPaths   = @group.append("g").attr("class", "all-path")
		@groupSymbols = @group.append("g").attr("class", "all-symbols")

	# save data and start the map
	dataLoaded: (errors, results) =>
		for data_name, i in _.keys(CONFIG.data)
			@data[data_name] = results[i]
		@countries = topojson.feature(@data.geojson, @data.geojson.objects.Africa1).features
		@relayout()
		# Bind events
		$(window).resize _.debounce(@relayout, 300)
		@ready = true

	relayout: =>
		# compute size
		@width  = @container.width()
		@height = $(window).height() - @container.offset().top - 67
		@svg
			.attr("width" , @width)
			.attr("height", @height)
		# Create projection
		@projection = d3.geo.mercator()
			.scale(1)
			.translate([0,0])
		b = [@projection(CONFIG.africa_bounds[0]), @projection(CONFIG.africa_bounds[1])]
		w = (b[1][0] - b[0][0]) / @width
		h = (b[1][1] - b[0][1]) / @height
		s = .95 / Math.max(Math.abs(w), Math.abs(h))
		left_offset = @width - (s * (b[1][0] - b[0][0])) # align right
		t = [-s * b[0][0] + left_offset, (@height - s * (b[1][1] + b[0][1])) / 2]
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
		@setStory(@story) if @story

	setStory: (story) =>
		# wait data
		return setTimeout((=> @setStory(story)), 100) unless @ready
		@story = story
		# detect the type of map
		switch story.display
			when "choropleth"
				@renderChoropleth(story)
			when "bubble"
				@renderBubble(story)

	renderChoropleth: (story) =>
		# prepare data
		data_story = @data[story.data]
		keys       = data_story.map((l)-> l.country)
		values     = data_story.map((l)-> parseFloat(l.gross_loans))
		countries  = _.object(keys, values)
		# color scale
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(CONFIG.color_scale).domain(domain, 10)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) -> # color countries using the color scale
				# mode highlight : color only the highlighted countries
				# otherwise      : color all the countries with data
				if countries[d.properties.Name]?
					if (story.highlight? and d.properties.Name in story.highlight) \
					or not story.highlight?
						return scale(countries[d.properties.Name]).hex()
				return "#BEBEBE"
		@groupPaths.selectAll('path').each (d) ->
			if countries[d.properties.Name]?
				$(this).qtip
					# show the tooltip if the country name is in story.tooltip
					show : if story.tooltip? and d.properties.Name in story.tooltip then true else undefined
					content :
						text: "#{d.properties.Name}<br/><strong>#{countries[d.properties.Name]}</strong>"

	renderBubble: (story) =>
		# TODO

# EOF
