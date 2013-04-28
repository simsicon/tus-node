http = require 'http'
url = require 'url'
fs = require 'fs'
_ = require 'underscore'
path = require 'path'
utils = require './utils.js'

RECEIVE_FILES_DIR = 'files'

file_path = (uuid, filename) ->
  filename = filename || ''
  path.join(RECEIVE_FILES_DIR, uuid, '/', filename)

server = http.createServer (req, res) ->
  console.log req.headers

  switch req.method.toUpperCase()
    when 'POST'
      if url.parse(req.url).pathname == '/files'
        uuid = utils.uuid()
        headers =
          'Location': 'http://127.0.0.1:3001/files/' + uuid
          'Content-Length': '0'

        res.writeHead 201, headers
        res.write '\n'
        res.end

        fs.mkdir file_path(uuid), () ->

        utils.save_json _.extend({'uuid': uuid}, req.headers)
        
    when 'PUT'
      file_id = req.url.slice(7)
      utils.get_json (file) ->
        utils.save_json _.extend file, {'content-length': req.headers['content-length']}

        req.on 'data', (chunk) ->
          filename = file['content-disposition'].split('filename')[1].split('"')[1]
          fs.writeFile file_path(file['uuid'], filename), chunk, {flag: 'a+'}, (err) ->
            throw err if err

        req.on 'end', ->
          console.log 'Receive End!'
          
          headers =
            'Range': 'bytes=0-' + (parseInt(file['content-range'].split('/')[1]) - 1)
            'Content-Length': 0

          res.writeHead 200, headers
          res.write '\n'
          res.end

      
    when 'HEAD'

      file_id = req.url.slice(7)
      utils.get_json (file) ->

        fs.stat 'files/' + file['uuid'] + '/' + file['content-disposition'].split('filename')[1].split('"')[1], (err, stat) ->
          headers =
            'Content-Type': file['content-type']
            'Content-Length': file['content-length']
            'Content-Disposition': file['content-disposition']
            'Range': 0 + '-' + stat['size']

          console.log "Radio is Head"

          res.writeHead 200, headers
          res.write '\n'
          res.close

server.timeout = 2000

server.listen 3001, '127.0.0.1'



