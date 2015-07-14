###
A small and lightweight class to streamline and standardize communication between
objects, as if each were a node in a larger network
###

module.exports =
class NNode
  constructor: ()->
    @channels = {}
    @neighbors = []
  ###
  Triggers listeners on all connected nodes
  ###
  tellOthers: (channel, data...)->
    @tell(channel, data...)
    for subscriber in @neighbors
      subscriber.tell(channel, data...)
    return this

  ###
  Triggers the listeners on the current node with the given data
  ###
  tell: (channel, data...)->
    if @channels[channel]?
      for listener in @channels[channel]
        listener.apply(this, data)
    # console.log("told", this, channel, data)
    return this

  ###
  Creates a uni-directional connection pathway to the given node
  ###
  connectTo: (node)->
    @neighbors.push(node) if @neighbors.indexOf(node) is -1
    return this

  ###
  Creates a bi-directional connection pathway between the current and given nodes
  ###
  connect: (node)->
    @connectTo(node)
    node.connectTo(this)
    return this

  ###
  Registers a listener on the current node
  ###
  listen: (channel, listener)->
    @channels[channel] = [] unless @channels[channel]?
    if @channels[channel].indexOf(listener) is -1
      @channels[channel].push(listener)
    return this
