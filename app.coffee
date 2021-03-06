fs         = require('fs')
express    = require("express")
global.app = express.createServer()
io         = require('socket.io').listen(app)
assets     = require('connect-assets')

#ip = '192.168.1.110'
ip = '10.0.1.8'
port = '3000'

app.set 'views', __dirname + '/views'

app.configure 'development', -> app.use assets()
app.configure 'production',  -> ip = 'vps.kastlersteinhauser.com'; port = 8501; app.use assets( build: true, buildDir: false, src: __dirname + '/assets', detectChanges: false )

app.use express.static(__dirname + '/assets')

app.get '/', (req,res) -> res.render('slides.jade', {ip: ip, port: port})
app.get '/clicker', (req,res) -> res.render 'clicker.jade'

slides_io = io.of("/slides")
clicker_io = io.of("/clicker")

slideId = 1 # dangerous for a threaded system to do
clicker_io.on "connection", (socket) ->
   socket.emit("startfrom", slideId)
   socket.on "changeto", (id) ->
      slideId = id
      slides_io.emit("changeto", slideId)
      socket.broadcast.emit("changeto", slideId)

slides_io.on "connection", (socket) ->
   socket.emit("startfrom", slideId)
   socket.on "changeto", (id) ->
      slideId = id
      clicker_io.emit("changeto", slideId)
      socket.broadcast.emit("changeto", slideId)

app.listen(port)
console.log("Listening on http://"+ip+":"+port+"/")

pidFile = fs.createWriteStream('/tmp/vbnet-gc.pid')
pidFile.once 'open', (fd) ->
   pidFile.write(process.pid)

