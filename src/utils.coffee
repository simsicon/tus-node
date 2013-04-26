# https://gist.github.com/jed/982883 UNDER DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
exports.uuid = (a) ->
  if a 
    (a ^ Math.random() * 16 >> a / 4).toString(16)
  else 
    ([1e7] + 1e3 + 4e3 + 8e3 + 1e11).replace(/[018]/g, this.uuid)

exports.mongo = (callback) ->
  mongoq = require("mongoq")
  db = mongoq("tus", {host: "127.0.0.1", port: "27017", w: 1}) 
  files = db.collection("files")
  callback files
