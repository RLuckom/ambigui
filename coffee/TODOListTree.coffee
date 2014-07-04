# Tree implementing a to-do list
class TODOListTree extends BasicEditableTree

  # Sets up the content of the tree
  makeDiv: =>
    @contentDiv = @htmlElement 'div', {style: 'width: 200px; height: 30px;'}
    @form = @htmlElement "form"
    @input = @htmlElement "input", {type: 'text', value: @name, size: 10}
    @button = @htmlElement 'input', {type: "button", value: 'delete'}
    @form.appendChild @input
    @form.appendChild @button
    @button.addEventListener 'click', @remove
    @contentDiv.innerHTML = @input.value
    @contentDiv.addEventListener 'click', @setInputActive
    @inputActive = false
    return @contentDiv

  # Call up the tree to change focus
  #
  # @param {TODOListTree} node node receiving focus
  requestFocusChange: (node) =>
    if not @parent?
      @changeFocus node
    else
      @parent.requestFocusChange node

  # Effect a change of focus
  #
  # @param {TODOListTree} node node receiving focus
  changeFocus: (node) =>
    if this isnt node
      @setTextToDiv()
    for c in @children
      c.changeFocus(node)

  # Callback to set the text of an input to the text
  # of the div on focusout.
  setTextToDiv: (evt) =>
    @name = @input.value
    @contentDiv.innerHTML = @input.value
    @inputActive = false

  # Callback to re-enable the input when div is clicked
  setInputActive: (evt) =>
    if not @inputActive
      @contentDiv.innerHTML = ''
      @contentDiv.appendChild @form
      @inputActive = true
      @requestFocusChange this
      @input.focus()
    return true

module.DOGWOOD.TODOListTree = TODOListTree
