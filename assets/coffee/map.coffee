# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Jul-2014
# Last mod : 16-Jul-2014
# -----------------------------------------------------------------------------
window.microcreditDRC = {} unless window.microcreditDRC?
# -----------------------------------------------------------------------------
#
#    AFRICA MAP
#
# -----------------------------------------------------------------------------
class microcreditDRC.AfricaMap extends serious.Widget

	CONFIG = microcreditDRC.settings.map

	bindUI: (ui) =>
		@ready = false
		@UIS = 
			legend        : ".legend"
			legend_scale  : ".legend .scale"
			legend_title  : ".legend .title"
			map_container : ".africa-container"
		@svg          = d3.select(".africa-container").insert("svg" , ":first-child")
		@group        = @svg.append("g")
		@groupPaths   = @group.append("g").attr("class", "all-path")
		@groupSymbols = @group.append("g").attr("class", "all-symbols")
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
		@width  = @uis.map_container.width()
		@height = $(window).height() - @uis.map_container.offset().top
		if microcreditDRC.settings.show_navigation
			# FIXME : to be dynamic
			@height -= 67
		@uis.map_container.css("height", @height)
		@svg
			.attr("width" , @width)
			.attr("height", @height)
		# Create projection
		@projection = d3.geo.mercator()
			.scale(1)
			.translate([0,0])
		b = [@projection(CONFIG.africa_bounds[0]), @projection(CONFIG.africa_bounds[1])]
		w = (b[1][0] - b[0][0]) / @width
		h = (b[1][1] - b[0][1]) / (@height - 46) # 46 height of legend
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

	computeZoom: (story) =>
		scale    = 1
		offset_y = 0
		offset_x = 0
		if story.zoom?
			scale     = story.zoom.scale
			center    = @projection(story.zoom.center)
			offset_x  = - (center[0] * scale - @width / 2)
			offset_y  = - (center[1] * scale - @height / 2)
		return {offset_x: offset_x, offset_y: offset_y, scale:scale}

	computeZoomTranslation: (story) =>
		trans = @computeZoom(story)
		### Return the translation instruction as string ex: "translate(1,2)scale(1)"" ###
		transformation = "translate(#{trans.offset_x},#{trans.offset_y})scale(#{trans.scale})"
		return transformation

	setStory: (story) =>
		# wait data
		return setTimeout((=> @setStory(story)), 100) unless @ready
		# reset map
		@groupPaths.selectAll('path')
			.attr 'fill', CONFIG.default_fill_color
		# remove circle only if the dataset has been changed
		@groupSymbols.selectAll("circle").remove() if @story? and @story.data != story.data
		# reset tooltip, destroy everything
		$("circle").qtip('destroy', true)
		$("path") .qtip('destroy', true)
		# reset force
		@force.stop() if @force
		# reset legend
		@uis.legend_scale.html("")
		@uis.legend_title.html("")
		$("g.scale", @ui).remove()
		# reset map
		@groupPaths.selectAll('path')
			.classed "choropleth", false
			.classed "discret", (d) ->
				d.is_discret = false
				if story.map_highlight?
					if not (story.map_highlight? and d.properties.Name in story.map_highlight)
						d.is_discret = true
				return d.is_discret
			# make a zoom
			.transition().duration(CONFIG.transition_duration)
				.attr("transform", @computeZoomTranslation(story))
		@story = story
		if story.legend?
			@uis.legend_title.html(story.legend)
		# detect the type of map
		switch story.display
			when "choropleth"
				@renderChoropleth(story)
			when "bubble"
				@renderBubble(story)
		$("body").removeClass("loading")

	renderChoropleth: (story) =>
		that = this
		# prepare data
		data_story = @data[story.data]
		keys       = data_story.map((l)-> l.country)
		values     = data_story.map((l)-> parseFloat(l.gross_loans))
		countries  = _.object(keys, values)
		# color scale
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(CONFIG.choropleth_color_scale).domain(values, CONFIG.choropleth_bucket_number, CONFIG.choropleth_type_scale)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) -> # color countries using the color scale
				color = scale(countries[d.properties.Name]).hex()
				# save color in element properties
				d.color = color
				return color
			.classed "choropleth", true
			.classed "has-data", (d) ->
				d.has_data = false
				if countries[d.properties.Name]?
					d.has_data = true
				return d.has_data
		# tooltip
		@groupPaths.selectAll('path').each (d) ->
			self = this
			if countries[d.properties.Name]?
				country_name = data_story.filter((c)-> c.country == d.properties.Name)[0].pays
				params = 
					# show the tooltip if the country name is in story.tooltip
					show     : if story.tooltip? and d.properties.Name in story.tooltip then true else undefined
					position : if story.tooltip? and d.properties.Name in story.tooltip then {target: d3.select(d), adjust: {x:-50, y:-30}} else undefined
					content  :
						text: "#{country_name}<br/><strong>#{d3.format(".4s")(countries[d.properties.Name]).replace("M", " millions").replace("G", " millards")}</strong>"
				do (self, params) ->
					setTimeout((-> $(self).qtip _.defaults(params, CONFIG.tooltip_style)), CONFIG.transition_duration)
		# /------ LEGEND 
		# remove old legend
		@uis.legend_scale.html("")
		# show value legend
		domains       = scale.domain()
		legend_size   = Math.min(CONFIG.legend_max_width, @width)
		domains_delta = domains[domains.length - 1] - domains[0]
		offset        = 0
		max_height    = 0
		size_by_value = true
		label_size    = 0
		@uis.legend.css "width", legend_size
		_.each domains, (step, i) ->
			size_by_value = false  if (domains[i] - domains[i - 1]) / domains_delta * legend_size < 20  if i > 0
			return
		rounded_domains   = microcreditDRC.Utils.smartRound(domains, 0)
		_.each domains, (step, index) ->
			# for each segment, we adding a domain in the legend and a sticker
			if index < domains.length - 1
				delta = domains[index + 1] - step
				color = scale(step)
				label = d3.format(".1s")(rounded_domains[index].toString().replace('.', ","))
				size  = (if size_by_value then delta / domains_delta * legend_size else legend_size / (domains.length - 1))
				# size = delta / domains_delta * legend_size
				# setting step
				$step = $("<div class='step'></div>")
				$sticker = $("<span class='sticker'></span>").appendTo(that.uis.legend_scale)
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
					$(".step", @ui).removeClass("active fixed")
					$target = $(e.target)
					$target.addClass("active")
					$target.addClass("fixed") if fix
					step_color = chroma.color($target.css("background-color")).hex()
					that.groupPaths.selectAll("path")
						.classed("discret", ((path) -> return path.color != step_color))
				deselect = (e, force=false) =>
					$(".step").removeClass("active fixed")
					that.groupPaths.selectAll("path")
						.classed("discret", ((d) -> return d.is_discret))
				$step.add($sticker).hover(select, deselect)
				that.uis.legend_scale.append $step
				offset += size

	renderBubble: (story) =>
		that = this
		data_story = @data[story.data]
		trans = that.computeZoom(story)
		# prepare data
		data_story = data_story.filter((d) -> !!d.longitude and !!d.latitude) # remove ungeolocated points
		data_story = data_story.filter((d) -> !story.value? or  !!d[story.value]) # remove points without data associated
		# scale
		if story.value?
			values = data_story.map((l)-> parseFloat(l[story.value]))
			scale  = d3.scale.linear()
				.domain([Math.min.apply(Math, values), Math.max.apply(Math, values)])
				.range(CONFIG.bubble_size_range)
		# update data
		for line in data_story
			coord       = @projection([line.longitude, line.latitude])
			line.gx     = coord[0]
			line.gy     = coord[1]
			line.x = line.gx unless line.x?
			line.y = line.gy unless line.y?
			line.radius = CONFIG.bubble_default_size
			if scale? and story.value?
				line.radius = scale(line[story.value])
		# color map
		if story.map_highlight
			@groupPaths.selectAll('path')
				.attr 'fill', (d) ->
					if d.properties.Name in story.map_highlight
						return CONFIG.highlighted_fill_color
					else
						return CONFIG.default_fill_color
		# positioning with the Force
		@force = d3.layout.force()
			.nodes(data_story)
			.gravity(0)
			.charge(0)
			.size([@width, @height])
			.on "tick", (e) ->
				that.groupSymbols.selectAll("circle")
					.each(microcreditDRC.Utils.collide(data_story, e.alpha))
					.attr 'transform', (d)->
						transformation = ""
						transformation += that.computeZoomTranslation(story)
						transformation += "translate(#{d.x}, #{d.y})"
						# transformation += "scale(#{1/story.zoom.scale})" if story.zoom?
						return transformation
		# put cirlce on the map
		@symbol = @groupSymbols.selectAll("circle").data(data_story)
		@symbol.enter()
			.append("circle", ".all-symbols")
				.attr("stroke", CONFIG.bubble_default_border_color)
				.attr("stroke-width", CONFIG.bubble_default_size * 0.1)
				.attr("r", 0)
		@symbol.exit().remove()
		# set circles properties
		@groupSymbols.selectAll("circle")
			.transition().duration(CONFIG.transition_duration)
				.attr "fill", (d) ->
					color = CONFIG.bubble_default_color
					if story.bubble_highlight? and d[story.bubble_highlight_property or story.name] in story.bubble_highlight
						color = CONFIG.bubble_highlighted_color
					return color
				.attr "r", ((d)-> d.radius)
		# active the Force
		@force.start()
		# tooltip
		@groupSymbols.selectAll('circle').each (d) ->
			legend_text = "#{d[story.name]}"
			if !!story.value
				legend_text += "<br><strong>#{d3.format(".4s")(d[story.value])}</strong>"
			params =
				content :
					text : legend_text
			$(this).qtip _.defaults(params, CONFIG.tooltip_style)
		# legend
		if story.value?
			legend = @groupPaths.append("g")
				.attr("class", "scale")
				.attr("transform", "translate(" + (@width - 80) + "," + (@height - @uis.legend.height()) + ")")
				.selectAll("g")
					.data([Math.max.apply(Math, values), Math.min.apply(Math, values)])
				.enter().append("g")
			legend.append("circle")
				.attr("cy", ((d) -> return -scale(d) * trans.scale))
				.attr("fill", CONFIG.bubble_default_color)
				.attr("stroke-width", 1)
				.attr("stroke", CONFIG.bubble_default_border_color)
				.attr "r", (d) -> return scale(d) * trans.scale
			padding = 5
			text = legend.append("text")
				.attr("y", ((d) -> return -2 * scale(d) * trans.scale))
				.attr("x", ((d) -> return scale(d) * trans.scale + padding))
				.attr("dy", "1em")
				.attr("fill", microcreditDRC.settings.background_color)
				.text(d3.format(".2s"))
			rect = legend.insert("rect", ":first-child")
				.attr("x", ((d) -> return scale(d) * trans.scale + padding))
				.attr("y", ((d) -> return -2 * scale(d) * trans.scale))
				.attr("width",  (d) -> d3.select(d3.select(this)[0][0].parentNode).select("text").node().getBBox().width )
				.attr("height", (d) -> d3.select(d3.select(this)[0][0].parentNode).select("text").node().getBBox().height)
				.style("fill", microcreditDRC.settings.text_color)

# EOF
