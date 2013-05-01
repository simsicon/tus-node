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

get_head_headers = (files, file_id, callback) ->
  files.findOne {uuid: file_id}, (err, file) ->
    if err
      console.log "Mongo error" + err
      throw err

    fs.stat 'files/' + file_id + '/' + file['content-disposition'].split('filename')[1].split('"')[1], (err, stat) ->
    
      headers =
        'Content-Type': file['content-type']
        'Content-Length': file['content-length']
        'Content-Disposition': file['content-disposition']
        'Range': 0 + '-' + stat['size']

      callback headers

server = http.createServer (req, res) ->
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

        utils.mongo (files) ->
          files.insert _.extend({'uuid': uuid}, req.headers), (err, file) ->
            if err
              console.log "Mongo error" + err
              throw err
        
    when 'PUT'
      file_id = req.url.slice(7)
      utils.mongo (files) ->
        files.update {uuid: file_id}, {$set: {'content-length': req.headers['content-length']}}, (err, file) ->
          throw err if err
          
        files.findOne {uuid: file_id}, (err, file) ->
          if err
            console.log "Mongo error" + err
            throw err
          length = 0

          req.on 'data', (chunk) ->
            filename = file['content-disposition'].split('filename')[1].split('"')[1]
            length += chunk.length
            fs.writeFile file_path(file['uuid'], filename), chunk, {flag: 'a+'}, (err) ->
              throw err if err

          req.on 'end', ->
            headers =
              'Range': 'bytes=0-' + (parseInt(file['content-range'].split('/')[1]) - 1)
              'Content-Length': 0

            res.writeHead 200, headers
            res.end()
      
    when 'HEAD'

      file_id = req.url.slice(7)
      utils.mongo (files) ->
        get_head_headers files, file_id, (headers) ->
          res.writeHead(200, headers)
          res.end()

server.timeout = 8000

server.listen 3001, '127.0.0.1'



