
slugify = require './utils/slugify'
cc = require 'coffeecup'
uuid = require 'node-uuid'
gm = require 'gm'
fs = require 'fs'
exec = require('child_process').exec
shellEscape = require './utils/shellEscape'
deepCopy = require('owl-deepcopy').deepCopy
YAML = require('yamljs')
applyContext = require './utils/applyContext'
sessionBridge = require './utils/sessionBridge'
express = require 'express'

# Export Plugin
module.exports = (BasePlugin) ->

    # Define Plugin
    class MinicmsPlugin extends BasePlugin

        # Plugin name
        name: 'minicms'

        config:
            # Some config to change the reserved "values"
            prefix:
                url:    'cms' # The prefix used to load the admin panel
                meta:   'cms' # The key used to store form info in metadata

            # Default validator for all fields
            validate: require './utils/validate'

            # Default sanitizer for all fields
            sanitize: require './utils/sanitize'

        # When dopac is ready, force it to watch files
        docpadReady: (opts) ->
            @docpad.action 'watch', {}, (err) ->
                if err then process.stderr.write ("#{err.message ? err}").trim()+"\n"
                @docpad.log "Force watching file for minicms."


        # Server Extend
        # Used to add our own custom routes to the server before the docpad routes are added
        serverExtend: (opts) ->
            # Extract useful values
            app = opts.server
            console.log "SERVER = "
            console.log app
            docpad = @docpad
            config = @config

            # Reset tmp directory
            exec "rm -rf #{shellEscape docpad.config.srcPath+'/files/tmp'}", ->

            # Serve static files used by minicms
            app.use '/'+@config.prefix.url, express.static(__dirname+'/static')

            if not @config.secret?
                throw "Secret is required for cookie sessions (minicms)"

            # Use session handler
            app.use express.cookieParser()
            app.use express.cookieSession secret: @config.secret

            # Authenticate (logout)
            app.get '/'+@config.prefix.url+'/logout', require('./routes/logout').bind(@)

            # Authenticate (page)
            app.get '/'+@config.prefix.url+'/login', require('./routes/login').bind(@)

            # Authenticate (submit)
            app.post '/'+@config.prefix.url+'/login', require('./routes/loginSubmit').bind(@)

            # Serve admin root
            app.get '/'+@config.prefix.url, require('./routes/root').bind(@)

            # Serve admin content list
            app.get '/'+@config.prefix.url+'/:content/list', require('./routes/list').bind(@)

            # Server admin content edit
            app.get '/'+@config.prefix.url+'/:content/edit', require('./routes/edit').bind(@)

            # Server admin content edit (submit)
            app.post '/'+@config.prefix.url+'/:content/edit', require('./routes/edit').bind(@)

            # Force generate
            app.post '/'+@config.prefix.url+'/generate', require('./routes/generate').bind(@)

            # Handle file upload
            app.post '/'+@config.prefix.url+'/:content/:field/upload', require('./routes/upload').bind(@)

            


















