describe 'Support table input', ->
    textarea = null
    action = null
    line = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      downEvent = $.Event('keydown', keyCode: 40)
      enterEvent = $.Event('keydown', keyCode: 13)

      action = ->
        textarea.val(line)
        textarea.data('markdownEditor').currentPos = ->
          line.length

        textarea.trigger(downEvent).trigger(enterEvent)

    context 'start with "|a|b|"', ->
      beforeEach -> line = '|a|b|'

      it 'insert sep and row', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n| --- | --- |\n|  |  |"

    context 'in table', ->
      beforeEach -> line = "|a|b|\n|---|---|\n| | |"

      it 'insert row only', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n|---|---|\n| | |\n|  |  |"
