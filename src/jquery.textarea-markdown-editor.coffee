KeyCodes =
  tab: 9
  enter: 13
  space: 32

class MarkdownEditor
  listFormat     = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/
  hrFormat       = /^\s*((-\s+-\s+-(\s+-)*)|(\*\s+\*\s+\*(\s+\*)*))\s*$/
  rowFormat      = /^\|(.*?\|)+\s*$/
  rowSepFormat   = /^\|(\s*:?---+:?\s*\|)+\s*$/
  emptyRowFormat = /^\|(\s*?\|)+\s*$/
  beginCodeblockFormat = /^((```+)|(~~~+))(\S*\s*)$/
  endCodeblockFormat   = /^((```+)|(~~~+))$/

  constructor: (@el, @options) ->
    @$el = $(@el)

    @selectionBegin = @selectionEnd = 0

    @tabSpaces = ''
    @tabSpaces += ' ' for i in [0...@options.tabSize]

    @$el.on 'keydown.markdownEditor', (e) =>
      if e.keyCode == KeyCodes.enter && !e.shiftKey
        @supportInputListFormat(e)  if @options.list
        @supportInputTableFormat(e) if @options.table
        @supportCodeblockFormat(e)  if @options.codeblock

      if e.keyCode == KeyCodes.space && e.shiftKey && !e.ctrlKey && !e.metaKey
        @toggleCheck(e) if @options.list
        @makeTable(e) if @options.autoTable

      if e.keyCode == KeyCodes.tab
        @onPressTab(e)

  getTextArray: ->
    @getText().split('')

  getText: ->
    @el.value

  supportInputListFormat: (e) ->
    text = @getTextArray()

    currentLine = @getCurrentLine(text)
    return if currentLine.match(hrFormat)

    match = currentLine.match(listFormat)
    return unless match

    pos = @getSelectionStart()
    return if text[pos] && text[pos] != "\n"

    if match[5].length <= 0
      @removeCurrentLine(text)
      return

    extSpace = if e.ctrlKey then @tabSpaces else ''

    @insert(text, "\n#{extSpace}#{match[1]}")

    e.preventDefault()

    @options.onInsertedList?(e)

  toggleCheck: (e) ->
    text = @getTextArray()

    currentLine = @getCurrentLine(text)
    matches = currentLine.match(listFormat)
    return unless matches
    return unless matches[4]

    line = ''
    if matches[4] == 'x'
      line = currentLine.replace('[x]', '[ ]')
    else
      line = currentLine.replace('[ ]', '[x]')

    pos = @getSelectionStart()
    @replaceCurrentLine(text, pos, currentLine, line)
    e.preventDefault()

  replaceCurrentLine: (text, pos, oldLine, newLine) ->
    beginPos = @getPosBeginningOfLine(text, pos)
    text.splice(beginPos, oldLine.length, newLine)

    @el.value = text.join('')

    @setSelectionRange(pos, pos)

  supportInputTableFormat: (e) ->
    text = @getTextArray()
    currentLine = @replaceEscapedPipe @getCurrentLine(text)
    selectionStart = @getSelectionStart()
    match = currentLine.match(rowFormat)
    return unless match
    return if @isTableHeader(text)
    return if selectionStart == @getPosBeginningOfLine(text, selectionStart)
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
        sep += " #{@options.tableSeparator} |"

    row = "\n|"
    for i in [0...rows]
      row += '  |'

    text = @insert(text, sep + row, prevPos)

    pos = prevPos + sep.length + row.length - rows * 3 + 1
    @setSelectionRange(pos, pos)

    @options.onInsertedTable?(e)

  supportCodeblockFormat: (e) ->
    text = @getTextArray()
    selectionStart = @getSelectionStart()

    currentLine = @getCurrentLine(text)
    match = currentLine.match(beginCodeblockFormat)
    return if text[selectionStart + 1] && text[selectionStart + 1] != "\n"
    return unless match
    return unless @requireCodeblockEnd(text, selectionStart)

    e.preventDefault()

    @insert(text, "\n\n#{match[1]}")
    @setSelectionRange(selectionStart + 1, selectionStart + 1)

    @options.onInsertedCodeblock?(e)

  requireCodeblockEnd: (text, selectionStart) ->
    innerCodeblock = @isInnerCodeblock(text, selectionStart)
    return false if innerCodeblock

    pos = @getPosBeginningOfLine(text, selectionStart)
    while pos <= text.length
      line = @getCurrentLine(text, pos)
      if innerCodeblock && line.match(endCodeblockFormat)
        return false
      else if !innerCodeblock && line.match(beginCodeblockFormat)
        innerCodeblock = true

      pos += line.length + 1

    true

  isInnerCodeblock: (text, selectionStart = @getSelectionStart()) ->
    innerCodeblock = false

    pos = 0
    endPos = @getPosBeginningOfLine(text, selectionStart) - 1
    while pos < endPos
      line = @getCurrentLine(text, pos)
      if innerCodeblock && line.match(endCodeblockFormat)
        innerCodeblock = false
      else if !innerCodeblock && line.match(beginCodeblockFormat)
        innerCodeblock = true

      pos += line.length + 1

    innerCodeblock

  makeTable: (e) ->
    text = @getTextArray()
    line = @getCurrentLine(text)

    matches = line.match(/^(\d+)x(\d+)$/)
    return unless matches

    e.preventDefault()

    rowsCount = matches[1]
    colsCount = matches[2]

    table = "|"
    for i in [0...rowsCount]
      table += '  |'
    table += "\n|"
    for i in [0...rowsCount]
      table += ' --- |'

    for i in [0...(colsCount - 1)]
      table += "\n|"
      for j in [0...rowsCount]
        table += "  |"

    pos = @getPosBeginningOfLine(text)
    @replaceCurrentLine(text, pos, line, table)
    @setSelectionRange(pos + 2, pos + 2)

  setSelectionRange: (@selectionBegin, @selectionEnd) ->
    @el.setSelectionRange(@selectionBegin, @selectionEnd)

  replaceEscapedPipe: (text) ->
    text.replace(/\\\|/g, '..')

  isTableHeader: (text = @getTextArray(), pos = @getSelectionStart() - 1) ->
    ep = pos = @getPosEndOfLine(text, pos) + 1
    line = @getCurrentLine(text, pos)

    line.match(rowSepFormat)

  isTableBody: (textArray = @getTextArray(), pos = @getSelectionStart() - 1) ->
    line = @replaceEscapedPipe @getCurrentLine(textArray, pos)
    while line.match(rowFormat) && pos > 0
      return true if line.match(rowSepFormat)
      pos = @getPosBeginningOfLine(textArray, pos) - 2
      line = @replaceEscapedPipe @getCurrentLine(textArray, pos)

    false

  getPrevLine: (textArray, pos = @getSelectionStart() - 1) ->
    pos = @getPosBeginningOfLine(textArray, pos)
    @getCurrentLine(textArray, pos - 2)

  getPosEndOfLine: (textArray, pos = @getSelectionStart()) ->
    pos++ while textArray[pos] && textArray[pos] != "\n"
    pos

  getPosBeginningOfLine: (textArray, pos = @getSelectionStart()) ->
    pos-- while textArray[pos-1] && textArray[pos-1] != "\n"
    pos

  getPosBeginningOfLines: (text, startPos = @getSelectionStart(), endPos = @getSelectionEnd()) ->
    beginningPositions = [@getPosBeginningOfLine(text, startPos)]

    startPos = @getPosEndOfLine(startPos) + 1
    if startPos < endPos
      for pos in [startPos..endPos]
        break unless text[pos]
        beginningPositions.push(pos) if pos > 0 && text[pos-1] == "\n"

    beginningPositions

  getCurrentLine: (text = @getText(), initPos = @getSelectionStart() - 1) ->
    pos = initPos

    beforeChars = ''
    while text[pos] && text[pos] != "\n"
      beforeChars = "#{text[pos]}#{beforeChars}"
      pos--

    pos = initPos + 1
    afterChars = ''
    while text[pos] && text[pos] != "\n"
      afterChars = "#{afterChars}#{text[pos]}"
      pos++

    "#{beforeChars}#{afterChars}"

  removeCurrentLine: (textArray) ->
    endPos   = @getPosEndOfLine(textArray)
    beginPos = @getPosBeginningOfLine(textArray)

    removeLength = endPos - beginPos
    textArray.splice(beginPos, removeLength)

    @el.value = textArray.join('')
    @setSelectionRange(beginPos, beginPos)

  onPressTab: (e) =>
    e.preventDefault()

    return if @options.table && @moveCursorOnTableCell(e)

    @tabToSpace(e) if @options.tabToSpace

  moveCursorOnTableCell: (e) ->
    text = @replaceEscapedPipe(@getText())
    currentLine = @getCurrentLine(text)

    return false unless currentLine.match(rowFormat)

    if e.shiftKey
      @moveToPrevCell(text)
    else
      @moveToNextCell(text)

    true

  tabToSpace: (e) ->
    text = @getTextArray()

    listPositions = []
    if @options.list
      dPos = 0
      currentPos = @getSelectionStart()

      for pos in @getPosBeginningOfLines(text, currentPos)
        pos += dPos
        currentLine = @getCurrentLine(text, pos)

        if currentLine.match(listFormat) && !currentLine.match(hrFormat)
          listPositions.push(pos)

          if e.shiftKey
            if currentLine.indexOf(@tabSpaces) == 0
              text.splice(pos, @options.tabSize)
              dPos -= @options.tabSize
          else
            for i in [0...@options.tabSize]
              text.splice(pos, 0, ' ')

            dPos += @options.tabSize

      @el.value = text.join('')
      if listPositions.length > 1
        @setSelectionRange(listPositions[0], @getPosEndOfLine(text, listPositions[listPositions.length-1]))
      else
        if dPos < 0
          beginPos = @getPosBeginningOfLine(text, currentPos + dPos)
          for i in [-1..-@options.tabSize]
            if (!text[currentPos+i] || text[currentPos+i] == "\n") && listPositions[0] > beginPos
              currentPos = listPositions[0] - dPos
              break

        @setSelectionRange(currentPos + dPos, currentPos + dPos)

    @insert(text, @tabSpaces) unless listPositions.length

  moveToPrevCell: (text, pos = @getSelectionStart() - 1) ->
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

  moveToNextCell: (text, pos = @getSelectionStart()) ->
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
    nextPos = @getSelectionStart() + @tabSpaces.length

    @insert(text, @tabSpaces, pos)
    @setSelectionRange(nextPos, nextPos)

  insert: (textArray, insertText, pos = @getSelectionStart()) ->
    textArray.splice(pos, 0, insertText)
    @el.value = textArray.join('')

    pos += insertText.length
    @setSelectionRange(pos, pos)

  getSelectionStart: ->
    @el.selectionStart

  getSelectionEnd: ->
    @el.selectionEnd

  destroy: ->
    @$el.off('keydown.markdownEditor').data('markdownEditor', null)
    @$el = null

$.fn.markdownEditor = (options = {}, args = undefined) ->
  if typeof options == 'string'
    @each ->
      $(@).data('markdownEditor')[options]?(args)
  else
    options = $.extend
      tabSize: 4
      onInsertedList: null
      onInsertedTable: null
      onInsertedCodeblock: null
      tabToSpace: true
      list: true
      table: true
      codeblock: true
      autoTable: true
      tableSeparator: '---'
    , options

    @each ->
      $(@).data('markdownEditor', new MarkdownEditor(@, options))

    @
