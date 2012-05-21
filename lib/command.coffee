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
    conf = fs.lstatSync("#{@dotHome}#{@dotConf}").isSymbolicLink()
    conf is true

  # For sourceFile original directory exist
  isDirectoryExist: ->
    path.existsSync "#{@dotHome}#{@sourceName}"

  # dotcloud.conf exist(true) or don't exist(false)
  isConfFileExist: ->
    conf = path.existsSync "#{@dotHome}#{@dotConf}"
    conf is true

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
      fs.rmdirSync "#{@dotHome}#{@sourceName}"
      deleteDotConf @

  # show all aliases name
  showAllAlias: ->
    result = fs.readdirSync "#{@dotHome}"
    filter = (v for v in result when fs.statSync("#{@dotHome}/#{v}").isDirectory() is on)

  # show in use alias name
  showInUse: ->
    result = fs.readlinkSync "#{@dotHome}#{@dotConf}"
    aliasName = result.match /(.+)\//
    if !aliasName then throw 'Not found dotcloud file'
    aliasName[1]

  # source file move
  moveFile = (source, destination, callback)->
    input = fs.createReadStream source
    output = fs.createWriteStream destination
    output.on 'error', (ex) -> throw ex

    util.pump input, output, ->
      fs.unlinkSync source
      callback()

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
      fs.symlinkSync "#{_self.dotHome}#{_self.sourceName}/#{_self.dotConf}",
                     "#{_self.dotHome}#{_self.dotConf}"
      _self.ev?.emit 'symbolicComplete'

  # dotcloud.key exist(true) or don't exist(false)
  isKeyFileExist = (_self)->
    conf = path.existsSync "#{_self.dotHome}#{_self.dotKey}"
    conf is true

process.on 'uncaughtException', (err) -> throw Error err

exports.Command = Command