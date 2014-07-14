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

	data :
		storyboard : "static/data/storyboard.json"
		africa     : "static/data/microfinance_africa.csv"
		geocoded   : "static/data/microfinance_geocoded.csv"
		kivus      : "static/data/microfinance_kivus.csv"

	map:
		geojson       : "static/africa.topo.json"
		africa_bounds : [[-20.2,-37.3],[54.3,39.0]]

# EOF
