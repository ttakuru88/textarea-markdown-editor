describe 'Table Function', ->
  textarea = null
  action = null
  text = null
  currentPos = null
  markdownEditor = null

  beforeEach ->
    textarea = $('<textarea>').markdownEditor()
    markdownEditor = textarea.data('markdownEditor')
    shiftEnterEvent = $.Event('keydown', keyCode: 32, shiftKey: true)

    action = ->
      textarea.val(text)

      markdownEditor.getSelectionStart = -> currentPos
      markdownEditor.getSelectionEnd = -> currentPos
      markdownEditor.selectionBegin = markdownEditor.selectionEnd = currentPos

      textarea.trigger(shiftEnterEvent)

  afterEach ->
    textarea = null
    action = null
    text = null
    currentPos = null
    markdownEditor = null

  describe 'sum', ->
    context 'all type of number', ->
      beforeEach ->
        text = "|z|x|\n|---|---|\n|c|10|\n|d|20|\n|e|30|\n||=SUM|"
        currentPos = text.length - 3

        action()

      it 'replace current cell', ->
        expect(textarea.val()).to.eql "|z|x|\n|---|---|\n|c|10|\n|d|20|\n|e|30|\n|| 60 |"

    context 'type of string', ->
      beforeEach ->
        text = "|z|x|\n|---|---|\n|c|10pt|\n|d|20pt|\n|e|30pt|\n||=SUM|"
        currentPos = text.length - 3

        action()

      it 'replace current cell', ->
        expect(textarea.val()).to.eql "|z|x|\n|---|---|\n|c|10pt|\n|d|20pt|\n|e|30pt|\n|| 60 |"
