# First attempt at enforcing a nice-to-subclass API on
# SVGTreeNode
class BasicTree extends SVGTreeNode

  # @param {Object} options see SVGTreeNode
  constructor: (options) ->
    super options
    
  # using "click the circle" to test out a few behaviors I'll want later.
  contentClick: (evt) =>
    options = {}
    if @visibleChildren().length != @children.length
      options.isHidden = true
    @newChild(options)
    @showChildren()
  
  # demo show and hide callbacks
  circleClick: (evt) =>
    if @visibleChildren().length != @children.length
      @showChildren()
    else
      @hideChildren()

  # creates the textelement in the SVG displaying the node name.
  #
  # Note that assigning to innerHTML is not supported in SVG even on relatively
  # recent browsers. It is safest to add text by using document.createTextNode.
  #
  # @return {DOM.SVGSVGElement} text node
  makeText: =>
    @contentX = @contentDX
    @contentY = @y + @marginTop
    @content = @svgElement "text", {
      fill: "black",
      x: @contentDX,
    }
    @content.appendChild document.createTextNode @name
    @content.addEventListener "click", @textClick
    @el.appendChild @content

  # Creates the content for the tree node. Override this to add custom
  # content.
  makeContent: =>
    div = @htmlElement 'div'
    s = 'background: red; height: 40px; width: 60px;'
    div.setAttribute 'style', s
    div.innerHTML = @name
    @content = @svgElement 'foreignObject'
    @contentGroup.appendChild @content
    @content.appendChild div
    @content.setAttribute 'width', div.offsetWidth
    @content.setAttribute 'height', div.offsetHeight
    @content.setAttribute 'y', @contentY
    @content.addEventListener "click", @contentClick

module.BasicTree = BasicTree
