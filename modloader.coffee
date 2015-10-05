fs = require "fs"
path = require "path"
async = require "async"

#go into the modules directory and include everything in there..
class ModLoader

	_fileList = undefined
	_localdir = undefined

	constructor : (localdir) ->
		@._localdir = __dirname
		@._localdir = localdir if localdir?

	getFiles : () =>
		if !@._fileList?
			@._fileList = fs.readdirSync path.join @._localdir, "modules"
		return @._fileList

	loadControllers : (app) =>
		@._loadItems app, "controllers", "controller"
		
	loadModels : (app) =>
		@._loadItems app, "models", "model"

	_loadItems : (app, type, dirname) =>
		loadPaths = {}
		items = app.get(type)
		if !items?
			items = {}
			app.set(type, items)
		
		files = @.getFiles()
		for f in files 
			file = path.join @._localdir, "modules", f
			stat = fs.statSync file
			if stat.isDirectory()
				itemDir = path.join @._localdir, "modules", f, dirname
				if fs.existsSync itemDir
					itemList = fs.readdirSync itemDir
					itemList.map (c) =>
						cStat = fs.statSync path.join itemDir, c
						c = c.split(".")[0]
						if !items[c]? and c.length > 0 and !cStat.isDirectory()
							itemPath = path.join itemDir, c
							items[c] = {} #load a stub in for now
							loadPaths[c] = itemPath
						else
							console.log "Ignoring #{type} : #{c}"
			
		for key, loadPath of loadPaths
			console.log "Loading : #{key}"
			newObj = new(require loadPath)(app)
			for newKey, newValue of newObj
				items[key][newKey] = newValue #patch stub with methods from newObj

	loadModules : (app) =>
		modules = []
		files = @.getFiles()
		for f in files
			file = path.join @._localdir, "modules", f
			indexFile = path.join file, "index.coffee"
			stat = fs.statSync file
			isDirectory = stat.isDirectory()
			loadFile = fs.existsSync indexFile
			if isDirectory and loadFile
				console.log "Loading : #{file}"
				modules[f] = require file
				try
					modules[f].configure app
				catch error
					console.log "Could not load : #{f}"
					console.log error
					process.exit 1
			else
				if isDirectory and !loadFile
					console.log "Ignoring : #{f} : No load file (index.coffee)"

	#Entry point!
	configure : (app) =>
		@.loadModels app
		@.loadControllers app
		@.loadModules app

module.exports = ModLoader
