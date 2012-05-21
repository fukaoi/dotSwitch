#  Linux(Unix) command exec object
#  @author: fukaoi

fs = require 'fs'
path = require 'path'
util = require 'util'

class Command
  constructor: (@sourceName)->
    @dotHome = "#{process.env.HOME}/.dotcloud/"
    @dotConf = 'dotcloud.conf'
    @dotKey = 'dotcloud.key'

  # add symbolic link
  addSymbolic: (apiKey, ev) ->
    if isKeyFileExist(@) then deleteDotKey(@)
    fs.mkdir "#{@dotHome}#{@sourceName}/", (err) =>
      if err then throw err
      @ev = ev
      moveFile "#{@dotHome}#{@dotConf}",
        "#{@dotHome}#{@sourceName}/#{@dotConf}",
        createSymbolic(@)

    ev.on 'symbolicComplete', =>
      # replace api key
      fs.readFile "#{@dotHome}#{@dotConf}", (err, data) =>
        if err then throw err
        utf8Data = data.toString 'UTF8'
        json = JSON.parse utf8Data
        json.apikey = apiKey
        modifyJson = JSON.stringify(json)

        fs.writeFile "#{@dotHome}#{@dotConf}", modifyJson, (err) ->
          if err then throw err
          ev.emit 'createComplete'

  # create new symbolic link
  createNewSymbolic: (ev) ->
    if isKeyFileExist(@) then deleteDotKey(@)
    fs.mkdir "#{@dotHome}#{@sourceName}/", (err) =>
      if err then throw err
      @ev = ev
      moveFile "#{@dotHome}#{@dotConf}",
        "#{@dotHome}#{@sourceName}/#{@dotConf}",
        createSymbolic(@)
      ev.on 'symbolicComplete', ->
        ev.emit 'createComplete'

  # symboliclink exist(true) or don't exist(false)
  isSymbolic: ->
    fs.lstat "#{@dotHome}#{@dotConf}", (err, stats) ->
      if err then throw err
      stats.isSymbolicLink()

  # For sourceFile original directory exist
  isDirectoryExist: ->
    path.exists "#{@dotHome}#{@sourceName}", (exist) ->
      exist is true

  # dotcloud.conf exist(true) or don't exist(false)
  isConfFileExist: ->
    path.exists "#{@dotHome}#{@dotConf}", (exist) ->
      console.log exist
      exist is true

  # change symboliclink of source
  switchSymbolic: ->
    if isKeyFileExist(@) then deleteDotKey(@)
    fs.unlink "#{@dotHome}#{@dotConf}", (err) =>
      if err then throw err
      createSymbolic(@)()

  # delete symboliclink of source
  deleteAliasDir: ->
    fs.unlink "#{@dotHome}#{@sourceName}/#{@dotConf}", (err) =>
      if err then throw err
      fs.rmdir "#{@dotHome}#{@sourceName}"
      deleteDotConf @

  # show all aliases name
  showAllAlias: ->
    fs.readdir "#{@dotHome}", (err, files) ->
      if err then throw err
      fs.stats "#{@dotHome}/#{v}", (err, stats) =>
        if err then throw err
        filter = (v for v in files when stats.isDirectory() is on)

  # show in use alias name
  showInUse: ->
    fs.readlink "#{@dotHome}#{@dotConf}", (err, link) ->
      if err then throw err
      aliasName = link.match /(.+)\//
      if !aliasName then throw 'Not found dotcloud file'
      aliasName[1]

  # source file move
  moveFile = (source, destination, callback)->
    input = fs.createReadStream source
    output = fs.createWriteStream destination
    output.on 'error', (ex) -> throw ex

    util.pump input, output, ->
      fs.unlink source, callback()

  # delete dotcloud.conf file
  deleteDotConf = (_self)->
    fs.unlink "#{_self.dotHome}#{_self.dotConf}", (err) =>
      if err then throw err

  # delete dotcloud.key file
  deleteDotKey = (_self)->
    fs.unlink "#{_self.dotHome}#{_self.dotKey}", (err) =>
      if err then throw err

  # create symboliclink (clojure)
  createSymbolic = (_self)->
    ->
      fs.symlink "#{_self.dotHome}#{_self.sourceName}/#{_self.dotConf}",
        "#{_self.dotHome}#{_self.dotConf}"
      _self.ev?.emit 'symbolicComplete'

  # dotcloud.key exist(true) or don't exist(false)
  isKeyFileExist = (_self)->
    path.exists "#{_self.dotHome}#{_self.dotKey}", (exist) ->
      exist is true

process.on 'uncaughtException', (err) -> throw Error err

exports.Command = Command