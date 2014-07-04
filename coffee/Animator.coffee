registerGlobal 'ambigui', module

#refactoring shim
class Animator

  # Polyfill requestAnimationFrame
  constructor: ->
    for x in ['ms', 'moz', 'o', 'webkit']
      if not window.requestAnimationFrame?
        window.requestAnimationFrame = window[x + 'RequestAnimationFrame']
    if not window.requestAnimationFrame?
      @animation = @fallbackAnimation

  # find numbers in strings.
  #
  valAndFormatArrays: (s) ->
    num_chars = '-+.eE0123456789'.split('')
    chars = s.split('')
    chars.reverse()
    format_section = ''
    num_candidate = ''
    numbers = []
    formatting = []
    numIndexToFormattingIndex = {}
    while chars.length != 0
      while chars[chars.length - 1] in num_chars and chars.length > 0
        num_candidate += chars.pop()
      while (not (chars[chars.length - 1] in num_chars)) and (chars.length > 0)
        format_section += chars.pop()
      if (not isNaN(Number(num_candidate))) and (num_candidate.length > 0)
        numIndexToFormattingIndex[numbers.length] = formatting.length
        numbers.push(parseFloat(num_candidate))
        formatting.push(null)
        num_candidate = ''
      else if num_candidate.length > 0
        format_section = formatting.pop() + num_candidate + format_section
        num_candidate = ''
      if format_section.length > 0
        formatting.push(format_section)
        format_section = ''
    return [numbers, formatting, numIndexToFormattingIndex]

  # make a function that takes an array of numbers and inserts them into the
  # format string correctly,
  #
  # @param {Array} numbers numbers to insert
  # @param {Array} formatting formatting in which to put numbers
  makeFormatter: (formatting, numIndexToFormattingIndex) ->
    return (num_array) ->
      fmt_copy  = (x for x in formatting)
      for n, indx in num_array
        fmt_copy[numIndexToFormattingIndex[indx]] = n
      sum = (s1, s2) -> s1 + s2
      return fmt_copy.reduce(sum, '')

  # Makes a function that takes a percent and returns that percent
  # interpolation between the fromValues and toValues.
  #
  # @param {Number or Array} fromValues if Array, must be of Numbers
  # @param {Number or Array} toValues if Array, must be of Numbers
  # @return {Function} given %, returns fromValues + (toValues - fromValues) * %
  interpolation: (fromValues, toValues) ->
    if (fromValues instanceof Array) and (toValues instanceof Array)
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
  # @param {Number} duration time for animation to last
  # @param {Function} callback if given, will be executed after animation
  animation: (el, attr, from, to, duration, callback) ->
    [fromVals, fromFmt, fromMap] = @valAndFormatArrays(from)
    [toVals, toFmt, toMap] = @valAndFormatArrays(to)
    formatter = @makeFormatter(fromFmt, fromMap)
    transition = @transition el, attr, fromVals, toVals, formatter
    startTime = null
    f = (t) ->
      if not t?
        window.requestAnimationFrame f
        return
      startTime ?= t
      dT = t - startTime
      if dT >= duration
        transition 1
        callback() if callback?
      else
        transition dT / duration
        window.requestAnimationFrame f
    return f
  
  # Returns a function f that will animate the element from the from state
  # to the to state over the duration.
  #
  # @param {DOMNode} el element to transition
  # @param {String} attr attribute of node to transition
  # @param {Number or Array} fromValues if Array, must be of Numbers
  # @param {Number or Array} toValues if Array, must be of Numbers
  # @param {Number} duration time for animation to last
  # @param {Function} callback if given, will be executed after animation
  fallbackAnimation: (el, attr, from, to, duration, callback) ->
    [fromVals, fromFmt, fromMap] = @valAndFormatArrays(from)
    [toVals, toFmt, toMap] = @valAndFormatArrays(to)
    formatter = @makeFormatter(fromFmt, fromMap)
    transition = @transition el, attr, fromVals, toVals, formatter
    startTime = null
    f = ->
      t = new Date().getTime()
      startTime ?= t
      dT = t - startTime
      if dT >= duration
        transition 1
        callback() if callback?
      else
        transition dT / duration
        window.setTimeout f, 16
    return f

module.Animator = Animator
