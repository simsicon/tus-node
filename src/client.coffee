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
  else

  req.end()

build_content_range = (begin, end, length) ->
  if begin == null
    head_str = '*'
  else
    head_str = begin + '-' + (end - 1)
  'bytes ' + head_str + '/' + length

shared_opts = () ->
  { hostname: '127.0.0.1', port: 3001 }    

post_file = (meta, callback) ->
  opts =
    headers:
      'Content-Length': '0',
      'Content-Range': build_content_range(null, null, meta['data'].length),
      'Content-Type': 'text/plain',
      'Content-Disposition': 'attachment; filename="' + meta['name'] + '"'
    method: 'POST',
    path: '/files'

  send_request null, _.extend(shared_opts(), opts), false, (err, res) ->
    callback err, res

put_file = (meta, callback) ->
  console.log "put file, and i got a meta"
  console.log meta
  range_start = parseInt(meta['range'][0])
  range_end = parseInt(meta['range'][1])

  data = meta['data']
  data = data.slice(range_start, range_end)

  opts =
    headers:
      'Content-Length': data.length
      'Content-Range': build_content_range(meta['range'][0], meta['range'][1], meta['data'].length)
    method: 'PUT'
    path: url.parse(meta['location']).path

  if meta['range'][0].toString() == '0'
    is_network_bad = true
  else
    is_network_bad = false

  console.log "IS network bad? " + is_network_bad
  console.log "Range: " + range_start + '-' + range_end
  console.log data.length
  console.log opts

  send_request data, _.extend(shared_opts(), opts), is_network_bad, (err, res) ->
    callback err, res

head_file = (location, callback) ->
  opts =
    method: 'HEAD'
    path: url.parse(location).path

  send_request null, _.extend(shared_opts(), opts), false, (err, res) ->
    range = res['headers']['range'].split('-')
    callback err, range, res

upload_file = (meta, callback) ->
  post_file meta, (err, res) ->
    console.log err if err
    meta = _.extend(meta, {location: res.headers['location']}, {range: [0, meta['data'].length]})
    put_file meta, (err, res) ->
      callback err, meta, res

resume_upload_file = (meta, callback) ->
  head_file meta['location'], (err, range, res) ->
    console.log err if err
    range = [range[1], meta['range'][1]]
    meta = _.extend(meta, {range: range})
    console.log meta
    put_file meta, (err, res) ->
      callback err, res

file_path  = './file'

fs.readFile file_path, (err, data) ->
  meta =
    path: file_path
    data: data
    name: path.basename(file_path)

  upload_file meta, (err, res) ->
    
    console.log 'Upload Failed' 
    console.log meta
    if err
      resume_upload_file meta, (err, res) ->
        console.log err if err
        console.log res['headers']

# upload_file meta, (err, meta, res) ->

    # resume_upload_file location, (err, res) ->
    #   if err
    #     console.log err

 