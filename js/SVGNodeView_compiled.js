(function() {
  var exports, module, registerGlobal;

  exports = exports != null ? exports : this;

  module = {};

  registerGlobal = function(uniqueName, objectToRegister) {
    if (objectToRegister == null) {
      objectToRegister = module;
    }
    exports[uniqueName] = objectToRegister;
    return window[uniqueName] = objectToRegister;
  };

}).call(this);
