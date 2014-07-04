# Tree for a menu with links and subcategories
class MenuTree extends SVGTreeNode

  # @param {object} options see SVGTreeNode
  # @param {String} options.link href for link, if needed
  # @param {String} options.class class for div
  # @param {String} options.id id for div
  # @param {String} options.tag tag for span
  # @param {Number} options.width width of div
  # @param {Number} options.height height of div
  constructor: (options) ->
    @link = options.link
    @class = options.class
    @id = options.id
    @tag = options.tag
    @width = options.width ? 200
    @height = options.height ? 20
    if not @tag?
      if @link?
        @tag = 'a'
      else
        @tag = 'p'
    super options
    if not @parent?
      height = @totalHeight() + @contentHeight() + @outerFramePaddingBottom
      @el.setAttribute "height", "#{height}px"
      @div.setAttribute "height", "#{height}px"

  # Polyfill for Chrome, which seems to overlay hidden
  # elements over visible ones
  animateVisible: (callback=null) =>
    if @isHidden
      newCallback = =>
        @content.innerHTML = ""
        if callback?
          callback()
      super newCallback
    else
      @content.appendChild @contentDiv
      super callback

  # Creates the content for the tree node. Override this to add custom
  # content.
  makeContent: =>
    conf = {}
    if @link?
      conf = {href: @link}
    if @class?
      conf.class = @class
    if @id?
      conf.id = id
    @a = @htmlElement @tag, conf
    @a.innerHTML = @name
    @contentDiv = @htmlElement 'div', {class: @class}
    @contentDiv.appendChild @a
    @content = @svgElement 'foreignObject'
    @contentGroup.appendChild @content
    if not @isHidden
      @content.appendChild @contentDiv
    @contentDiv.style.height = @height
    @contentDiv.style.width = @width
    @content.setAttribute 'width', @width
    @content.setAttribute 'height', @height
    @content.setAttribute 'y', @contentY
    if not @link?
      @contentDiv.addEventListener "click", @toggleChildrenVisible

module.DOGWOOD.MenuTree = MenuTree
