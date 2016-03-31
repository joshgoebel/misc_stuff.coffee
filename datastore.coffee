$ = jQuery

$ ->

class Lib.DataStore
  LS: localStorage
  constructor: (@namespace) ->
    riot.observable @
    window.addEventListener 'storage', ((e)=> @storageEvent(e)), false
  storageEvent: (event) ->
    # console.log event
    key = event.key
    # if this key is in our namespace
    if key.indexOf(@namespace) == 0
      new_event = _.extend({}, event)
      new_event.key = event.key.replace(@namespace+"--","") # rewrite key removing namespace
      new_event.newValue = JSON.parse(event.newValue)
      @trigger "storage", new_event
    # otherwise this is not our namespace so we do not care
  fetch: (key) ->
    raw = @LS.getItem(@keyName(key))
    `if ((typeof raw == "undefined" || raw == null)) { return null; }`
    JSON.parse raw
  store: (key, value) ->
    if typeof value == "undefined"
      value = null
    @LS.setItem @keyName(key), JSON.stringify(value)
    value
  # private
  keyName: (key) ->
    "#{@namespace}--#{key}"
