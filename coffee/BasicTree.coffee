# First attempt at enforcing a nice-to-subclass API on
# SVGTreeNode
class BasicTree extends SVGTreeNode

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
    @content.addEventListener "click", @toggleChildrenVisible

  # Override this to add custom content.
  #
  # @return {DOMElement} Element to use as content
  makeDiv: =>
    div = @htmlElement 'div'
    s = 'background: red; height: 40px; width: 60px;'
    div.setAttribute 'style', s
    div.innerHTML = @name
    return div

module.DOGWOOD.BasicTree = BasicTree
