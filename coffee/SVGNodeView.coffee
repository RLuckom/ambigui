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

  # Sets up the view
  constructor: (options) ->
    @children = [] # visible children go in this array
    @hidden = [] # hidden children go in this array
    @referenceChildren = [] # this array holds all children (hidden and
                            # visible) in the order in which they were added
    if not options.parent?
      @x = options.x ? 5
      @y = options.y ? 40
      @indent = options.indent ? 40
      @textDX = options.textDX ? 5
      @textDY = options.textDY ? -10
      @circleRadius = options.circleRadius ? 4
      @circleDY = options.circleDY ? 0
      @nodeHeight = options.nodeHeight ? 35
      @flagpoleLength = @circleDY + @circleRadius
      @isRoot = true
    else
      @parent = options.parent
      @parent.register this
    @name = options.text ? "Root"
    super options

  # @param {String} name text to display in tree
  # @return {SVGNodeView} child nodeview woith name name
  new_child: (name="child") =>
    transform_spec = {
      transform: "translate(#{@indent}, 0)"
    }
    spacer_el = @svgElement "g", transform_spec
    child_el = @svgElement "g"
    spacer_el.appendChild child_el
    @el.appendChild spacer_el
    new SVGNodeView({el: child_el, parent: this, text:name})
    @trigger 'new_child'
    if @isRoot then @updatePosition()

  # puts child in this.children and populates child's members
  #
  # @param {SVGNodeView} child
  register: (child) =>
    @children.push child
    @referenceChildren.push child
    @updateChildren()
    @listenTo child, "new_child", @newChild

  # when there's a new descendant, update all children and pass it up
  # TODO fix dumb name.
  newChild: =>
    @trigger "new_child"
    if @isRoot then @updatePosition()

  # Populates child with correct current values
  #
  # @param {SVGNodeView} child
  # @param {Number} index index of child in this.children
  updateChild: (child, index) =>
    child.x = @x + @indent
    child.y = @y + @nodeHeight * index
    child.indent = @indent
    child.textDX = @textDX
    child.textDY = @textDY
    child.circleRadius = @circleRadius
    child.circleDY = @circleDY
    child.nodeHeight = @nodeHeight
    child.flagpoleLength = @circleDY + @circleRadius

  # recursively updates the position of all descendent elements
  moveChildren: =>
    child.updatePosition() for child in @children

  # Must be called after @parent is set
  initialize: =>
    @line = @makeLine()
    @circle = @makeCircle()
    @circle.addEventListener "click", @circleClick
    @text = @makeText()
    @text.addEventListener "click", @textClick
    @el.appendChild @line
    @el.appendChild @circle
    @el.appendChild @text

  # updates the position of all children.
  updateChildren: =>
    descendants = 0
    for child in @children
      descendants += 1
      @updateChild child, descendants
      descendants += child.numDescendants()

  # animates all elements of this node from their current actual location to
  # their current 'correct' location
  updatePosition: =>
    @updateChildren()
    @moveChildren()
    @animateLine()
    @animateText()
    @animateCircle()

  # Returns the current coordinates to use for the polyline.
  # Sets priorLinePoints to the existing coordinates, if any.
  #
  # @return {string} svg polyline points string
  getLinePoints: =>
    @priorLinePoints = @linePoints
    last = @children[@children.length - 1]
    n = if last then last.numDescendants() else 0
    @flagpoleLength = (@numDescendants() - n) * @nodeHeight
    @linePoints = "#{0} #{@y} #{@indent} #{@y} "
    # CoffeeScript's support for multiline strings is pretty sweet
    # but codo doc generation breaks when it doesn't find a close
    # quote on the same line as opening.
    @linePoints += "#{@indent} #{@y + @flagpoleLength}"
    @priorLinePoints ?= @linePoints
    return @linePoints

  # Counts the descendants of this node
  numDescendants: =>
    n = 0
    for c in @children
      n += c.numDescendants()
    n + @children.length

  # @return {DOM.SVGSVGElement} polyline
  makeLine:  =>
    @svgElement "polyline",  {
      fill: "none",
      points: @getLinePoints(),
      'stroke-width': "2px",
      stroke: "blue"
    }

  # move the line to the correct position
  animateLine: =>
    animationSpec = {
      attributeName: 'points',
      to: @getLinePoints(),
      from: @priorLinePoints,
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    animation = @svgElement "animate", animationSpec
    @line.appendChild animation
    animation.beginElement()

  # creates the textelement in the SVG displaying the node name.
  #
  # @return {DOM.SVGSVGElement} circle
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
  animateText: =>
    animationSpec = {
      attributeName: 'y',
      to: @y + @textDY,
      from: @textY,
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    @textY = @y + @textDY
    animation = @svgElement "animate", animationSpec
    @text.appendChild animation
    animation.beginElement()


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
  animateCircle: =>
    animationSpec = {
      attributeName: 'cy',
      to: @y + @circleDY,
      from: @circleY,
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    @circleY = @y + @circleDY
    animation = @svgElement "animate", animationSpec
    @circle.appendChild animation
    animation.beginElement()

  # Shows the immediate children of this node
  showChildren: =>
    tmp = @children.concat @hidden
    new_children = []
    for c in @referenceChildren
      if c in tmp
        new_children.push c
    @children = new_children
    @updateChildren()
    @hidden = []
    child.spinIn() for child in @children
    @trigger "new_child"
    if @isRoot
      @updatePosition()

  # Hides all visible descendants of this node.
  hideChildren: =>
    f = @hideCallback => @trigger "new_child"
    if @isRoot
      f = @hideCallback @updatePosition
    child.hide(f) for child in @children

  # hides the element and all children
  #
  # @param {Function} callback if given, called with this as param on hide end
  hide: (callback) =>
    if @children.length == 0 then @spinOut => callback this
    cb = @hideCallback => @retractFlagpole => @spinOut => callback this
    child.hide(cb) for child in @children

  # Makes a function that listens for each child to check in, and moves them
  # from the @children array to the @hidden arrray. When all children have
  # called the function, it calls the provided callback.
  #
  # @param {Function} callback if given will be called on animattion end
  hideCallback: (callback) =>
    return (child) =>
      @hidden.push child
      indx = @children.indexOf child
      @children.splice indx, 1
      if @children.length == 0
        callback()

  # Returns the current coordinates to use for a retracted version of
  # the polyline.
  #
  # @return {string} svg polyline points string
  getRetractedLinePoints: =>
    return "#{0} #{@y} #{@indent} #{@y} #{@indent} #{@y}"

  # Retracts the flagpole below the node
  #
  # @param {Function} callback if given will be called on animattion end
  retractFlagpole: (callback) =>
    animationSpec = {
      attributeName: 'points',
      from: @priorLinePoints,
      to: @getRetractedLinePoints(),
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    animation = @svgElement "animate", animationSpec
    @line.appendChild animation
    if callback?
      animation.addEventListener "endEvent", callback
    animation.beginElement()

  # Flips the subnodes to invisible
  #
  # @param {Function} callback if given will be called on animattion end
  spinOut: (callback) =>
    animationSpec = {
      attributeName: 'transform',
      type: "scale",
      from: "1 1",
      to: "0 1",
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    animation = @svgElement "animateTransform", animationSpec
    @el.appendChild animation
    if callback?
      animation.addEventListener "endEvent", callback
    animation.beginElement()

  # Flips the subnodes to visible
  #
  # @param {Function} callback if given will be called on animattion end
  spinIn: (callback) =>

    # please use caution while opening the overhead bins, as their contents may
    # have shifted during flight.
    @circleY = @y + @circleDY
    @circle.setAttribute "cy", @circleY
    @textY = @y + @textDY
    @text.setAttribute "y", @textY
    @priorLinePoints = @getLinePoints()
    @line.setAttribute 'points', @priorLinePoints

    animationSpec = {
      attributeName: 'transform',
      type: "scale",
      from: "0 1",
      to: "1 1",
      dur: "0.4s",
      repeatCount: 1,
      begin: "indefinite",
      fill: "freeze"
    }
    animation = @svgElement "animateTransform", animationSpec
    @el.appendChild animation
    if callback?
      animation.addEventListener "endEvent", callback
    animation.beginElement()

  # using "click the circle" to test out a few behaviors I'll want later.
  circleClick: (evt) =>
    @new_child()
  
  # demo show and hide callbacks
  textClick: (evt) =>
    if @hidden.length != 0
      @showChildren()
    else
      @hideChildren()

module.SVGNodeView = SVGNodeView

module.drawSVG = drawSVG
