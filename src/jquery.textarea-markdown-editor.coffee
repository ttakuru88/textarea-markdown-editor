KeyCodes =
  tab: 9
  enter: 13

class MarkdownEditor
  listFormat = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/

  constructor: (@el, @options) ->
    @$el = $(@el)

    @tabSpaces = ''
    @tabSpaces += ' ' for i in [0...@options.tabSize]

    @$el.on 'keydown', (e) =>
      @supportInputListFormat(e) if @options.list
      @tabToSpace(e) if @options.tabToSpace

  getTextArray: ->
    @$el.val().split('')

  supportInputListFormat: (e) ->
    return if e.keyCode != KeyCodes.enter || e.shiftKey

    text = @getTextArray()

    currentLine = @getCurrentLine(text)

    match = currentLine.match(listFormat)
    return if !match
    if match[5].length <= 0
      @removeCurrentLine(text)
      return

    extSpace = if e.ctrlKey then @tabSpaces else ''

    @insert(text, "\n#{extSpace}#{match[1]}")

    e.preventDefault()

    @options.onInsertedList?(e)

  getCurrentLine: (textArray = @getTextArray()) ->
    pos = @currentPos() - 1
    beforeChars = ''
    while textArray[pos] && textArray[pos] != "\n"
      beforeChars = "#{textArray[pos]}#{beforeChars}"
      pos--

    pos = @currentPos()
    afterChars = ''
    while textArray[pos] && textArray[pos] != "\n"
      afterChars = "#{afterChars}#{textArray[pos]}"
      pos++

    "#{beforeChars}#{afterChars}"

  removeCurrentLine: (textArray) ->
    endPos = @currentPos()
    beginPos = @getHeadPos(textArray, endPos)

    removeLength = endPos - beginPos
    textArray.splice(beginPos, removeLength)

    @$el.val(textArray.join(''))
    @el.setSelectionRange(beginPos , beginPos)

  tabToSpace: (e) =>
    return if e.keyCode != KeyCodes.tab
    e.preventDefault()

    text = @getTextArray()
    currentLine = @getCurrentLine(text)
    if currentLine.match(listFormat)
      pos = @getHeadPos(text)

      if e.shiftKey
        @removeSpaces(text, pos) if currentLine.indexOf(@tabSpaces) == 0
      else
        @insertSpaces(text, pos)
    else
      @insert(text, @tabSpaces)

  insertSpaces: (text, pos) ->
    nextPos = @currentPos() + @tabSpaces.length

    @insert(text, @tabSpaces, pos)
    @el.setSelectionRange(nextPos, nextPos)

  removeSpaces: (text, pos) ->
    text.splice(pos, @tabSpaces.length)
    pos = @currentPos() - @tabSpaces.length

    @$el.val(text.join(''))
    @el.setSelectionRange(pos, pos)

  getHeadPos: (textArray, pos = @currentPos()) ->
    pos-- while pos > 0 && textArray[pos-1] != "\n"
    pos

  insert: (textArray, insertText, pos = @currentPos()) ->
    textArray.splice(pos, 0, insertText)
    @$el.val(textArray.join(''))

    pos += insertText.length
    @el.setSelectionRange(pos, pos)

  currentPos: ->
    @$el.caret('pos')

$.fn.markdownEditor = (options = {}, args = undefined) ->
  if typeof options == 'string'
    @each ->
      $(@).data('markdownEditor')[options]?(args)
  else
    options = $.extend
      tabSize: 2
      onInsertedList: null
      tabToSpace: true
      list: true
    , options

    @each ->
      $(@).data('markdownEditor', new MarkdownEditor(@, options))

    @
