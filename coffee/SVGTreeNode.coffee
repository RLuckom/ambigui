module.DOGWOOD = {}

# Recursive tree node.
class SVGTreeNode

  @animator: new module.Animator()

  # Creates a function that returns namespaced DOMElements
  #
  # @param {String} namespace namespace to use
  # @param {String} version optional namespace version string
  # @return {Function} creates elements in the namespace.
  @namespaceElementCreator: (namespace, version=null) ->
    return (tag, attributes={}) ->
      el = document.createElementNS namespace, tag
      if version?
        attributes.version ?= version
      attributes.xmlns = namespace
      for attr, value of attributes
        el.setAttribute(attr, value)
      return el

  # Creates a tag element in the svg namespace
  #
  # @param {String} tag tag type e.g. 'svg' 'path' 'rect
  # @param {Object} attributes key-value pairs to be set as attributes
  svgElement: @namespaceElementCreator "http://www.w3.org/2000/svg", "1.1"

  # Creates a tag element in the svg namespace
  #
  # @param {String} tag tag type e.g. 'svg' 'path' 'rect
  # @param {Object} attributes key-value pairs to be set as attributes
  htmlElement: @namespaceElementCreator "http://www.w3.org/1999/xhtml"

  # returns data about the tree
  toString: =>
    s = "name: #{@name}\n isHidden: #{@isHidden} x: #{@x} y: #{@y}"
    s += " contentDX: #{@contentDX} contentOffset: #{@marginBottom()} "
    s += "contentX: #{@contentX}"
    s += " textY: #{@contentY} linePoints: #{@linePoints} circleX: #{@circleX}"
    s += " circleY #{@circleY}"
    s += " scale: #{@scale}"
    s += "\n"
    s += child.toString() for child in @children
    ret = ''
    for line in s.split("\n")
      ret += '   ' + line + "\n"
    return ret

  # Sets up the view. In the params below, the name 'model' is used to describe
  # the parent if provided (options.parent) or if not, the options model itself.
  # So 'model.indent' means options.parent.indent or options.indent if
  # options.parent is null.
  #
  # The frame of each node has its origin at the point where the nodes line
  # intersects with its parent's line. Positive x is to the left, positive y is
  # down. Note that the y-offset of the text from the origin is negative if the
  # text is above the line.
  #
  # @param {Object} options
  # @param {Bool} options.isHidden whether to display the node
  # @param {String} options.text the text to display on the node.
  # @param {Bool} options.autoAdjust Whether to autoresize containing div.
  # @param {Number} options.x x-coord
  # @param {Number} options.y y-coord
  # @param {SVGTreeNode} options.parent If provided, used to populate members.
  # @param {Number} model.indent x-distance to translate per generation.
  # @param {Number} model.textDX x-offset of the text from 0 in the node-frame.
  # @param {Number} model.elementOffset y-offset of the element from node-0.
  # @param {Number} model.circleRadius radius of end circle.
  # @param {Number} model.animateDuration time to allow for animations.
  # @param {number} model.lineWidth width of lines
  # @param {String} model.treeColor color for circle when children are shown
  constructor: (options) ->
    @children = []
    model = options.parent ? options
    @name = options.text ? "Root"
    @autoAdjust = options.autoAdjust ? true
    @indent = model.indent ? 40
    @contentDX = model.contentDX ? 15
    @circleRadius = model.circleRadius ? 4
    @animateDuration = model.animateDuration ? 400
    @isHidden = options.isHidden ? false
    @scale = if @isHidden then "0 1" else "1 1"
    @emptyColor = model.emptyColor ? 'white'
    @treeColor = model.treeColor ? 'slateblue'
    @marginTop = model.marginTop ? 20
    @marginBottom = model.marginBottom ? 10
    @frameLength = model.frameLength ? 20
    @lineWidth = model.lineWidth ? 2
    @outerFramePaddingBottom = model.outerFramePaddingBottom ? 20
    @x = options.x ? 5
    @y = options.y ? 0
    if options.parent?
      @parent = options.parent
      @el = options.el
    else
      @isRoot = true
      @div = options.el
      @el = @svgElement "svg"
      @div.appendChild @el
    @contentY = @y + @marginTop
    @makeContentGroup()
    @makeContent()
    @makeLine()
    if @isHidden and options.children?
      @circleY = @y + @marginTop + @contentHeight() + @marginBottom
      @circleX = @indent
    if options.children?
      for child in options.children
        child.isHidden = true
        @newChild(child)

  # @param {String} name text to display in tree
  # @return {SVGTreeNode} child nodeview with name name
  newChild: (options={}) =>
    if not (@circle? or @isHidden)
      @makeCircle()
    transform_spec = transform: "translate(#{@indent}, 0)"
    spacer_el = @svgElement "g", transform_spec
    scale = if options.isHidden then "0 1" else "1 1"
    transform_spec = transform: "scale(#{scale})"
    child_el = @svgElement "g", transform_spec
    spacer_el.appendChild child_el
    @el.appendChild spacer_el
    options.el = child_el
    options.parent = this
    options.text ?= 'new'
    options.x = @x + @indent
    if options.isHidden
      options.y = @y
    else
      options.y = @y + @flagpoleLength()
    child = new @constructor options
    @children.push child

  # request gets passed up the chain, root calls update.
  requestUpdate: =>
    if @parent?
      @parent.requestUpdate()
    else
      @updatePosition()

  # animates all elements of this node from their current actual location to
  # their current 'correct' location
  updatePosition: (callback=null) =>
    @updateChildren()
    if not @parent? and @autoAdjust
      @updateOuterFrame()
    @moveChildren()
    @move()

  # Updates the height of the frame containing the tree based on how
  # much space the tree needs.
  updateOuterFrame: =>
    n = @div.offsetHeight
    if n != @totalHeight() + @contentHeight() + @outerFramePaddingBottom
      height = @totalHeight() + @contentHeight() + @outerFramePaddingBottom
      SVGTreeNode.animator.animation(
        @div, "height", "#{n}px", "#{height}px", @frameLength,
        @animateDuration, null
      )()
      SVGTreeNode.animator.animation(
        @el, "height", "#{n}px", "#{height}px", @frameLength,
        @animateDuration, null
      )()
    @width ?= @div.offsetWidth
    if @width != @totalWidth()
      SVGTreeNode.animator.animation(
        @div, "width", "#{@width}px", "#{@totalWidth()}px", @frameLength,
        @animateDuration, null
      )()
      SVGTreeNode.animator.animation(
        @el, "width", "#{@width}px", "#{@totalWidth()}px", @frameLength,
        @animateDuration, null
      )()
      @width = @totalWidth()

  # Updates the position and form of the node.
  move: =>
    @animateLine()
    @animateContent()
    @animateCircle()
    @animateVisible()

  # Returns the height of the caller-supplied content in the node
  # TODO: Currently returns after first node with height
  #
  # @return {Number}
  contentHeight: =>
    for node in @contentGroup.childNodes
      if node.offsetHeight?
        return node.offsetHeight
      if node.height?
        return node.height.baseVal.value

  # Returns the width of the caller-supplied content in the node
  # TODO: Currently returns after first node with height
  #
  # @return {Number}
  contentWidth: =>
    candidates = []
    for node in @contentGroup.childNodes
      if node.offsetWidth?
        candidates.push node.offsetWidth
      if node.width?
        candidates.push node.width.baseVal.value
    return Math.max candidates...

  # updates the position of all children.
  updateChildren: =>
    dY = @y + @marginTop + @contentHeight() + @marginBottom
    for child in @children
      child.y = if not child.isHidden then dY else @y
      child.x = @x + @indent
      dY += child.totalHeight()

  # recursively updates the position of all descendent elements
  #
  # @param {Function} callback if given will be called on animation end
  moveChildren: (callback=null) =>
    if @children.length == 0 and callback?
      callback()
    child.updatePosition(callback) for child in @children

  # Returns the length of the 'flagpole' extending below the node. That
  # is the part the children extend from.
  #
  # @return {Number}
  flagpoleLength: =>
    l = 0
    for child in @children
      if not child.isHidden
        if child == @children[@children.length - 1]
          l += child.marginTop + child.contentHeight() + child.marginBottom
        else
          l += child.totalHeight()
    return l

  # Returns the total height of the node, including all descendants.
  # @return {Number}
  totalHeight: =>
    n = Math.max(@marginTop, @marginBottom) + @contentHeight()
    n += child.totalHeight() for child in @visibleChildren()
    return n

  # Returns the total width of the node, including all descendants.
  # @return {Number}
  totalWidth: =>
    candidates = [Math.max(@contentWidth() + @contentDX, 2 * @indent)]
    candidates.push(@indent + c.totalWidth()) for c in @children
    return Math.max candidates...

  # Returns the current coordinates to use for the polyline.
  # Sets priorLinePoints to the existing coordinates, if any.
  #
  # @return {String} svg polyline points string
  getLinePoints: =>
    y = @y + @marginTop + @contentHeight() + @marginBottom
    return "#{0} #{y} #{@indent} #{y} #{@indent} #{y + @flagpoleLength()}"

  # @return {DOM.SVGSVGElement} polyline
  makeLine:  =>
    @linePoints = @getLinePoints()
    @line = @svgElement "polyline",  {
      fill: "none",
      points: @linePoints,
      'stroke-width': "#{@lineWidth}px",
      stroke: @treeColor
    }
    @el.appendChild @line
      
  # move the line to the correct position
  #
  # @param {Function} callback if given will be called on animation end
  animateLine: (callback=null)=>
    if not @line?
      if @isHidden
        @linePoints = @getLinePoints()
        return
      @makeLine()
    newPoints = @getLinePoints()
    SVGTreeNode.animator.animation(
      @line, "points", @linePoints, newPoints,
      @frameLength, @animateDuration, callback
    )()
    @linePoints = newPoints

  # move the text to the correct position
  #
  # @param {Function} callback if given will be called on animation end
  animateContent: (callback=null) =>
    newY = @y + @marginTop
    SVGTreeNode.animator.animation(
      @content, "y", "#{@contentY}px", "#{newY}px",
      @frameLength, @animateDuration, callback
    )()
    @contentY = newY

  # @return {DOM.SVGSVGElement} circle
  makeCircle: =>
    @circleX = @indent
    @circleY ?= @y + @marginTop + @contentHeight() + @marginBottom
    @circle = @svgElement "circle", {
      fill: @treeColor,
      cx: @indent,
      cy: @circleY,
      r: @circleRadius,
      "stroke-width": "#{@lineWidth}px",
      stroke: @treeColor
    }
    @circle.addEventListener "click", @toggleChildrenVisible
    @el.appendChild @circle

  # move the circle to the correct position
  #
  # @param {Function} callback if given will be called on animation end
  animateCircle: (callback=null) =>
    if not @circle?
      if (@children.length == 0) or @isHidden
        return
      else
        @makeCircle()
    new_cy = @y + @marginTop + @contentHeight() + @marginBottom
    SVGTreeNode.animator.animation(
      @circle, "cy", "#{@circleY}px", "#{new_cy}px",
      @frameLength, @animateDuration, callback
    )()
    @circleY = new_cy
    color = if @visibleChildren().length == 0 then @treeColor else @emptyColor
    @circle.setAttribute 'fill', color

  # Shows the immediate children of this node
  showChildren: =>
    for child in @children
      child.isHidden = false
    @updateChildren()
    @requestUpdate()

  # Hides all visible descendants of this node.
  hideChildren: =>
    test = => @visibleChildren().length == 0
    trigger = => @requestUpdate()
    f = @groupActionCallback trigger, test
    if @isRoot
      f = @groupActionCallback @updatePosition, test
    child.hide(f) for child in @visibleChildren()

  # hides the element and all children
  #
  # @param {Function} callback if given, called with this as param on hide end
  hide: (callback) =>
    if @visibleChildren().length == 0
      @isHidden = true
      callback this
    hideCallback = =>
      @isHidden = true
      callback this
    test = => @visibleChildren().length == 0
    cb = @groupActionCallback hideCallback, test
    child.hide(cb) for child in @visibleChildren()

  # Makes a function that listens for each . When all
  # children have reported back, it calls the provided callback.
  #
  # @param {Function} callback if given will be called on animation end
  groupActionCallback: (callback, test) ->
    return (opts) ->
      if test(opts) and callback?
        callback()

  # @return {Number} of children that are hidden
  visibleChildren: =>
    @children.filter (x) -> not x.isHidden

  # Animates the visibility of a node based on the isHidden member.
  # no visual effect if the isHidden state hasn't changed.
  #
  # @param {Function} callback if provided, called on animation end.
  animateVisible: (callback=null) =>
    newScale = if @isHidden then "0 1" else "1 1"
    SVGTreeNode.animator.animation(
      @el, "transform", "scale(#{@scale})", "scale(#{newScale})",
      @frameLength, @animateDuration, callback
    )()
    @scale = newScale

  # The ContentGroup is an svg 'g' element that holds the content. This
  # sets it up. Should be called before attempting to make the content.
  makeContentGroup: =>
    @contentX = @contentDX
    transform_spec = transform: "translate(#{@contentX}, 0)"
    @contentGroup = @svgElement "g", transform_spec
    @el.appendChild @contentGroup
  
  # show and hide callbacks
  toggleChildrenVisible: (evt) =>
    if @visibleChildren().length != @children.length
      @showChildren()
    else
      @hideChildren()

module.DOGWOOD.SVGTreeNode = SVGTreeNode
