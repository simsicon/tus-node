# https://gist.github.com/jed/982883 UNDER DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
exports.uuid = (a) ->
  if a 
    (a ^ Math.random() * 16 >> a / 4).toString(16)
  else 
    ([1e7] + 1e3 + 4e3 + 8e3 + 1e11).replace(/[018]/g, this.uuid)

exports.mongo = (callback) ->
  mongoose = require 'mongoose'
  db = mongoose.createConnection('localhost', 'tus', '27017', {server: { poolSize: 5 }, w: 1})
  files = db.collection('files')
  callback files

exports.get_json = (callback) ->
  fs = require 'fs'
  fs.readFile './state.json', (err, data) ->
    callback JSON.parse(data)

exports.save_json = (json) ->
  fs = require 'fs'
  fs.writeFile './state.json', JSON.stringify(json), (err) ->
    throw err if err
    true
  
