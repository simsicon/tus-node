fs = require 'fs'
_ = require 'underscore'

exports.store = (file_id, meta, callback) ->
  _store_file = './metadata/store.json'
  fs.readFile _store_file, (err, data) ->
    throw err if err

    if data.length == 0
      _meta = {}
    else
      try
        _meta = JSON.parse(data)
      catch e
        throw e

    console.log _meta
    console.log data.length

    meta = _.extend(_meta, meta)

    console.log meta

    fs.writeFile _store_file, JSON.stringify(meta), (err) ->
      if err
        throw err
      else
        callback true


