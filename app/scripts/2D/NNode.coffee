###
A small and lightweight class to streamline and standardize communication between
objects, as if each were a node in a larger network
###

module.exports =
class NNode
  constructor: ()->
    @listenerMap = {}
    @subscriberListenerMap = {}
  ###
  News onhand! Tell this to all eager subscribers.
  ###
  post: (channel, data...)->
    # console.log("post", channel, data...)
    @_activateListeners(@subscriberListenerMap, channel, data)

  ###
  Subscribe to a popular node to keep updated.
  All news will be prepended with the namespace, if given
  ###
  subscribe: (channel, listener)->
    @_addToListenerMap(@subscriberListenerMap, channel, listener)
    return

  ###
  Tells this node a very personal message.
  ###
  tell: (channel, data...)->
    @_activateListeners(@listenerMap, channel, data)
    return

  ###
  Registers this node to hear any type of message.
  ###
  listen: (channel, listener)->
    @_addToListenerMap(@listenerMap, channel, listener)
    return

  _addToListenerMap: (map, channel, listener)->
    map[channel] = [] unless map[channel]?
    @_addToSet(map[channel], listener)
    return

  _activateListeners: (map, channel, data)->
    if map[channel]?
      for listener in map[channel]
        listener.apply(this, data)
    return

  _addToSet: (array, value)->
    if array.indexOf(value) is -1
      array.push(value)
    return
