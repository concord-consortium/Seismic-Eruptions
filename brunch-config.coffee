exports.config =
  # See http://brunch.io/#documentation for docs.
  fileListInterval: 500
  files:
    javascripts:
      joinTo:
        '2D/app-2d.js': /^app\/scripts\/(2D|common)/
        '3D/app-3d.js': /^app\/scripts\/(3D|common)/
        '2D/vendor-2d.js': /^vendor\/scripts\/(2D|common)/
        '3D/vendor-3d.js': /^vendor\/scripts\/(3D|common)/
    stylesheets:
      joinTo:
        '2D/app-2d.css': /^app\/styles\/2D/
        '3D/app-3d.css': /^app\/styles\/3D/
        '2D/vendor-2d.css': /^vendor/

  sourceMaps: false

  modules:
    wrapper: (path, data) ->
      if data.indexOf("//NOWRAP") is 0 or path.indexOf('app') is -1
        """
#{data}\n\n
        """
      else
        path = path.replace /^app\/scripts\//, ''
        path = path.replace /\.[^\.]*$/, ''
        """
require.define({"#{path}": function(exports, require, module) {
  #{data}
}});\n\n
        """
  plugins:
    autoReload:
      enabled:
        css: off
        js: off
        assets: off
