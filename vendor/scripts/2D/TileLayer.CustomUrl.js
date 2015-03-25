L.TileLayer.prototype._oldGetTileUrl = L.TileLayer.prototype.getTileUrl;

L.TileLayer.prototype.getTileUrl = function(tilePoint) {
  if (typeof(this._url) === 'function') {
    return this._url.call(this, tilePoint);
  }
  return  this._oldGetTileUrl.call(this, tilePoint);
};
