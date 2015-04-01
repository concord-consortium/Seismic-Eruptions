class DataLoader
  load: (url)->
    return new Promise (resolve, reject) =>
      id = 'request_' + Math.random().toString(36).substr(2, 8) # a semi-random alphanumeric id
      scriptDomElement = @injectScript(id, url)
      @createListener(id, scriptDomElement, resolve, reject)
      document.body.appendChild(scriptDomElement)

  createListener: (id, scriptDomElement, resolve, reject)->
    window[id] = (data)->
      document.body.removeChild(scriptDomElement)
      delete window[id]
      resolve(data)

  injectScript: (id, url)->
    scriptDomElement = document.createElement('script')
    scriptDomElement.src = url + '&callback='+id
    scriptDomElement.id = id
    return scriptDomElement

module.exports = DataLoader
