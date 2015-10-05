path = require "path"
common = require "echo-sdk"
seq = common.sequelize


modelList = [
]

exports.configure = (app) ->

	db = common.db(app)

	models = {}

	modelList.forEach (m) =>
		importPath = path.join __dirname, "modules", m.module, "orm", "#{m.model}"
		console.log "Loading : #{importPath}"
		models[m.model] = db.import importPath

	app.set("orm", models)
	app.set("db", db)