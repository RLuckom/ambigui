registerGlobal 'DOGWOOD', module

# Populates the svg handlebars template
drawSVG = ->
  svg = document.createElementNS("http://www.w3.org/2000/svg", 'svg')
  svg.setAttribute 'style', "width: 600px; height:500px;"
  document.getElementById("svgDiv").appendChild svg
  x = new SVGNodeView(el: svg)

# View to manage a single node on the tree of the scene graph
class SVGNodeView extends Backbone.View

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

  interpolation: (fromValues, toValues) ->
    if isNaN(fromValues) and isNaN(toValues)
      diffs = (t - fromValues[i] for t, i in toValues)
      return (percent) ->
        f + diffs[i] * percent for f, i in fromValues
    else
      diff = toValues - fromValues
      return (percent) -> fromValues + diff * percent

  transition: (el, attr, fromValues, toValues, formatter) ->
    interpolator = @interpolation fromValues, toValues
    return (percent) ->
      el.setAttribute attr, formatter interpolator percent

  animation: (el, attr, from, to, step, duration, formatter, callback) ->
    transition = @transition el, attr, from, to, formatter
    d = new Date()
    startTime = d.getTime()
    f = ->
      dT = new Date().getTime() - startTime
      if dT >= duration
        transition 1
        callback() if callback?
      else
        transition dT / duration
        window.setTimeout f, step
    f.start = -> startTime = new Date().getTime()
    f.reset = (newFrom=from, newTo=to, newDuration=duration, newStep=step) ->
      transition = @transition el, attr, newFrom, newTo, formatter
      duration = newDuration
      step = newStep
    return f
  
  # creates an animation element from attributes in spec,
  # appends it to element parent, and if given, sets callback to fire when the
  # animation finishes
  #
  # @param {Object} spec dur, repeatCount, fill, and begin have auto values
  # @param {SVGElement} parentElement element to be animated
  # @param {Function} callback if given, will be executed after animation
  # @param {String} animType defaults to 'animate'.
  animateElement: (spec, parentElement, callback=null, animType="animate") =>
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

    #spec.dur ?= @animateDuration
    #spec.repeatCount ?= 1
    #spec.fill ?= "freeze"
    #spec.begin ?= "indefinite"
    #animation = @svgElement animType, spec
    #if callback?
    #  animation.addEventListener "endEvent", callback
    #parentElement.appendChild animation
    #animation.beginElement()

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
  # @param {SVGNodeView} options.parent If provided, used to populate members.
  # @param {String} options.text the text to display on the node.
  # @param {Number} model.indent x-distance to translate per generation.
  # @param {Number} model.textDX x-offset of the text from 0 in the node-frame.
  # @param {Number} model.textDY y-offset of the text from 0 in the node-frame.
  # @param {Number} model.circleRadius radius of end circle.
  # @param {Number} model.circleDY y-offset of circle from node-frame origin.
  # @param {Number} model.nodeHeight dy by which to translate for each node.
  # @param {Number} model.animateDuration time to allow for animations.
  # @param {Bool} model.isHidden whether to display the node
  constructor: (options) ->
    super options
    @children = []
    @scale = '1 1'
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
    @isHidden = model.isHidden ? false
    if options.parent?
      @parent = options.parent
    else
      @isRoot = true
    @x = options.x ? 5
    @y = options.y ? 40
    @line = @makeLine()
    @circle = @makeCircle()
    @circle.addEventListener "click", @circleClick
    @text = @makeText()
    @text.addEventListener "click", @textClick
    @el.appendChild @line
    @el.appendChild @circle
    @el.appendChild @text

  # @param {String} name text to display in tree
  # @return {SVGNodeView} child nodeview with name name
  newChild: (name="child") =>
    child.isHidden = false for child in @children
    transform_spec = transform: "translate(#{@indent}, 0)"
    spacer_el = @svgElement "g", transform_spec
    child_el = @svgElement "g"
    spacer_el.appendChild child_el
    @el.appendChild spacer_el
    child_spec = {
      el: child_el,
      parent: this,
      text:name,
      x: @x + @indent,
      y: @y + @numDescendants() * @nodeHeight
    }
    child = new SVGNodeView child_spec
    @children.push child
    @listenTo child, "request_update", @requestUpdate
    @trigger 'request_update'
    if @isRoot then @updatePosition()

  # request gets passed up the chain, root calls update.
  requestUpdate: () =>
    if not @isRoot
      @trigger "request_update"
    else
      @updatePosition()

  # animates all elements of this node from their current actual location to
  # their current 'correct' location
  updatePosition: (callback=null) =>
    @updateChildren()
    @moveChildren()
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
  # @param {SVGNodeView} child
  # @param {Number} index index of child in this.children
  updateChild: (child, index) =>
    child.x = @x + @indent
    child.y = if not child.isHidden then @y + @nodeHeight * index else @y

  # recursively updates the position of all descendent elements
  #
  # @param {Function} callback if given will be called on animattion end
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
    @svgElement "polyline",  {
      fill: "none",
      points: @linePoints,
      'stroke-width': "2px",
      stroke: "blue"
    }

  # move the line to the correct position
  #
  # @param {Function} callback if given will be called on animattion end
  animateLine: (callback=null)=>
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
    t = @svgElement "text", {
      fill: "black",
      x: @textDX,
      y: @y + @textDY
    }
    t.appendChild document.createTextNode @name
    return t

  # move the text to the correct position
  #
  # @param {Function} callback if given will be called on animattion end
  animateText: (callback=null) =>
    newY = @y + @textDY
    @animateElement(
      {attributeName: 'y', to: newY, from: @textY}, @text, callback
    )
    @textY = newY

  # @return {DOM.SVGSVGElement} circle
  makeCircle: =>
    @circleX = @indent
    @circleY = @y + @circleDY
    @svgElement "circle", {
      fill: "blue",
      cx: @indent,
      cy: @y + @circleDY,
      r: @circleRadius,
      "stroke-width": "2px",
      stroke: "blue"
    }

  # move the circle to the correct position
  #
  # @param {Function} callback if given will be called on animattion end
  animateCircle: (callback=null) =>
    new_cy = @y + @circleDY
    @animateElement(
      {attributeName: 'cy', to: new_cy, from: @circleY}, @circle, callback
    )
    @circleY = new_cy

  # Shows the immediate children of this node
  showChildren: =>
    for child in @children
      child.isHidden = false
    @updateChildren()
    @trigger "request_update"
    if @isRoot
      @updatePosition()

  # Hides all visible descendants of this node.
  hideChildren: =>
    test = => @visibleChildren().length == 0
    trigger = => @trigger "request_update"
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
  # @param {Function} callback if given will be called on animattion end
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
    @animateElement spec, @el, callback, 'animateTransform'

  # using "click the circle" to test out a few behaviors I'll want later.
  circleClick: (evt) =>
    @newChild()
  
  # demo show and hide callbacks
  textClick: (evt) =>
    if @visibleChildren().length != @children.length
      @showChildren()
    else
      @hideChildren()

module.SVGNodeView = SVGNodeView

module.drawSVG = drawSVG
