# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 02-Jul-2014
# Last mod : 14-Jul-2014
# -----------------------------------------------------------------------------
# This file is part of microcreditDRC.
# 
#     microcreditDRC is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     microcreditDRC is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with microcreditDRC.  If not, see <http://www.gnu.org/licenses/>.

window.microcreditDRC = {} unless window.microcreditDRC?

class microcreditDRC.Navigation extends serious.Widget

	bindUI: =>
		@currentStory    = 0
		@data            = {}
		@africaMapWidget = serious.Widget.ensureWidget($(".widget.navigation"))
		@storyWidget     = serious.Widget.ensureWidget($(".widget.story"))
		# load data
		q = queue()
		for data_name, data_file of microcreditDRC.settings.data
			do (data_file) ->
				if data_file.indexOf(".json") > -1
					q.defer(d3.json, data_file)
				else if data_file.indexOf(".csv") > -1
					q.defer(d3.csv, data_file)
		q.awaitAll(@dataLoaded)

	dataLoaded: (errors, results) =>
		for data_name, i in _.keys(microcreditDRC.settings.data)
			@data[data_name] = results[i]
		@start()

	start:     => @showStory()

	showStory: => @storyWidget.setStory(@currentStory)

	next: =>
		@currentStory += 1 if @currentStory < @data.storyboard.length
		@showStory()

	previous: =>
		@currentStory -= 1 if @currentStory > 0
		@showStory()

# EOF
