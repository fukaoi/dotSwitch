#!/usr/bin/env coffee

#  dotcloud account switch tool
#  @author: fukaoi
Command = require('../lib/command.coffee').Command
program = require 'commander'
EventEmitter = require('events').EventEmitter

###
# super class
###
class DotSwitch
  constructor: (@alias) ->
    @Cmd = new Command(@alias)

    if !@Cmd.isConfFileExist()
    then throw "Not Found #{@Cmd.dotConf}. Please execute 'dotcloud' command"

  # alias parameter check
  aliasCheck: ->
    if not @alias
      throw "Input dotcloud alias name (#{program.name} --help for help)"

  # alias directory check
  aliasDirecCheck: ->
    if @Cmd.isDirectoryExist() is off
      throw "Not found #{@alias} directory"

  # alias directory exist check
  aliasDirecExistCheck: ->
    if @Cmd.isDirectoryExist() is on
      throw "Exist #{@alias} directory"

  # dotcloud.conf exist check
  dotcloudConfCheck: ->
    if @Cmd.isConfFileExist() is off
      throw "Not found #{@Cmd.dotConf}, At first dotcloud setup"

###
# factory method
###
class SwitchOption extends DotSwitch
  run: ->
    @aliasCheck()
    @aliasDirecCheck()
    @Cmd.switchSymbolic()
    console.log "#{@alias} switch ok"

class CreateOption extends DotSwitch
  run: ->
    @aliasCheck()
    @aliasDirecExistCheck()
    ev = new EventEmitter
    if @Cmd.isSymbolic()
      # add aliaas
      program.prompt 'Enter dotcloud api key:', (apiKey) =>
        if !apiKey then throw 'No input api key'
        console.log 'OK api key.'
        @Cmd.addSymbolic apiKey, ev
        ev.on 'createComplete', ->
          console.log 'Add alias of dotcloud file'
          process.exit(0)
    else
      # new aliaas
      @Cmd.createNewSymbolic ev
      ev.on 'createComplete', ->
        console.log 'New create alias of dotcloud file'

class DeleteOption extends DotSwitch
  run: ->
    @aliasCheck()
    @aliasDirecCheck()
    @Cmd.deleteAliasDir()
    console.log "Delete alias #{@alias} of directory"

class ListOption extends DotSwitch
  run: ->
    res = @Cmd.showAllAlias()
    console.log aliasName for aliasName in res

class NowOption extends DotSwitch
  run: ->
    res = @Cmd.showInUse()
    console.log "Now used in: #{res}"

###
# main
###
try
  program
  .version('0.1.0')
  .usage('[option] [alias name] or [option]')
  .option('-s, --switch', 'change alias of dotcloud file')
  .option('-c, --create', 'create a new alias or add alias')
  .option('-d, --delete', 'delete a alias of directory')
  .option('-l, --list', 'show all aliases(option only)')
  .option('-n, --now', 'alias in use(option only)')
  .parse(process.argv)

  option = process.argv[3]
  switch process.argv[2]
    when '-s', '--switch'
      new SwitchOption(option).run()
    when '-c', '--create'
      new CreateOption(option).run()
    when '-d', '--delete'
      new DeleteOption(option).run()
    when '-l', '--list'
      new ListOption().run()
    when '-n', '--now'
      new NowOption().run()

catch err
  console.log "\n  error: #{err}\n"
