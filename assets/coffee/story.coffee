# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 14-Jul-2014
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

class microcreditDRC.Story extends serious.Widget

	bindUI: =>
		@scope.body = ko.observable("")

	setStory: (story_id) =>
		$.get "static/stories/#{story_id}.md", (data) =>
			@scope.body(markdown.toHTML(data))

# EOF
