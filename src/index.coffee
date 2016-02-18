app      = require('express')()
http     = require('http').Server(app)
email    = require("emailjs/email")

# CORS allow all
app.use(require('cors')())

# Config
user           = process.env.SMTP_USERNAME
password       = process.env.SMTP_PASSWORD
host           = process.env.SMTP_HOST
defaultFrom    = process.env.SMTP_FROM
defaultSubject = process.env.DEFAULT_SUBJECT
port           = process.env.SMTP_PORT
ssl            = process.env.SMTP_SSL is 'true'
tls            = process.env.SMTP_TLS is 'true'
key            = process.env.API_KEY

configured = ->
  user? and password? and host? and port? and key?

# Index 
app.get('/', (req, res) ->
  if configured()
    res.send('OK')
  else 
    res.send('Configuration Failure')
)

# Email
app.get('/email', (req, res) ->
  
  text    = req.query.text
  to      = req.query.to
  from    = req.query.from
  subject = req.query.subject

  # Set default if not set
  from    = defaultFrom    if not from?
  subject = defaultSubject if not subject?

  valid = ->
    text? and to? and key is req.query.api_key
  
  if not configured() or not valid()
    res.send('Configuration Failure')
  else        
    # Send mail
    server  = email.server.connect({user, password, host, port, ssl, tls})
    
    server.send({from, to, subject, text}, (err) ->
      if err
        res.send('ERROR')
      else
        res.send('OK')
    )    
)

# Launch
http_port = process.env.PORT || 9090;
http.listen(http_port, ->
  console.log('Pipemail Server running')
)
