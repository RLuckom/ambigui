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
    attributes.xmlns ?= "http://www.w3.org/2000/svg"
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
    if spec.attributeName in ['y', 'cy']
      formatter = (x) -> "#{x}px"
      @animation(
        parentElement, spec.attributeName, spec.from,
        spec.to, 20, duration, formatter, callback
      )()
    if spec.attributeName == 'points'
      from = (parseInt(x) for x in spec.from.split ' ')
      to = (parseInt(x) for x in spec.to.split ' ')
      formatter = (x) ->
        x.join ' '
      @animation(
        parentElement, spec.attributeName, from,
        to, 20, duration, formatter, callback
      )()
    if spec.attributeName == 'transform'
      from = (parseInt(x) for x in spec.from.split ' ')
      to = (parseInt(x) for x in spec.to.split ' ')
      formatter = (x) ->
        "#{spec.type}(#{x.join ' '})"
      @animation(
        parentElement, spec.attributeName, from,
        to, 20, duration, formatter, callback
      )()

  # returns data about the tree
  toString: =>
    s = "name: #{@name}\n isHidden: #{@isHidden} x: #{@x} y: #{@y}"
    s += " textDX: #{@textDX} textDY: #{@textDY} textX: #{@textX}"
    s += " textY: #{@textY} linePoints: #{@linePoints} circleX: #{@circleX}"
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
  # @param {SVGTreeNode} options.parent If provided, used to populate members.
  # @param {String} options.text the text to display on the node.
  # @param {Number} model.indent x-distance to translate per generation.
  # @param {Number} model.textDX x-offset of the text from 0 in the node-frame.
  # @param {Number} model.textDY y-offset of the text from 0 in the node-frame.
  # @param {Number} model.circleRadius radius of end circle.
  # @param {Number} model.circleDY y-offset of circle from node-frame origin.
  # @param {Number} model.nodeHeight dy by which to translate for each node.
  # @param {Number} model.animateDuration time to allow for animations.
  # @param {Bool} options.isHidden whether to display the node
  # @param {String} model.treeColor color for circle when children are shown
  constructor: (options) ->
    @el = options.el
    @children = []
    model = options.parent ? options
    @name = options.text ? "Root"
    @indent = model.indent ? 40
    @textDX = model.textDX ? 5
    @textDY = model.textDY ? -10
    @circleRadius = model.circleRadius ? 4
    @circleDY = model.circleDY ? 0
    @nodeHeight = model.nodeHeight ? 35
    @flagpoleLength = @circleDY + @circleRadius
    @animateDuration = model.animateDuration ? 400
    @isHidden = options.isHidden ? false
    @scale = if @isHidden then "0 1" else "1 1"
    @emptyColor = model.emptyColor ? 'white'
    @treeColor = model.treeColor ? 'blue'
    @x = options.x ? 5
    @y = options.y ? 40
    if options.parent?
      @parent = options.parent
    else
      @isRoot = true
    @makeLine()
    @makeText()
    if @isHidden and options.children?
      @circleY = @y + @circleDY
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
      options.y = @y + @numDescendants() * @nodeHeight
    child = new SVGTreeNode options
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
    @moveChildren()
    @move()

  move: =>
    @animateLine()
    @animateText()
    @animateCircle()
    @animateVisible()

  # updates the position of all children.
  updateChildren: =>
    descendants = 0
    for child in @children
      descendants += 1
      @updateChild child, descendants
      descendants += child.numDescendants()

  # Populates child with correct current values
  #
  # @param {SVGTreeNode} child
  # @param {Number} index index of child in this.children
  updateChild: (child, index) =>
    child.x = @x + @indent
    child.y = if not child.isHidden then @y + @nodeHeight * index else @y

  # recursively updates the position of all descendent elements
  #
  # @param {Function} callback if given will be called on animation end
  moveChildren: (callback=null) =>
    if @children.length == 0 and callback?
      callback()
    child.updatePosition(callback) for child in @children

  # Returns the current coordinates to use for the polyline.
  # Sets priorLinePoints to the existing coordinates, if any.
  #
  # @return {String} svg polyline points string
  getLinePoints: =>
    last = @children[@children.length - 1]
    n = if last then last.numDescendants() else 0
    @flagpoleLength = (@numDescendants() - n) * @nodeHeight
    return "#{0} #{@y} #{@indent} #{@y} #{@indent} #{@y + @flagpoleLength}"

  # Counts the descendants of this node
  numDescendants: =>
    n = 0
    for c in @children
      if not c.isHidden
        n += c.numDescendants() + 1
    return n

  # @return {DOM.SVGSVGElement} polyline
  makeLine:  =>
    @linePoints = @getLinePoints()
    @line = @svgElement "polyline",  {
      fill: "none",
      points: @linePoints,
      'stroke-width': "2px",
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
    @animateElement(
      {attributeName: 'points', from: @linePoints, to: newPoints},
      @line,
      callback
    )
    @linePoints = newPoints

  # creates the textelement in the SVG displaying the node name.
  #
  # Note that assigning to innerHTML is not supported in SVG even on relatively
  # recent browsers. It is safest to add text by using document.createTextNode.
  #
  # @return {DOM.SVGSVGElement} text node
  makeText: =>
    @textX = @textDX
    @textY = @y + @textDY
    @text = @svgElement "text", {
      fill: "black",
      x: @textDX,
      y: @y + @textDY
    }
    @text.appendChild document.createTextNode @name
    @text.addEventListener "click", @textClick
    @el.appendChild @text

  # move the text to the correct position
  #
  # @param {Function} callback if given will be called on animation end
  animateText: (callback=null) =>
    if not @text?
      if @isHidden
        return
      @makeText()
    newY = @y + @textDY
    @animateElement(
      {attributeName: 'y', to: newY, from: @textY}, @text, callback
    )
    @textY = newY

  # @return {DOM.SVGSVGElement} circle
  makeCircle: =>
    @circleX = @indent
    @circleY ?= @y + @circleDY
    @circle = @svgElement "circle", {
      fill: @treeColor,
      cx: @indent,
      cy: @y + @circleDY,
      r: @circleRadius,
      "stroke-width": "2px",
      stroke: @treeColor
    }
    @circle.addEventListener "click", @circleClick
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
    new_cy = @y + @circleDY
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

  # using "click the circle" to test out a few behaviors I'll want later.
  textClick: (evt) =>
    options = {}
    if @visibleChildren().length != @children.length
      options.isHidden = true
    @newChild(options)
    if options.isHidden
      @showChildren()
  
  # demo show and hide callbacks
  circleClick: (evt) =>
    if @visibleChildren().length != @children.length
      @showChildren()
    else
      @hideChildren()

module.SVGTreeNode = SVGTreeNode

module.drawSVG = drawSVG
