$ = jQuery

DS = null

$ ->
  DS = new Lib.DataStore("master/slave");

# http://blog.fastmail.fm/2012/11/26/inter-tab-communication-using-local-storage/
class @MasterSlave
  @failover_delay = 45000
  constructor: (@key) ->
    now = Date.now()
    ping = DS.fetch("ping") || 0
    @is_master = false
    if now - ping > MasterSlave.failover_delay
      @becomeMaster()
    else
      @loseMaster()
      @masterDidChange()
    @hook_events()

  loseMaster: ->
    clearTimeout @_ping
    @_ping = setTimeout (=> @becomeMaster()), 35000 + ~~( Math.random() * 20000 )
    was_master = @is_master
    @is_master = false
    if was_master
      @masterDidChange()

  becomeMaster: ->
    DS.store "ping", Date.now()
    clearTimeout @_ping
    @_ping = setTimeout (=> @becomeMaster()), 35000 + ~~( Math.random() * 20000 )
    was_master = @is_master
    @is_master = true
    unless was_master
      @masterDidChange()

  masterDidChange: ->
    # if @is_master
    #   window.document.title="MASTER #{DS.fetch("ping")}"
    # else
    #   window.document.title="SLAVE #{DS.fetch("ping")}"
    # do nothing for now

  broadcast: (type, event) ->
    DS.store "broadcast", { type: type, event: event }

  handleEvent: (event) ->
    # console.log "event", event
    type = event.key
    if type == "ping"
      ping = DS.fetch("ping") || 0
      if ping > 0 # someone else is doing a ping, so we can't be master
        @loseMaster()
      else # someone is pinging 0, which is abdicating master
        clearTimeout @_ping
        this._ping = setTimeout (=> @becomeMaster()), ~~( Math.random() * 1000 )
    if type == "broadcast"
      data = event.newValue # should already be JSON
      # console.log "broadcast", data
      @[data.type](data.event)

  # teardown, give up master if we are master
  destroy: ->
    if @is_master
      DS.store "ping", 0
    @unhook_events()

  hook_events: ->
    @unloadHandler = => @destroy()
    DS.on "storage", (event) => @handleEvent(event)
    # window.addEventListener( 'storage', @, false )
    window.addEventListener( 'unload', @unloadHandler, false )

  unhook_events: ->
    # window.removeEventListener( 'storage', @, false )
    DS.off "storage"
    window.removeEventListener( 'unload', @unloadHandler, false )
  # setup a master/slave instance for the window

  @start: (key) ->
    @instance = new MasterSlave(key)
