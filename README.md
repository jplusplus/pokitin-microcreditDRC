Map of microfinance in the DR Congo
===================================

http://jplusplus.github.io/pokitin-microcreditDRC/

Note to developer : http://jplusplus.github.io/pokitin-microcreditDRC/embedded.html

compiled archive : https://github.com/jplusplus/pokitin-microcreditDRC/archive/gh-pages.zip

## Commands

### Install

	make install

Will install python dependances with pip in a virtualenv and nodejs dependances with npm in the directory node_modules

### Run the Web Application

	make run

### Generate the Static Files

	make freeze BASE_URL="http://jplusplus.github.io/pokitin-microcreditDRC/"

Will greate a `build` folder with the static files inside

### Update the I18n Files

	make update_i18n

### Compile the I18n Files

	make compile_i18n
