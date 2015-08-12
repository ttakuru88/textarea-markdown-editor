describe 'Sort table', ->
    textarea = null
    action = null
    markdownEditor = null
    text = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      markdownEditor = textarea.data('markdownEditor')

      action = (pos) ->
        enterEvent = $.Event('keydown', keyCode: 32, shiftKey: true)

        textarea.val(text)

        markdownEditor.getSelectionStart = -> pos
        markdownEditor.getSelectionEnd = -> pos
        markdownEditor.selectionBegin = pos
        markdownEditor.selectionEnd = pos

        textarea.trigger(enterEvent)

    afterEach ->
      textarea = null
      action = null
      markdownEditor = null
      text = null

    context 'single table', ->
      beforeEach ->
        text = "|a|b|\n|---|---|\n|h|9|\n|b|3|\n|f|1|"

      context 'first col', ->
        beforeEach ->
          action(1)

        it 'sort by first col', ->
          expect(textarea.val()).to.eql "|a|b|\n|---|---|\n|b|3|\n|f|1|\n|h|9|\n"

      context 'second col', ->
        beforeEach ->
          action(3)

        it 'sort by second col', ->
          expect(textarea.val()).to.eql "|a|b|\n|---|---|\n|f|1|\n|b|3|\n|h|9|\n"
