utils                   = require 'utils'
{ mode_hints }          = require 'mode-hints/mode-hints'
{ updateToolbarButton } = require 'button'
{ searchForMatchingCommand
, isEscCommandKey
, isReturnCommandKey
, findStorage }         = require 'commands'
{ getPref } = require 'prefs'

modes = {}

modes['normal'] =

  disables: do ->
    map = {}

    # convert from { 'google.com': ['j', 'k'] }
    # to { 'j': { 'google.com': 1 } }
    pref = JSON.parse(getPref('per_site_disables'))
    for host of pref
      keys = pref[host]
      for i in [0...keys.length]
        (map[keys[i]] ?= {})[host] = true
    return map

  onEnter: (vim, storage) ->
    storage.keys ?= []
    storage.commands ?= {}

  onLeave: (vim, storage) ->
    storage.keys.length = 0

  onInput: (vim, storage, keyStr, event) ->

    if storage.keys.length is 0 \
       and @disables[keyStr]?[vim.window.location.host]
      return

    storage.keys.push(keyStr)

    { match, exact, command } = searchForMatchingCommand(storage.keys)

    if match
      if exact
        command.func(vim, event)
        storage.keys.length = 0
      return true
    else
      storage.keys.length = 0

modes['insert'] =
  onEnter: (vim) ->
    updateToolbarButton(vim.rootWindow, {insertMode: true})
  onLeave: (vim) ->
    updateToolbarButton(vim.rootWindow, {insertMode: false})
    utils.blurActiveElement(vim.window)
  onInput: (vim, storage, keyStr) ->
    if isEscCommandKey(keyStr)
      vim.enterMode('normal')
      return true

modes['find'] =
  onEnter: (vim, storage, options) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()

    findBar.onFindCommand()
    findBar._findField.focus()
    findBar._findField.select()

    return unless highlightButton = findBar.getElement("highlight")
    return unless highlightButton.checked != options.highlight
    highlightButton.click()

  onLeave: (vim) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value
    findBar.close()

  onInput: (vim, storage, keyStr) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    if isEscCommandKey(keyStr) or isReturnCommandKey(keyStr)
      vim.enterMode('normal')
      return true
    else
      findBar._findField.focus()

modes['hints'] = mode_hints

exports.modes = modes
