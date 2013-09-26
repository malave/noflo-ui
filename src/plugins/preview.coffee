{Dataflow} = require '/meemoo-dataflow'

class NoFloPreview
  initialize: (dataflow) ->
    @preview = null

    @$connector = $ "<div class=\"noflo-ui-preview\">
      <h2><i></i> <span>WebSocket</span></h2>
      <div class=\"toolbar\">
        <button class=\"start btn\"><i class=\"icon-play\"></i></button>
        <button class=\"stop btn\"><i class=\"icon-stop\"></i></button>
        <button class=\"connect btn\"><i class=\"icon-refresh\"></i></button>
        <span class=\"status\"></span>
        <span class=\"uptime\"></span>
      </div>
      <div class=\"preview\"></div>
    </div>"

    @$status = @$connector.find '.status'
    @$preview = @$connector.find '.preview'
    @$startButton = @$connector.find '.start'
    @$stopButton = @$connector.find '.stop'
    @$connButton = @$connector.find '.connect'

    dataflow.addPlugin
      id: 'preview'
      name: ''
      menu: @$connector
      icon: 'play-circle'
      pinned: true

    @$startButton.click =>
      dataflow.plugins.notification.requestPermission()
      @runtime.start()
    @$stopButton.click =>
      @runtime.stop()
    @$startButton.hide()
    @$stopButton.hide()
    @$connButton.hide()

    @dataflow = dataflow

  onShow: =>
    # Move the preview element of the runtime to the plugin card
    @$preview.append @runtime.getElement()

  setRuntime: (@runtime) ->
    switch @runtime.getType()
      when 'iframe'
        @$connector.find('h2 i').addClass 'icon-globe'
      else
        @$connector.find('h2 i').addClass 'icon-cloud'

    @runtime.on 'status', (status) =>
      @$status.removeClass 'online'
      @$status.removeClass 'offline'
      @$status.removeClass 'pending'
      @$status.addClass status.state

      @$status.html status.label

      if status.label is 'running'
        @$startButton.hide()
        @$stopButton.show()
      if status.label is 'stopped'
        @$stopButton.hide()
        @$startButton.show()

  preparePreview: (preview, callback) ->
    @runtime.connect preview
    @$connButton.click =>
      @preparePreview preview, ->

    @runtime.once 'connected', =>
      # Update preview card contents
      @$connector.find('h2 span').html @runtime.getAddress()
      @$connButton.hide()
      @$startButton.show()

      # Show the preview card automatically
      @dataflow.showPlugin 'preview'

      callback()

    @runtime.once 'disconnected', =>
      @dataflow.plugins.notification.notify 'noflo.png', 'Error', 'Connection to NoFlo runtime was lost'
      @$connButton.show()
      @$startButton.hide()
      @$stopButton.hide()

plugin = Dataflow::plugin 'preview'
Dataflow::plugins['preview'] = new NoFloPreview