describe 'Csv to table', ->
    textarea = null
    action = null
    markdownEditor = null
    keyCode = 32 # space

    beforeEach ->
      textarea = document.createElement('textarea')
      markdownEditor = window.markdownEditor(textarea)

      action = (text, selectionStart = text.length, selectionEnd = text.length) ->
        textarea.value = text

        markdownEditor.getSelectionStart = -> selectionStart
        markdownEditor.getSelectionEnd = -> selectionEnd
        markdownEditor.selectionBegin = selectionStart
        markdownEditor.selectionEnd = selectionEnd

        event = new Event('keydown')
        event.keyCode = keyCode
        event.shiftKey = true
        textarea.dispatchEvent(event)

    afterEach ->
      textarea = null
      action = null
      markdownEditor = null
      keyCode = 32

    context 'csv', ->
      context 'basic', ->
        beforeEach ->
          action("a, b,c\ne,f, g", 0)

        it 'to table', ->
          expect(textarea.value).to.eql "| a | b | c |\n| --- | --- | --- |\n| e | f | g |\n"

      context 'quoted', ->
        beforeEach ->
          action("\"a, b\",c\ne,f", 0)

        it 'to table', ->
          expect(textarea.value).to.eql "| a, b | c |\n| --- | --- |\n| e | f |\n"

      context 'quoted double quotation', ->
        beforeEach ->
          action("\"\"\"a\"\", b\",c\ne,f", 0)

        it 'to table', ->
          expect(textarea.value).to.eql "| \"a\", b | c |\n| --- | --- |\n| e | f |\n"

      context 'new line in cell', ->
        beforeEach ->
          action("\"a\nb\",c\ne,f", 0)

        it 'to table', ->
          expect(textarea.value).to.eql "| a<br>b | c |\n| --- | --- |\n| e | f |\n"

      context 'single col', ->
        beforeEach ->
          action("a, b, c", 0)

        it 'to table', ->
          expect(textarea.value).to.eql "| a | b | c |\n| --- | --- | --- |\n"

      context 'single row', ->
        beforeEach ->
          action("a\nb\nc", 0)

        it 'not to table', ->
          expect(textarea.value).to.eql "a\nb\nc"
