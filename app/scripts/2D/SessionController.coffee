###
A class to manage the user's map session, including settings of most things.
###

NNode = require("./NNode")

module.exports = new
class SessionController extends NNode
  constructor: ()->
    super
    # A big object that holds all the session parameters.
    @session = {}

    # Appends or overwrites values onto the current session.
    @listen "append", (params)=>
      for key, value of params
        @session[key] = value
      # Let others know the session has been appended to
      @post "append", @session

    # Let properties defined in the passed parameters overwrite the
    # current properties. Used for hash updates.
    @listen "replace-and-update", (params)=>
      for key of @session when params[key]?
        if typeof @session[key] is typeof params[key]
          @session[key] = params[key]
      @post "update", @session
