describe 'Support table input', ->
    textarea = null
    action = null
    line = null
    currentPos = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      downEvent = $.Event('keydown', keyCode: 40)
      enterEvent = $.Event('keydown', keyCode: 13)

      action = ->
        textarea.val(line)
        textarea.data('markdownEditor').currentPos = ->
          currentPos || line.length

        textarea.trigger(downEvent).trigger(enterEvent)

    afterEach ->
      textarea = null
      action = null
      line = null
      currentPos = null

    context 'start with "|a|b|"', ->
      beforeEach -> line = '|a|b|'

      it 'insert sep and row', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n| --- | --- |\n|  |  |"

    context 'start with "|a|b\\|c|"', ->
      beforeEach -> line = '|a|b\\|c|'

      it 'insert sep and row with 2 columns', ->
        action()
        expect(textarea.val()).to.eql "|a|b\\|c|\n| --- | --- |\n|  |  |"

    context 'in table', ->
      beforeEach -> line = "|a|b|\n|---|---|\n|aa|bb|"

      it 'insert row only', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n|---|---|\n|aa|bb|\n|  |  |"

    context 'cursor on first cell', ->
      beforeEach ->
        currentPos = 1
        line = '|a|b|'

      it 'insert sep and row', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n| --- | --- |\n|  |  |"

    context 'new line on empty row', ->
      beforeEach ->
        currentPos = 18
        line = "|a|b|\n|---|---|\n| | |"

      it 'remove current line', ->
        action()
        expect(textarea.val()).to.eql "|a|b|\n|---|---|\n"
