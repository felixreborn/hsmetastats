
path = require "path"
request = require "request"
serveStatic = require "serve-static"
Multer = require "multer"
swig = require "swig"
bodyParser = require "body-parser"
csrf = require "csurf"
async = require "async"
Hub = require "echo-hub"
EchoError = require("echo-sdk").EchoError

module.exports = (app, done) =>

	###
	Config
	###
	app.get("plugins").mergeConfig app, require "./config"
		
	#form handling
	app.use bodyParser.urlencoded({ extended: false })
	app.use bodyParser.json()

	#swig setup
	app.engine 'swig', swig.renderFile
	app.set 'view engine', 'swig'
	app.set 'views', __dirname + '/modules'
	app.set 'view cache', false
	swig.setDefaults { cache : false }

	#proxy
	app.set 'trust proxy', true
	
	#static files
	app.use Multer({ dest: app.get("config").uploads.path})
	app.use serveStatic path.join __dirname, "public"

	#module middleware container
	app.set 'middleware', {}

	#CSRF
	app.use (err, req, res, next) =>
		#not a CSRF problem? carry on!
		return next(err) if err.code isnt 'EBADCSRFTOKEN'

		#handle CSRF problem..
		res.status 403

		#and do *not* carry on

	#make items available in views
	app.use (req, res, next) ->

		#user agent parsing
		res.locals.ua = require('ua-parser').parseUA(req.headers["user-agent"])

		res.locals.csrf = req.csrfToken() if req.csrfToken?
		res.locals.user = req.user
		res.locals.path = req.path.split("/").pop()
		res.locals.path = "home" if req.path == "/"

		#make organisation available
		res.locals.organisation = req.organisation

		#attempted homebrew effort for flash messages
		Flash = new common.flash(req.session)
		res.locals.flash = Flash.flash
		req.flash = Flash.flash
		next()

	###
	swig filters
	###
	app.set 'swig', swig

	###
	sequelize models (not sure I like this..)
	###
	models = require "./modelloader"
	models.configure app

	###
	Modloader - load in and run any config each module needs
	###
	modloader = require "./modloader"
	modloader.configure app

	###
	404 and 500 pages
	###
	BaseController = new common.controller.BaseController(app)
	
	#404 handling
	app.use (req, res, next) =>
		BaseController.show404 req, res

	#500 handling
	app.use BaseController.handle500
		return done err