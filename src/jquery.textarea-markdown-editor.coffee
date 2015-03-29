KeyCodes =
  tab: 9
  enter: 13

class MarkdownEditor
  listFormat     = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/
  hrFormat       = /^\s*((-\s+-\s+-(\s+-)*)|(\*\s+\*\s+\*(\s+\*)*))\s*$/
  rowFormat      = /^\|(.*?\|)+\s*$/
  rowSepFormat   = /^\|(\s*:?---+:?\s*\|)+\s*$/
  emptyRowFormat = /^\|(\s*?\|)+\s*$/

  constructor: (@el, @options) ->
    @$el = $(@el)

    @selectionBegin = @selectionEnd = 0

    @tabSpaces = ''
    @tabSpaces += ' ' for i in [0...@options.tabSize]

    @$el.on 'keydown.markdownEditor', (e) =>
      @supportInputListFormat(e) if @options.list
      @supportInputTableFormat(e) if @options.table
      @tabToSpace(e)

  getTextArray: ->
    @getText().split('')

  getText: ->
    @$el.val()

  supportInputListFormat: (e) ->
    return if e.keyCode != KeyCodes.enter || e.shiftKey

    text = @getTextArray()

    currentLine = @getCurrentLine(text)
    return if currentLine.match(hrFormat)

    match = currentLine.match(listFormat)
    return unless match
    if match[5].length <= 0
      @removeCurrentLine(text)
      return

    extSpace = if e.ctrlKey then @tabSpaces else ''

    @insert(text, "\n#{extSpace}#{match[1]}")

    e.preventDefault()

    @options.onInsertedList?(e)

  supportInputTableFormat: (e) ->
    return if e.keyCode != KeyCodes.enter || e.shiftKey

    text = @getTextArray()
    currentLine = @replaceEscapedPipe @getCurrentLine(text)
    match = currentLine.match(rowFormat)
    return unless match
    if currentLine.match(emptyRowFormat) && @isTableBody(text)
      @removeCurrentLine(text)
      return

    e.preventDefault()

    rows = -1
    for char in currentLine
      rows++ if char == '|'

    prevPos = @getPosEndOfLine(text)
    sep = ''
    unless @isTableBody(text)
      sep = "\n|"
      for i in [0...rows]
        sep += ' --- |'

    row = "\n|"
    for i in [0...rows]
      row += '  |'

    text = @insert(text, sep + row, prevPos)

    pos = prevPos + sep.length + row.length - rows * 3 + 1
    @setSelectionRange(pos, pos)

  setSelectionRange: (@selectionBegin, @selectionEnd) ->
    @el.setSelectionRange(@selectionBegin, @selectionEnd)

  replaceEscapedPipe: (text) ->
    text.replace(/\\\|/g, '..')

  isTableBody: (textArray = @getTextArray(), pos = @currentPos() - 1) ->
    line = @replaceEscapedPipe @getCurrentLine(textArray, pos)
    while line.match(rowFormat) && pos > 0
      return true if line.match(rowSepFormat)
      pos = @getPosBeginningOfLine(textArray, pos) - 2
      line = @replaceEscapedPipe @getCurrentLine(textArray, pos)

    false

  getPrevLine: (textArray, pos = @currentPos() - 1) ->
    pos = @getPosBeginningOfLine(textArray, pos)
    @getCurrentLine(textArray, pos - 2)

  getPosEndOfLine: (textArray, pos = @currentPos()) ->
    pos++ while textArray[pos] && textArray[pos] != "\n"
    pos

  getPosBeginningOfLine: (textArray, pos = @currentPos()) ->
    pos-- while textArray[pos-1] && textArray[pos-1] != "\n"
    pos

  getCurrentLine: (textArray = @getTextArray(), pos = @currentPos() - 1) ->
    initPos = pos

    beforeChars = ''
    while textArray[pos] && textArray[pos] != "\n"
      beforeChars = "#{textArray[pos]}#{beforeChars}"
      pos--

    pos = initPos + 1
    afterChars = ''
    while textArray[pos] && textArray[pos] != "\n"
      afterChars = "#{afterChars}#{textArray[pos]}"
      pos++

    "#{beforeChars}#{afterChars}"

  removeCurrentLine: (textArray) ->
    endPos   = @getPosEndOfLine(textArray)
    beginPos = @getPosBeginningOfLine(textArray)

    removeLength = endPos - beginPos
    textArray.splice(beginPos, removeLength)

    @$el.val(textArray.join(''))
    @setSelectionRange(beginPos, beginPos)

  tabToSpace: (e) =>
    return if e.keyCode != KeyCodes.tab
    e.preventDefault()

    if @options.table
      text = @replaceEscapedPipe(@getText())
      currentLine = @getCurrentLine(text)

      if currentLine.match(rowFormat)
        if e.shiftKey
          @moveToPrevCell(text)
        else
          @moveToNextCell(text)

        return

    if @options.tabToSpace
      text = @getTextArray()
      currentLine = @getCurrentLine(text)

      if @options.list && currentLine.match(listFormat)
        pos = @getPosBeginningOfLine(text)

        if e.shiftKey
          @removeSpaces(text, pos) if currentLine.indexOf(@tabSpaces) == 0
        else
          @insertSpaces(text, pos)
      else
        @insert(text, @tabSpaces)

  moveToPrevCell: (text, pos = @currentPos() - 1) ->
    overSep = false
    prevLine = false
    ep = pos

    while text[ep]
      return false if overSep && ep < 0 || !overSep && ep <= 0
      return false if prevLine && text[ep] != ' ' && text[ep] != '|'

      if !overSep
        if text[ep] == '|'
          overSep = true
          prevLine = false
      else if text[ep] != ' '
        if text[ep] == "\n"
          overSep = false
          prevLine = true
        else
          ep++ if text[ep] == '|'
          ep++ if text[ep] == ' '
          break
      ep--
    return false if ep < 0

    ssp = sp = ep
    epAdded = false
    while text[sp] && text[sp] != '|'
      if text[sp] != ' '
        ssp = sp
        unless epAdded
          ep++
          epAdded = true
      sp--
    @setSelectionRange(ssp, ep)
    true

  moveToNextCell: (text, pos = @currentPos()) ->
    overSep = false
    overSepSpace = false
    eep = null
    sp = pos
    while text[sp]
      if sp > 0 && text[sp-1] == "\n" && text[sp] != '|'
        sp--
        eep = sp
        break

      if !overSep
        if text[sp] == '|'
          overSep = true
      else if text[sp] != ' '
        if text[sp] == "\n"
          overSep = false
        else
          break
      else
        break if overSepSpace
        overSepSpace = true
      sp++

    unless text[sp]
      sp--
      eep = sp

    unless eep
      eep = ep = sp
      while text[ep] && text[ep] != '|'
        eep = ep + 1 if text[ep] != ' '
        ep++

    @setSelectionRange(sp, eep)
    true

  insertSpaces: (text, pos) ->
    nextPos = @currentPos() + @tabSpaces.length

    @insert(text, @tabSpaces, pos)
    @setSelectionRange(nextPos, nextPos)

  removeSpaces: (text, pos) ->
    text.splice(pos, @tabSpaces.length)
    pos = @currentPos() - @tabSpaces.length

    @$el.val(text.join(''))
    @setSelectionRange(pos, pos)

  insert: (textArray, insertText, pos = @currentPos()) ->
    textArray.splice(pos, 0, insertText)
    @$el.val(textArray.join(''))

    pos += insertText.length
    @setSelectionRange(pos, pos)

  currentPos: ->
    @$el.caret('pos')

  destroy: ->
    @$el.off('keydown.markdownEditor').data('markdownEditor', null)
    @$el = null

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
      table: true
    , options

    @each ->
      $(@).data('markdownEditor', new MarkdownEditor(@, options))

    @
