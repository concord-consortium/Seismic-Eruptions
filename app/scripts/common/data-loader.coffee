class DataLoader
  load: (url, {ajax,callback}={})->
    return new Promise (resolve, reject) =>
      if ajax
        $.ajax
          url: url
          dataType: 'json'
          success: (data)->
            resolve(data)
          error: (request)->
            reject(request)
      else
        id = if callback? then callback else 'request_' + Math.random().toString(36).substr(2, 8) # a semi-random alphanumeric id
        scriptDomElement = @injectScript(id, url, !callback?)
        @createListener(id, scriptDomElement, resolve, reject)
        document.body.appendChild(scriptDomElement)

  createListener: (id, scriptDomElement, resolve, reject)->
    window[id] = (data)->
      document.body.removeChild(scriptDomElement)
      delete window[id]
      resolve(data)

  injectScript: (id, url, appendCallback=true)->
    scriptDomElement = document.createElement('script')
    scriptDomElement.src = url + (if appendCallback then '&callback='+id else '')
    scriptDomElement.id = id
    return scriptDomElement

module.exports = DataLoader
