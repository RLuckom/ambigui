# First attempt at enforcing a nice-to-subclass API on
# SVGTreeNode
class BasicEditableTree extends EditableTree

  # Override some defaults...
  constructor: (options) ->
    model = options.parent ? options
    model.circleRadius ?= 10
    model.starRadius ?= 10
    model.starLength ?= 26
    super options

  # using "click the circle" to test out a few behaviors I'll want later.
  createChild: (evt) =>
    options = {}
    if @visibleChildren().length != @children.length
      options.isHidden = true
    @newChild(options)
    @showChildren()

  # Creates the content for the tree node.
  makeContent: =>
    @content = @svgElement 'foreignObject'
    @contentGroup.appendChild @content
    div = @makeDiv()
    @content.appendChild div
    @content.setAttribute 'width', div.offsetWidth
    @content.setAttribute 'height', div.offsetHeight
    @content.setAttribute 'y', @contentY

  # Override this to add custom content.
  #
  # @return {DOMElement} Element to use as content
  makeDiv: =>
    div = @htmlElement 'div'
    s = 'background: red; height: 40px; width: 60px;'
    div.setAttribute 'style', s
    div.innerHTML = @name
    return div

module.DOGWOOD.BasicEditableTree = BasicEditableTree
