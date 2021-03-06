KeyCodes =
  tab: 9
  enter: 13
  ctrl: 17
  space: 32
  b: 66
  i: 73
  u: 85
  q: 81

class MarkdownEditor
  listFormat     = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/
  hrFormat       = /^\s{0,3}\s*((-\s+-\s+-(\s+-)*)|(\*\s+\*\s+\*(\s+\*)*))\s*$/
  rowFormat      = /^\s{0,3}\|(.*?\|)+\s*$/
  rowSepFormat   = /^\s{0,3}\|(\s*(:-{2,}|-{2,}:|:-{1,}:|-{3,})\s*\|)+\s*$/
  emptyRowFormat = /^\s{0,3}\|(\s*?\|)+\s*$/
  beginCodeblockFormat = /^\s{0,3}((```+)|(~~~+))(\S*\s*)$/
  endCodeblockFormat   = /^\s{0,3}((```+)|(~~~+))$/
  makingTableFormat = /^(:?)(\d+)x(\d+)(:?)$/
  numberFormat = /^-?\d+[\d\.]*$/
  functionFormat = /^=\s*(\S+)\s*$/
  requiredGeneratorMetaTagFormat = /<meta[^>]+?generator[^>]+?>/i
  contentParser = /\scontent=['"]?([^'"]+)['"]?/i
  tsv2tableGenerators = /^Sheets$|^LibreOffice|^Microsoft Excel|^OpenOffice/

  tableFunctions = ['sum', 'average', 'max', 'min', 'count']

  clearPastedStrings: ->
    @pastedStrings = {}

  constructor: (@el, @options) ->
    @selectionBegin = @selectionEnd = 0

    @tabSpaces = ''
    @tabSpaces += ' ' for i in [0...@options.tabSize]

    if @options.convertSheetToTable
      @el.addEventListener 'paste', (e) =>
        return if !e.clipboardData || !e.clipboardData.items

        @clearPastedStrings()
        items = {}
        for item in e.clipboardData.items
          if item.kind == 'string' && /^text\/(plain|html)$/.test(item.type)
            items[item.type] = item

        if items['text/plain'] && items['text/html'] && items['text/plain'].getAsString && items['text/html'].getAsString
          e.preventDefault()
          @options.beforePastedObjectToTable?(e)
          @getPastedString(items['text/plain'])
          @getPastedString(items['text/html'])

    @el.addEventListener 'keydown', (e) =>
      if e.keyCode == KeyCodes.enter && !e.shiftKey
        @supportInputListFormat(e)  if @options.list
        @supportInputTableFormat(e) if @options.table
        @supportCodeblockFormat(e)  if @options.codeblock

      if e.keyCode == KeyCodes.space && e.shiftKey && !e.ctrlKey && !e.metaKey
        text = @getTextArray()
        currentLine = @getCurrentLine(text)

        @toggleCheck(e, text, currentLine) if @options.list
        @makeTable(e, text, currentLine) if @options.autoTable

        if @options.csvToTable
          if @csvToTable(@getSelectedText(), text)
            e.preventDefault()
            @options.onMadeTable?(e)
            return
        if @options.tsvToTable
          if @tsvToTable(@getSelectedText(), text)
            e.preventDefault()
            @options.onMadeTable?(e)
            return

        @sortTable(e, text, currentLine) if @options.sortTable
        @tableFunction(e, text, currentLine) if @options.tableFunction

      if e.keyCode == KeyCodes.tab
        @onPressTab(e)

      if e.ctrlKey && !e.metaKey && !e.shiftKey && e.which != KeyCodes.ctrl
        @withCtrl(e)

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

  toggleCheck: (e, text, currentLine) ->
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

    @replace(text, newLine, beginPos, beginPos + oldLine.length)

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

    @insert(text, sep + row, prevPos)

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

  makeTable: (e, text, currentLine) ->
    return if @isSelectRange()
    matches = currentLine.match(makingTableFormat)
    return unless matches
    return if matches[2] <= 0 || matches[3] <= 0

    e.preventDefault()

    alignLeft = !!matches[1].length
    alignRight = !!matches[4].length

    table = @buildTable(matches[2], matches[3], {alignLeft: alignLeft, alignRight: alignRight})

    pos = @getPosBeginningOfLine(text)
    @replaceCurrentLine(text, pos, currentLine, table)
    @setSelectionRange(pos + 2, pos + 2)

    @options.onMadeTable?(e)

  buildTable: (rowsCount, colsCount, options = {}) ->
    separator = "---"
    separator = ":#{separator}" if options.alignLeft
    separator = "#{separator}:" if options.alignRight

    table = "|"
    for i in [0...rowsCount]
      table += '  |'
    table += "\n|"
    for i in [0...rowsCount]
      table += " #{separator} |"

    for i in [0...(colsCount - 1)]
      table += "\n|"
      for j in [0...rowsCount]
        table += "  |"

    table

  csvToTable: (csv, text = @getTextArray(), allowFlat = false) ->
    @separatedStringToTable(csv, ',', text, allowFlat)

  tsvToTable: (tsv, text = @getTextArray(), allowFlat = false) ->
    @separatedStringToTable(tsv, "\t", text, allowFlat)

  separatedStringToTable: (str, separator, text, allowFlat) ->
    str = str.replace(/\r\n/g, "\n").replace(/\r/g, "\n")
    inQuote = false
    escape = false
    cells = [['']]
    y = 0
    x = 0
    xMax = 0
    for c, i in str
      if inQuote
        if escape
          escape = false
          cells[y][x] += c
        else if !escape && c == '"'
          if str[i+1] == '"'
            escape = true
          else
            inQuote = false
        else
          cells[y][x] += c
      else
        if c == '"'
          inQuote = true
        else if c == separator
          cells[y].push('')
          x += 1
          xMax = x if xMax < x
        else if c == "\n"
          cells.push([''])
          y += 1
          x = 0
        else
          cells[y][x] += c

    return false if allowFlat && xMax <= 0 && y <= 0 || !allowFlat && xMax <= 0

    table = @createTableFromArray(cells)
    @replace(text, table, @getSelectionStart(), @getSelectionEnd())
    true

  createTableFromArray: (csvLines) ->
    table = ''
    for line, i in csvLines
      if line.length == 1 && line[0] == ""
        continue

      table += "|"
      for cell in line
        table += " #{@trim(cell).replace(/\n/g, '<br>')} |"
      table += "\n"

      if i == 0
        table += "|"
        for j in [0...line.length]
          table += " #{@options.tableSeparator} |"
        table += "\n"
    table

  getPastedString: (item) ->
    type = item.type
    item.getAsString (str) => @onGetPastedString(type, str)

  onGetPastedString: (type, str) ->
    unless str
      @clearPastedStrings()
      return

    @pastedStrings[type] = str
    if @pastedStrings['text/plain'] && @pastedStrings['text/html']
      metaMatch = @pastedStrings['text/html'].match(requiredGeneratorMetaTagFormat)
      if metaMatch
        generatorMatch = metaMatch[0].match(contentParser)
        if generatorMatch
          generator = generatorMatch[1]
          unless tsv2tableGenerators.test(generator) && @tsvToTable(@pastedStrings['text/plain'], null, true)
            @restorePlainText()
        else
          @restorePlainText()
      else
        @restorePlainText()

      @clearPastedStrings()

  restorePlainText: ->
    @replace(@getTextArray(), @pastedStrings['text/plain'], @getSelectionStart(), @getSelectionEnd())

  tableFunction: (e, text, currentLine) ->
    return if @isSelectRange()

    col = @getCurrentCol(text, currentLine) - 1
    row = @getCurrentRow(text)
    return if col < 0
    return unless row?

    e.preventDefault()

    data = @getCurrentTableData(text)
    currentCellText = data.lines[row].values[col]
    return if typeof currentCellText != 'string'

    match = currentCellText.match(functionFormat)
    return unless match

    inputFunction = match[1]
    inCaseSensitiveFunction = new RegExp("^#{inputFunction}$", 'i')
    for tableFunction in tableFunctions
      if tableFunction.match(inCaseSensitiveFunction)
        result = @["#{tableFunction}TableFunction"](data, col, row)
        @replaceCurrentCol(text, result) if result?
        return

  countTableFunction: (data, col, row) ->
    data.lines.length - 1

  maxTableFunction: (data, col, row) ->
    max = -Infinity
    for line in data.lines
      if typeof line.values[col] == 'number' && max < line.values[col]
        max = line.values[col]
      else
        number = parseFloat(line.values[col])
        max = number if number? && !isNaN(number) && max < number

    return null if max == -Infinity

    max

  round: (num) ->
    w = Math.pow(10, @options.significantFigures)
    Math.round(num * w) / w

  minTableFunction: (data, col, row) ->
    min = Infinity
    for line in data.lines
      if typeof line.values[col] == 'number' && min > line.values[col]
        min = line.values[col]
      else
        number = parseFloat(line.values[col])
        min = number if number? && !isNaN(number) && min > number

    return null if min == Infinity

    min

  averageTableFunction: (data, col, row) ->
    @round(@sumTableFunction(data, col, row) / @countTableFunction(data, col, row))

  sumTableFunction: (data, col, row) ->
    sum = 0.0
    for line in data.lines
      if typeof line.values[col] == 'number'
        sum += line.values[col]
      else
        number = parseFloat(line.values[col])
        sum += number if number? && !isNaN(number)

    @round sum

  replaceCurrentCol: (text, str, pos = @getSelectionStart()) ->
    sp = pos
    ep = pos

    while sp > 0 && text[sp-1] != '|'
      sp--

    while text[ep] && text[ep] != '|'
      ep++

    @replace(text, " #{str} ", sp, ep, true)

  sortTable: (e, text, currentLine) ->
    return if @isSelectRange() || !@isTableHeader(text)
    e.preventDefault()

    prevPos = @getSelectionStart()
    col = @getCurrentCol(text, currentLine) - 1
    data = @getCurrentTableData(text)

    asc = false
    for i in [1...data.lines.length]
      if 0 < @compare(data.lines[i-1].values[col], data.lines[i].values[col])
        asc = true
        break

    data.lines.sort (a, b) =>
      @compare(a.values[col], b.values[col], asc)

    body = ''
    for line in data.lines
      body += "#{line.text}\n"

    @replace(text, body, data.bodyStart, data.bodyEnd)
    @setSelectionRange(prevPos, prevPos)

    @options.onSortedTable?(e)

  compare: (a, b, asc = true) ->
    x = if asc then 1 else -1

    return -1 * x if @isEmpty(a)
    return 1 * x if @isEmpty(b)
    return 0 if a == b
    return (if a < b then -1 else 1) * x

  getCurrentCol: (text, currentLine) ->
    row = @replaceEscapedPipe(currentLine)
    pos = @getSelectionStart() - @getPosBeginningOfLine(text, @getSelectionStart())

    count = 0
    for i in [0...Math.min(pos, row.length)]
      count++ if row[i] == '|'

    count

  getCurrentRow: (text, pos = @getSelectionStart()) ->
    pos = @getPosEndOfLine(text, pos) - 1
    row = 0
    line = @getCurrentLine(text, pos)
    while @replaceEscapedPipe(line).match(rowFormat)
      pos -= line.length + 1
      line = @getCurrentLine(text, pos)
      row++

    return null if row < 3

    row - 3


  isEmpty: (v) ->
    v == null || v == undefined || v == ''

  getTableStart: (text, pos = @getSelectionStart()) ->
    pos = @getPosEndOfLine(text, pos) - 1

    line = @getCurrentLine(text, pos)
    while @replaceEscapedPipe(line).match(rowFormat)
      pos -= line.length + 1
      line = @getCurrentLine(text, pos)

    pos + 2

  isTableLine: (text) ->
    text.match(rowFormat)

  getCurrentTableData: (text, pos = @getSelectionStart()) ->
    pos = @getTableStart(text, pos)
    newLineLeft = 2
    while newLineLeft > 0 && text[pos]?
      newLineLeft-- if text[pos] == "\n"
      pos++

    data =
      bodyStart: pos
      lines: []

    while text[pos]? && @isTableBody(text, pos)
      line = @getCurrentLine(text, pos - 1)
      break if line.length <= 0

      values = @replaceEscapedPipe(line.slice(1, -1)).split('|')
      for v,i in values
        values[i] = @trim(v)
        values[i] = +values[i] if values[i].match?(numberFormat)

      data.lines.push
        text:  line
        values: values

      pos += line.length + 1

    data.bodyEnd = pos
    data

  trim: (str) ->
    str.replace(/^\s+/, '').replace(/\s+$/, '')

  isSelectRange: ->
    @getSelectionStart() != @getSelectionEnd()

  getSelectedText: ->
    @getText().slice(@getSelectionStart(), @getSelectionEnd())

  setSelectionRange: (@selectionBegin, @selectionEnd) ->
    @el.setSelectionRange(@selectionBegin, @selectionEnd)

  replaceEscapedPipe: (text) ->
    text.replace(/\\\|/g, '..')

  isTableHeader: (text = @getTextArray(), pos = @getSelectionStart()) ->
    pos = @getPosEndOfLine(text, pos)
    line = @getCurrentLine(text, pos)

    !!line.match(rowSepFormat)

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

    @replace(textArray, '', beginPos, endPos)

  onPressTab: (e) =>
    e.preventDefault()

    return if @options.table && @moveCursorOnTableCell(e)

    @tabToSpace(e) if @options.tabToSpace

  withCtrl: (e) ->
    return unless @options.fontDecorate

    preventDefault = switch e.which
      when KeyCodes.b
        @wrap('**')
      when KeyCodes.i
        @wrap('_')
      when KeyCodes.u
        @wrap('~~')
      when KeyCodes.q
        @wrap('`')

    e.preventDefault() if preventDefault?

  wrap: (wrapper) ->
    selectionStart = @getSelectionStart()
    selectionEnd = @getSelectionEnd()
    return if selectionStart == selectionEnd
    text = @getTextArray()
    beginningOfLines = @getPosBeginningOfLines(text, selectionStart, selectionEnd)
    return false if beginningOfLines.length > 1

    selectedText = text.slice(selectionStart, selectionEnd).join('')
    @replace(text, "#{wrapper}#{selectedText}#{wrapper}", selectionStart, selectionEnd)
    @setSelectionRange(selectionStart + wrapper.length, selectionEnd + wrapper.length)
    true

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
    currentPos = @getSelectionStart()
    beginningOfLines = @getPosBeginningOfLines(text, currentPos)

    if beginningOfLines.length <= 1
      currentLine = @getCurrentLine(text, beginningOfLines[0])
      if @options.list && currentLine.match(listFormat) && !currentLine.match(hrFormat)
        @insertSpacesToBeginningOfLines(text, currentPos, beginningOfLines, e.shiftKey)
      else if !e.shiftKey
        @insert(text, @tabSpaces)
    else
      @insertSpacesToBeginningOfLines(text, currentPos, beginningOfLines, e.shiftKey)

  insertSpacesToBeginningOfLines: (text, currentPos, beginningOfLines, isBack) ->
    listPositions = []
    dPos = 0

    for pos in beginningOfLines
      pos += dPos
      currentLine = @getCurrentLine(text, pos)

      listPositions.push(pos)

      if isBack
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

  insert: (textArray, insertText, pos = @getSelectionStart()) ->
    @replace(textArray, insertText, pos, pos)

  replace: (textArray, text, beginPos, endPos, select = false) ->
    @setSelectionRange(beginPos, endPos)

    try
      result = document.execCommand?('insertText', false, text)
    catch
      result = false

    @replaceValue(textArray, text, beginPos, endPos) unless result
    @setSelectionRange(beginPos, beginPos + text.length) if select

  replaceValue: (textArray, insertText, beginPos, endPos) ->
    textArray.splice(beginPos, endPos - beginPos, insertText)

    try
      document.execCommand('ms-beginUndoUnit');
    catch error
      ;

    @el.value = textArray.join('')

    try
      document.execCommand('ms-endUndoUnit');
    catch error
      ;

    pos = beginPos + insertText.length
    @setSelectionRange(pos, pos)

  getSelectionStart: ->
    @el.selectionStart

  getSelectionEnd: ->
    @el.selectionEnd

  destroy: ->
    @el.removeEventListener('keydown')
    @el.dataset.markdownEditor = null
    @el = null

  startUpload: (name) ->
    text = @getTextArray()
    pos = @getSelectionStart()

    insertText = @buildUploadingText(name)
    insertText = "\n#{insertText}" if pos > 0 && text[pos-1] != "\n"
    insertText = "#{insertText}\n" if pos < text.length - 1 && text[pos] != "\n"

    @replaceValue(text, insertText, pos, pos)

  cancelUpload: (name) ->
    @el.value = @getText().replace(@buildUploadingText(name), '')

  buildUploadingText: (name) ->
    @options.uploadingFormat(name)

  finishUpload: (name, options = {}) ->
    text = @getText()
    finishedUploadText = options.text || ''
    if finishedUploadText.length <= 0 && options.url || options.alt
      finishedUploadText = "![#{options.alt || ''}](#{options.url || ''})"
      finishedUploadText = "[#{finishedUploadText}](#{options.href})" if options.href?

    uploadingText = @buildUploadingText(name)

    uploadingTextPos = text.indexOf(uploadingText)
    if uploadingTextPos >= 0
      selectionStart = @getSelectionStart()
      selectionEnd = @getSelectionEnd()

      @replaceValue(@getTextArray(), finishedUploadText, uploadingTextPos, uploadingTextPos + uploadingText.length)
    else
      pos = @getSelectionStart()
      @replaceValue(@getTextArray(), finishedUploadText, pos, pos)

defaultOptions =
  tabSize: 4
  onInsertedList: null
  onInsertedTable: null
  onInsertedCodeblock: null
  onSortedTable: null
  onMadeTable: null
  convertSheetToTable: true
  tabToSpace: true
  list: true
  table: true
  fontDecorate: true
  codeblock: true
  autoTable: true
  tableSeparator: '---'
  csvToTable: true
  tsvToTable: true
  sortTable: true
  tableFunction: true
  significantFigures: 4
  beforePastedObjectToTable: null
  uploadingFormat: (name) ->
    "![Uploading... #{name}]()"

window.markdownEditor = (el, options = {}) ->
  for defaultOptionName, value of defaultOptions
     options[defaultOptionName] ?= value

  new MarkdownEditor(el, options)
