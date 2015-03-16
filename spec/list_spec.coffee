describe 'Support list input', ->
    textarea = null
    action = null
    line = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      down_event = $.Event('keydown', keyCode: 40)
      enter_event = $.Event('keydown', keyCode: 13)

      action = ->
        textarea.val(line)
        textarea.data('markdownEditor').current_pos = -> # stub
          line.length

        textarea.trigger(down_event).trigger(enter_event)

    context 'empty line', ->
      beforeEach -> line = ''

      it 'do nothing', ->
        action()
        expect(textarea.val()).to.eql ''

    context 'chars line', ->
      beforeEach -> line = 'abc'

      it 'do nothing', ->
        action()
        expect(textarea.val()).to.eql 'abc'

    context 'only "- "', ->
      beforeEach -> line = '- '

      it 'delete line', ->
        action()
        expect(textarea.val()).to.eql ''

    context 'start with "- "', ->
      beforeEach -> line = '- abc'

      it 'start with "- " next line', ->
        action()
        expect(textarea.val()).to.eql "- abc\n- "

    context 'start with "* "', ->
      beforeEach -> line = '* abc'

      it 'start with "* " next line', ->
        action()
        expect(textarea.val()).to.eql "* abc\n* "

    context 'start with "55. "', ->
      beforeEach -> line = '55. abc'

      it 'start with "55. " next line', ->
        action()
        expect(textarea.val()).to.eql "55. abc\n55. "

    context 'has many spaces', ->
      beforeEach -> line = '-  abc'

      it 'keep spaces next line', ->
        action()
        expect(textarea.val()).to.eql "-  abc\n-  "
