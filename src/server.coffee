http = require 'http'
url = require 'url'
fs = require 'fs'
_ = require 'underscore'
utils = require './utils.js'

server = http.createServer (req, res) ->
  console.log req.headers

  switch req.method.toUpperCase()
    when 'POST'
      if url.parse(req.url).pathname == '/files'
        uuid = utils.uuid()
        headers = {
          'Location': 'http://localhost:3001/files/' + uuid,
          'Content-Length': '0'
        }
        res.writeHead 201, headers
        res.write '\n'
        res.end

        utils.mongo (files) ->
          files.insert _.extend {'uuid': uuid}, req.headers
        
    when 'PUT'
      file_id = req.url.slice(7)
      utils.mongo (files) ->
        q = files.find({uuid: file_id}).toArray()
        q.done (docs) ->
          file_meta = docs[0]

          req.on 'data', (chunk) ->
            console.log 'Receive Data!'
            console.log chunk.length
            fs.writeFile './files/' + file_meta['uuid'], chunk, {flag: 'a+'}, (err) ->
              throw err if err

          req.on 'end', ->
            console.log 'Receive End!'
            
            headers = {
              'Range': 'bytes=0-' + (parseInt(file_meta['content-range'].split('/')[1]) - 1),
              'Content-Length': 0,
              'Connection': 'close'
            }

            console.log headers
            res.writeHead 200, headers
            res.write '\n'
            res.end

        q.fail (error) ->
          console.log "mongo failed"
          console.log error
          throw error
      
    when 'HEAD'
      
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.write 'head'
    else
      
      res.writeHead 403
      res.end

server.listen 3001, 'localhost'



