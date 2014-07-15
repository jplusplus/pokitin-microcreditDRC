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
		@UIS = 
			legend : ".legend"
			scale  : ".legend .scale"
		@container    = $(".africa-container", ui)
		@svg          = d3.select(".africa-container").insert("svg" , ":first-child")
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
		scale  = chroma.scale(CONFIG.color_scale).domain(domain, 3)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) -> # color countries using the color scale
				# mode highlight : color only the highlighted countries
				# otherwise      : color all the countries with data
				color = "#BEBEBE"
				if countries[d.properties.Name]?
					if (story.highlight? and d.properties.Name in story.highlight) \
					or not story.highlight?
						color = scale(countries[d.properties.Name]).hex()
				d.color = color
				return color
		@groupPaths.selectAll('path').each (d) ->
			if countries[d.properties.Name]?
				$(this).qtip
					# show the tooltip if the country name is in story.tooltip
					show : if story.tooltip? and d.properties.Name in story.tooltip then true else undefined
					content :
						text: "#{d.properties.Name}<br/><strong>#{countries[d.properties.Name]}</strong>"
		@showLegend(scale)

	renderBubble: (story) =>
		# TODO

	showLegend : (scale) =>
		that = this
		# remove old legend
		@uis.scale.html("")
		# show value legend
		domains       = scale.domain()
		legend_size   = 300
		domains_delta = domains[domains.length - 1] - domains[0]
		offset        = 0
		max_height    = 0
		size_by_value = true
		label_size    = 0
		@uis.legend.css "width", legend_size
		_.each domains, (step, i) ->
			size_by_value = false  if (domains[i] - domains[i - 1]) / domains_delta * legend_size < 20  if i > 0
			return
		rounded_domains   = AfricaMap.smartRound(domains, 0)
		_.each domains, (step, index) ->
			# for each segment, we adding a domain in the legend and a sticker
			if index < domains.length - 1
				delta = domains[index + 1] - step
				color = scale(step)
				label = rounded_domains[index].toString().replace('.', ",")
				# if index == domains.length - 2 and that.stories.get(that.story_selected).infos["append_sign"]?
				# 	label += " #{that.stories.get(that.story_selected).infos["append_sign"]}"
				size  = (if size_by_value then delta / domains_delta * legend_size else legend_size / (domains.length - 1))
				# setting step
				$step = $("<div class='step'></div>")
				$sticker = $("<span class='sticker'></span>").appendTo(that.uis.scale)
				$step.css
					width: size
					"background-color": color.hex()
				# settings ticker
				$sticker.css "left", offset
				if index > 0
					label_size += size
					if label_size < 30
						label = ""
					else
						label_size = 0
					$("<div />").addClass("value").html(label).appendTo $sticker
				else
					$sticker.remove()
				# add hover effect to highlight regions
				select = (e, fix=false) =>
					$(".step").removeClass("active fixed")
					$target = $(e.target)
					$target.addClass("active")
					$target.addClass("fixed") if fix
					step_color = chroma.color($target.css("background-color")).hex()
					opacity    = (path) -> if path.color == step_color then 1 else .2
					that.groupPaths.selectAll("path")
						.attr("opacity", opacity)
						.classed("discret", false)
				deselect = (e, force=false) =>
					$(".step").removeClass("active fixed")
					that.groupPaths.selectAll("path")
						.attr("opacity", 1)
						.classed("discret", (d) -> d.is_discrete)
				$step.add($sticker).hover(select, deselect)
				that.uis.scale.append $step
				offset += size

	#     Rounds a set of unique numbers to the lowest
	#     precision where the values remain unique
	@smartRound = (values, add_precision) ->
		round = (b) ->
			+(b.toFixed(precision))
		result = []
		precision = 0
		nonEqual = true
		loop
			result = _.map(values, round)
			precision++
			break unless _.uniq(result, true).length < values.length
		if add_precision
			precision += add_precision - 1
			result = _.map(values, round)
		result

# EOF
