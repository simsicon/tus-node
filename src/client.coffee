http = require 'http'
fs = require 'fs'
_ = require 'underscore'
url = require 'url'

send_request = (data, options, cb) ->
  req = http.request options

  req.on 'error', (e) ->
    console.log 'Problem with request:' + e.message

  req.on 'response', (res) ->
    console.log 'STATUS:' + res.statusCode
    console.log 'HEADERS:' + JSON.stringify(res.headers)
    res.setEncoding('utf-8')
    cb res

  if _.isString(data) || Buffer.isBuffer(data)
    req.write data
    req.write '0\r\n\r\n'
  else
    req.write '0\r\n\r\n'

  req.end

build_content_range = (begin, end, length) ->
  if begin == null
    head_str = '*'
  else
    head_str = begin + '-' + end
  'bytes ' + head_str + '/' + length

shared_opts = () ->
  { hostname: 'localhost', port: 3001 }    

post_file = (data, callback) ->
  opts = {
    headers: {
      'Content-Length': '0',
      'Content-Range': build_content_range(null, null, data.length),
      'Content-Type': 'text/plain',
      'Content-Disposition': 'attachment; filename="file"'
    },
    method: 'POST',
    path: '/files'
  }

  send_request null, _.extend(shared_opts(), opts), (res) ->
    callback res

put_file = (data, res) ->
  location = url.parse(res.headers['location'])
  opts = {
    headers: {
      'Content-Length': data.length,
      'Content-Range': build_content_range(0, data.length - 1, data.length)
    },
    method: 'PUT',
    path: location.path
  }
  
  send_request data, _.extend(shared_opts(), opts), (res) ->

send_file = () ->
  fs.readFile './file', (err, data) ->
    throw err if err

    post_file data, (res) ->
      put_file data, res, () ->

send_file()





