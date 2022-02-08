fx_version 'adamant'

game 'gta5'

description 'ESX Konbini'

version 'legacy'

shared_script '@es_extended/imports.lua'

server_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/fr.lua',
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/client/wrapper.lua',
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/fr.lua',
	'config.lua',
	'client/main.lua'
}

ui_page 'html/ui.html'

files {
	'html/ui.html',
	'html/css/elera.css',
	'html/roboto.ttf',
	'html/Pixolletta8px.ttf',
	'html/img/logo_store.png',
	'html/img/*_x64.png',
	'html/js/elera.js',
}

dependency 'es_extended'
