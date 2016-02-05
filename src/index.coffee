app      = require('express')()
http     = require('http').Server(app)
email    = require("emailjs/email")
nedb     = require('nedb')
inquirer = require("inquirer")
bluebird = require("bluebird")

# CORS allow all
app.use(require('cors')())

# Config db
db = new nedb({ filename: 'pipemail_config', autoload: true });

db.find({}, (err, entries) ->
  
  # Ask for config
  if entries.length is 0
    askConfig().then(start)
  else
    start(entries[0])
)

askConfig = ->
  defer = bluebird.defer()
  questions = [
    {
      type: "input",
      name: "smtp_host",
      message: "SMTP host?"
    }
    {
      type: "input",
      name: "smtp_port",
      message: "SMTP port?"
    }
    {
      type: "input",
      name: "smtp_username",
      message: "SMTP username?"
    }
    {
      type: "input",
      name: "smtp_password",
      message: "SMTP password?"
    }
    {
      type: "confirm",
      name: "smtp_ssl",
      default: false
      message: "Use SSL?"
    }
    {
      type: "confirm",
      name: "smtp_tls",
      default: false
      message: "Use TlS?"
    }
    {
      type: "input",
      name: "smtp_send_from",
      message: "Send from email address?"
    }
    {
      type: "input",
      name: "smtp_default_subject",
      message: "Default subject?"
    }
    {
      type: "input",
      name: "secret_key",
      message: "Secret key?"
    }
  ]

  inquirer.prompt( questions, ( answers ) ->
    db.insert(answers, (err, newDoc) ->
      if err?
        console.log(err)
        process.exit(1)
      else
        defer.resolve(answers)
    )
  )

  defer.promise

  

start = (config) ->
  app.get('/email', (req, res) ->
    
    message = req.query.message
    to_address = req.query.to_address
    key = req.query.key
    
    if not message? or not to_address? or not key?
      res.send('Error, missing information')
      return
      
    if key isnt config.secret_key
      res.send('Error, supplied key is not correct')
      return

    subject = req.query.subject
    
    # Set default subject
    if not subject?
      subject = config.smtp_default_subject
    
    # Send mail!    
    server  = email.server.connect(
      user:     config.smtp_username
      password: config.smtp_password
      host:     config.smtp_host
      port:     config.smtp_port
      ssl:      config.smtp_ssl
      tls:      config.smtp_tls
    )
    
    server.send({
        from:    config.smtp_send_from
        to:      to_address
        subject: subject
        text: message
      }, (err, message) ->
      if err
        res.send('ERROR')
      else
        res.send('OK')
    )    
  )

  # Launch
  port = 9090
  server = http.listen(port, ->
  
    top      = '┌──────────────────────────────────────┐'
    title    = '│ Pipemail Server                      │'
    ready    = '│ Ready to serve clients on port: '
    endReady =                                       ' │'
    bottom   = '└──────────────────────────────────────┘'
  
    console.log(top)
    console.log(title)
    console.log(ready + port + endReady)
    console.log(bottom)
  )