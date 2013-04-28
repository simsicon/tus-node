http = require 'http'
fs = require 'fs'
url = require 'url'
path = require 'path'
_ = require 'underscore'

send_request = (data, options, is_network_bad, callback) ->
  req = http.request options

  req.on 'error', (err) ->
    # console.log 'Problem with request:' + err.message
    callback err

  req.on 'response', (res) ->
    console.log 'STATUS:' + res.statusCode
    console.log 'HEADERS:' + JSON.stringify(res.headers)
    res.setEncoding('utf-8')
    callback null, res

  if _.isString(data) || Buffer.isBuffer(data)
    start = 0
    buffer_length = 65536
    end = start + buffer_length

    if is_network_bad
      data_end = data.length - parseInt(Math.random() * 100000)  #Bad network could be bad

      while end <= data_end
        req.write data.slice(start, end)
        start = end
        end = start + buffer_length

    else
      data_end = data.length

      while end <= data_end
        req.write data.slice(start, end)
        start = end
        end = start + buffer_length

      if start < data_end && end > data_end
        req.write data.slice(start, data_end)

    req.write '0\r\n\r\n'
  else
    console.log "yeah basically I am just a null"
    req.write '0\r\n\r\n'

  req.end

build_content_range = (begin, end, length) ->
  if begin == null
    head_str = '*'
  else
    head_str = begin + '-' + end
  'bytes ' + head_str + '/' + length

shared_opts = () ->
  { hostname: '127.0.0.1', port: 3001 }    

post_file = (filename, data, callback) ->
  opts =
    headers:
      'Content-Length': '0',
      'Content-Range': build_content_range(null, null, data.length),
      'Content-Type': 'text/plain',
      'Content-Disposition': 'attachment; filename="' + filename + '"'
    method: 'POST',
    path: '/files'

  send_request null, _.extend(shared_opts(), opts), false, (err, res) ->
    callback err, res

put_file = (data, location, range, callback) ->
  opts =
    headers:
      'Content-Length': data.length
      'Content-Range': build_content_range(range[0], range[1], data.length)
    method: 'PUT'
    path: url.parse(location).path

  if range[0].toString() == '0'
    is_network_bad = true
  else
    is_network_bad = false

  console.log "IS network bad? " + is_network_bad
  data = data.slice(range[0], range[1] + 1)
  send_request data, _.extend(shared_opts(), opts), is_network_bad, (err, res) ->
    callback err, res

head_file = (location, callback) ->
  opts =
    method: 'HEAD'
    path: url.parse(location).path

  console.log opts

  send_request null, _.extend(shared_opts(), opts), false, (err, res) ->
    console.log err
    range = res.headers['Range'].split('-')
    callback err, range, res

upload_file = (file_path, callback) ->
  fs.readFile file_path, (err, data) ->
    console.log err if err

    post_file path.basename(file_path), data, (err, res) ->
      console.log err if err
      location = res.headers['location']
      put_file data, location, [0, data.length - 1], (err, res) ->
        if res
          callback err, res
        else
          callback err, location

resume_upload_file = (location, callback) ->
  head_file location, (err, range, res) ->
    console.log err if err

    put_file data, location, range, (err, res) ->


file_path  = './file'
upload_file file_path, (err, res) ->
  if err
    console.log 'Upload Failed' 
    console.log err

    location = url.parse(res)['pathname']
    resume_upload_file location, (err, res) ->
      if err
        console.log err

 