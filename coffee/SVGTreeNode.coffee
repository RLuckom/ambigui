registerGlobal 'DOGWOOD', module

# Recursive tree node.
class SVGTreeNode

  # Creates a tag element in the svg namespace
  #
  # @param {String} tag tag type e.g. 'svg' 'path' 'rect
  # @param {Object} attributes key-value pairs to be set as attributes
  svgElement: (tag, attributes={}) ->
    el = document.createElementNS("http://www.w3.org/2000/svg", tag)
    attributes.version ?= "1.1"
    attributes.xmlns = "http://www.w3.org/2000/svg"
    for attr, value of attributes
      el.setAttribute(attr, value)
    return el

  # Creates a tag element in the svg namespace
  #
  # @param {String} tag tag type e.g. 'svg' 'path' 'rect
  # @param {Object} attributes key-value pairs to be set as attributes
  htmlElement: (tag, attributes={}) ->
    el = document.createElementNS("http://www.w3.org/1999/xhtml", tag)
    attributes.xmlns = "http://www.w3.org/1999/xhtml"
    for attr, value of attributes
      el.setAttribute(attr, value)
    return el

  # Makes a function that takes a percent and returns that percent
  # interpolation between the fromValues and toValues.
  #
  # @param {Number or Array} fromValues if Array, must be of Numbers
  # @param {Number or Array} toValues if Array, must be of Numbers
  # @return {Function} given %, returns fromValues + (toValues - fromValues) * %
  interpolation: (fromValues, toValues) ->
    if isNaN(fromValues) and isNaN(toValues)
      diffs = (t - fromValues[i] for t, i in toValues)
      return (percent) ->
        f + diffs[i] * percent for f, i in fromValues
    else
      diff = toValues - fromValues
      return (percent) -> fromValues + diff * percent

  # Returns a function that takes a percent p and sets the specified
  # attribute on the specified element to from + (to - from) * p
  #
  # formatter is a function that takes an array of values and puts them in the
  # format required by the attribute. For instance, a formatter for a color
  # attribute might be:
  #
  # formatter = (arr)-> "rgb(#{arr.join(',')})"
  #
  # @param {DOMNode} el element to transition
  # @param {String} attr attribute of node to transition
  # @param {Number or Array} fromValues if Array, must be of Numbers
  # @param {Number or Array} toValues if Array, must be of Numbers
  # @param {Function} formatter see above
  transition: (el, attr, fromValues, toValues, formatter) ->
    interpolator = @interpolation fromValues, toValues
    return (percent) ->
      el.setAttribute attr, formatter interpolator percent

  # Returns a function f that will animate the element from the from state
  # to the to state over the duration.
  #
  # @param {DOMNode} el element to transition
  # @param {String} attr attribute of node to transition
  # @param {Number or Array} fromValues if Array, must be of Numbers
  # @param {Number or Array} toValues if Array, must be of Numbers
  # @param {Function} formatter see transition
  # @param {Function} callback if given, will be executed after animation
  animation: (el, attr, from, to, step, duration, formatter, callback) ->
    transition = @transition el, attr, from, to, formatter
    startTime = null
    f = ->
      startTime ?= new Date().getTime()
      dT = new Date().getTime() - startTime
      if dT >= duration
        transition 1
        callback() if callback?
      else
        transition dT / duration
        window.setTimeout f, step
    return f
  
  # creates an animation element from attributes in spec,
  # appends it to element parent, and if given, sets callback to fire when the
  # animation finishes
  #
  # @param {Object} spec dur, repeatCount, fill, and begin have auto values
  # @param {SVGElement} parentElement element to be animated
  # @param {Function} callback if given, will be executed after animation
  animateElement: (spec, parentElement, callback=null) =>
    duration = @animateDuration
    if spec.attributeName in ['y', 'cy', 'height', 'y1', 'y2']
      formatter = (x) -> "#{x}px"
      @animation(
        parentElement, spec.attributeName, spec.from,
        spec.to, @frameLength, duration, formatter, callback
      )()
    if spec.attributeName == 'points'
      from = (parseInt(x) for x in spec.from.split ' ')
      to = (parseInt(x) for x in spec.to.split ' ')
      formatter = (x) -> x.join ' '
      @animation(
        parentElement, spec.attributeName, from,
        to, @frameLength, duration, formatter, callback
      )()
    if spec.attributeName == 'transform'
      from = (parseInt(x) for x in spec.from.split ' ')
      to = (parseInt(x) for x in spec.to.split ' ')
      formatter = (x) -> "#{spec.type}(#{x.join ' '})"
      @animation(
        parentElement, spec.attributeName, from,
        to, @frameLength, duration, formatter, callback
      )()

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
  # @param {Number} options.x x-coord
  # @param {Number} options.y y-coord
  # @param {SVGTreeNode} options.parent If provided, used to populate members.
  # @param {String} options.text the text to display on the node.
  # @param {Number} model.indent x-distance to translate per generation.
  # @param {Number} model.textDX x-offset of the text from 0 in the node-frame.
  # @param {Number} model.elementOffset y-offset of the element from node-0.
  # @param {Number} model.circleRadius radius of end circle.
  # @param {Number} model.animateDuration time to allow for animations.
  # @param {number} model.lineWidth width of lines
  # @param {Bool} model.newStar Whether to use a star to create children
  # @param {Number} model.starLength drop distance of star
  # @param {Number} model.starRadius redius of star
  # @param {String} model.treeColor color for circle when children are shown
  constructor: (options) ->
    @children = []
    model = options.parent ? options
    @name = options.text ? "Root"
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
    @newStar = model.newStar ? false
    @lineWidth = model.lineWidth ? 2
    @starLength = if @newStar then model.starLength ? 15 else 0
    @starRadius = if @newStar then model.starRadius ? 5 else 0
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
    if @newStar
      @makeStar()
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
    options.text ?= 'child'
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
    if not @parent?
      @updateOuterFrame()
    @moveChildren()
    @move()

  # Updates the height of the frame containing the tree based on how
  # much space the tree needs.
  updateOuterFrame: =>
    n = @div.offsetHeight
    if n != @totalHeight() + @contentHeight() + @outerFramePaddingBottom
      height = @totalHeight() + @contentHeight() + @outerFramePaddingBottom
      @animateElement(
        {attributeName: 'height', from: n, to: height},
        @div,
      )
      @animateElement(
        {attributeName: 'height', from: n, to: height},
        @el,
      )

  # Updates the position and form of the node.
  move: =>
    if @newStar
      @animateStar()
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
    n = @marginTop + @contentHeight() + @marginBottom + @starLength
    n += child.totalHeight() for child in @visibleChildren()
    return n

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

  # @return {Object} current x1, y1, x2, y2 for line to star
  getStarLinePoints: =>
    top = (@y + @flagpoleLength() +
      + @marginTop + @contentHeight() + @marginBottom)
    {x1: @indent, y1: top, x2: @indent, y2: top + @starLength}

  # Assembles the star, appends to @el. binds createChild
  makeStar: =>
    @starLinePoints = @getStarLinePoints()
    @starLinePoints.fill = "none"
    @starLinePoints.stroke = @treeColor
    @starLinePoints['stroke-width'] = "#{@lineWidth}px"
    @starLine = @svgElement "line", @starLinePoints
    @el.appendChild @starLine
    @star = @svgElement('g', {
      transform: "translate(#{@indent}, #{@starLinePoints.y2})"
    })
    diff = Math.sqrt @starRadius * @starRadius / 2
    diag1 = {
      x1: -diff, y1: diff, x2: diff, y2:-diff,
      fill:"none", "stroke-width": "#{@lineWidth / 2}px", 'stroke': @treeColor
    }
    @star.appendChild @svgElement 'line', diag1
    diag2 = {
      x1: -diff, y1: -diff, x2: diff, y2:diff,
      fill:"none", "stroke-width": "#{@lineWidth / 2}px", 'stroke': @treeColor
    }
    @star.appendChild @svgElement 'line', diag2
    cross1 = {
      x1: @starRadius, y1: 0, x2: -@starRadius, y2:0,
      fill:"none", "stroke-width": "#{@lineWidth / 2}px", 'stroke': @treeColor
    }
    @star.appendChild @svgElement 'line', cross1
    cross2 = {
      x1: 0, y1: @starRadius, x2: 0, y2: -@starRadius,
      fill:"none", "stroke-width": "#{@lineWidth / 2}px", 'stroke': @treeColor
    }
    @star.appendChild @svgElement 'line', cross2
    c =  {cx: 0, cy: 0, r: @starRadius, opacity: 0}
    @star.appendChild @svgElement "circle", c
    @star.addEventListener "click", @createChild
    @el.appendChild @star
    
  # Moves the starLine and star to the current correct position
  animateStar: (callback=null) =>
    if not @starLine?
      if @isHidden
        @starLinePoints = @getStarLinePoints()
        return
      @makeStar()
    newStarLinePoints = @getStarLinePoints()
    @animateElement(
      {attributeName: 'y1', from: @starLinePoints.y1, to: newStarLinePoints.y1},
      @starLine, callback
    )
    @animateElement(
      {attributeName: 'y2', from: @starLinePoints.y2, to: newStarLinePoints.y2},
      @starLine, null
    )
    n = {
      attributeName: 'transform'
      from: "#{@indent} #{@starLinePoints.y2}"
      to: "#{@indent} #{newStarLinePoints.y2}"
      type: "translate"
    }
    @animateElement n, @star, null
    @starLinePoints = newStarLinePoints
      
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
    @animateElement(
      {attributeName: 'points', from: @linePoints, to: newPoints},
      @line,
      callback
    )
    @linePoints = newPoints

  # move the text to the correct position
  #
  # @param {Function} callback if given will be called on animation end
  animateContent: (callback=null) =>
    newY = @y + @marginTop
    @animateElement(
      {attributeName: 'y', to: newY, from: @contentY}, @content, callback
    )
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
    @animateElement(
      {attributeName: 'cy', to: new_cy, from: @circleY}, @circle, callback
    )
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
    spec = {
      attributeName: 'transform',
      type: 'scale',
      from: @scale,
      to: newScale
    }
    @scale = newScale
    @animateElement spec, @el, callback

  # The ContentGroup is an svg 'g' element that holds the content. This
  # sets it up. Should be called before attempting to make the content.
  makeContentGroup: =>
    @contentX = 2 * @contentDX
    transform_spec = transform: "translate(#{@contentX}, 0)"
    @contentGroup = @svgElement "g", transform_spec
    @el.appendChild @contentGroup
  
  # show and hide callbacks
  toggleChildrenVisible: (evt) =>
    if @visibleChildren().length != @children.length
      @showChildren()
    else
      @hideChildren()

module.SVGTreeNode = SVGTreeNode
