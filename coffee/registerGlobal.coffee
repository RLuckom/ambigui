exports = exports ? this

# Makes an object available globally
#
# @param [String] uniqueName The name to give the object in global scope.
# @param [Object] objectToRegister the object to provide globally.
registerGlobal = (uniqueName, objectToRegister=module) ->
  exports[uniqueName] = objectToRegister
  window[uniqueName] = objectToRegister

module = {}
