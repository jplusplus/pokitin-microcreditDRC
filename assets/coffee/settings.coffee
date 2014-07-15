# Encoding: utf-8
# Project : microcreditDRC
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU General Public License
# -----------------------------------------------------------------------------
# Creation : 02-Jul-2014
# Last mod : 02-Jul-2014
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

microcreditDRC.settings =

	storyboard : "static/data/storyboard.json"

	map:
		data :
			microfinance_africa   : "static/data/microfinance_africa.csv"
			microfinance_geocoded : "static/data/microfinance_geocoded.csv"
			microfinance_kivus    : "static/data/microfinance_kivus.csv"
			geojson               : "static/africa.topo.json"
		transition_duration      : 750
		africa_bounds            : [[-20.2,-37.3],[54.3,39.0]]
		default_fill_color       : "#BEBEBE"
		highlighted_fill_color   : "#0080FF"
		choropleth_bucket_number : 4
		choropleth_color_scale   : ['rgb(158,202,225)','rgb(107,174,214)','rgb(66,146,198)','rgb(33,113,181)','rgb(8,69,148)', "#001261"] # http://colorbrewer2.org/?type=sequential&scheme=Blues&n=7
		bubble_default_color     : "#4D4D4D"
		bubble_default_size      : 4
		tooltip_style :
			style: # http://qtip2.com/options#style
				classes : "qtip-dark qtip-tipsy"
				tip:
					corner: false
			position:
				target: 'mouse'
				adjust:
					x:  40
					y: -10 

# EOF
