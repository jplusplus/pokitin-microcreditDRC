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
		# init the scope, visible from template with knockout.js
		@scope.currentStory = ko.observable(0)
		@scope.storyboard   = ko.observable({})
		@scope.hasNext      = ko.computed(@hasNext)
		@scope.hasPrevious  = ko.computed(@hasPrevious)
		@scope.next         = @next
		@scope.previous     = @previous
		# get the instance of other widgets
		@africaMapWidget    = serious.Widget.ensureWidget($(".widget.map"))
		@storyWidget        = serious.Widget.ensureWidget($(".widget.story"))
		# load storyboard
		q = queue().defer(d3.json, microcreditDRC.settings.storyboard)
		q.await(@dataLoaded)

	dataLoaded: (errors, storyboard) =>
		console.error "Error in #{microcreditDRC.settings.storyboard}", errors if errors
		@scope.storyboard(storyboard)
		@showStory()

	showStory: =>
		@africaMapWidget.setStory(@scope.storyboard()[@scope.currentStory()].map)
		@storyWidget.setStory(@scope.currentStory())

	hasNext: =>
		return @scope.currentStory() < @scope.storyboard().length - 1 if @scope.storyboard()

	hasPrevious: =>
		return @scope.currentStory() > 0

	next: =>
		@scope.currentStory(@scope.currentStory() + 1) if @hasNext()
		@showStory()

	previous: =>
		@scope.currentStory(@scope.currentStory() - 1) if @hasPrevious()
		@showStory()

# EOF
