describe 'Auto make table', ->
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

    context '"axc"', ->
      beforeEach ->
        action('axc')

      it 'nothing do', ->
        expect(textarea.value).to.eql 'axc'

    context '"3x2"', ->
      context 'select range', ->
        beforeEach ->
          action('3x2', 1, 2)

        it 'nothing do', ->
          expect(textarea.value).to.eql '3x2'

      context 'unselect range', ->
        beforeEach ->
          action('3x2')

        it 'make table', ->
          expect(textarea.value).to.eql "|  |  |  |\n| --- | --- | --- |\n|  |  |  |"

    context '":3x2"', ->
      beforeEach ->
        action(':3x2')

      it 'make table and align left', ->
        expect(textarea.value).to.eql "|  |  |  |\n| :--- | :--- | :--- |\n|  |  |  |"

    context '"3x2:"', ->
      beforeEach ->
        action('3x2:')

      it 'make table and align right', ->
        expect(textarea.value).to.eql "|  |  |  |\n| ---: | ---: | ---: |\n|  |  |  |"

    context '":3x2:"', ->
      beforeEach ->
        action(':3x2:')

      it 'make table and align center', ->
        expect(textarea.value).to.eql "|  |  |  |\n| :---: | :---: | :---: |\n|  |  |  |"
