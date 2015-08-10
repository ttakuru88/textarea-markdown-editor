describe 'Auto make table', ->
    textarea = null
    action = null
    currentPos = null
    markdownEditor = null
    keyCode = 32 # space

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      markdownEditor = textarea.data('markdownEditor')

      action = (text) ->
        enterEvent = $.Event('keydown', keyCode: keyCode, shiftKey: true)

        textarea.val(text)
        pos = if currentPos? then currentPos else text.length
        markdownEditor.getSelectionStart = ->
          pos
        markdownEditor.selectionBegin = markdownEditor.selectionEnd = pos

        textarea.trigger(enterEvent)

    afterEach ->
      textarea = null
      action = null
      currentPos = null
      markdownEditor = null
      keyCode = 32

    context '"axc"', ->
      beforeEach ->
        action('axc')

      it 'nothing do', ->
        expect(textarea.val()).to.eql 'axc'

    context '"3x2"', ->
      beforeEach ->
        action('3x2')

      it 'make table', ->
        expect(textarea.val()).to.eql "|  |  |  |\n| --- | --- | --- |\n|  |  |  |"

    context '":3x2"', ->
      beforeEach ->
        action(':3x2')

      it 'make table and align left', ->
        expect(textarea.val()).to.eql "|  |  |  |\n| :--- | :--- | :--- |\n|  |  |  |"

    context '"3x2:"', ->
      beforeEach ->
        action('3x2:')

      it 'make table and align right', ->
        expect(textarea.val()).to.eql "|  |  |  |\n| ---: | ---: | ---: |\n|  |  |  |"

    context '":3x2:"', ->
      beforeEach ->
        action(':3x2:')

      it 'make table and align center', ->
        expect(textarea.val()).to.eql "|  |  |  |\n| :---: | :---: | :---: |\n|  |  |  |"
