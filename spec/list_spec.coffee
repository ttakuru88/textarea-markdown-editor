describe 'Support list input', ->
    textarea = null
    action = null
    line = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      enterEvent = $.Event('keydown', keyCode: 13)

      action = ->
        textarea.val(line)
        textarea.data('markdownEditor').currentPos = -> # stub
          line.length

        textarea.trigger(enterEvent)

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

    context 'start with "- - - - -"', ->
      beforeEach -> line = '- - - - -'

      it 'do nothing', ->
        action()
        expect(textarea.val()).to.eql '- - - - -'

    context 'start with "- - - - - a"', ->
      beforeEach -> line = '- - - - - a'

      it 'start with "- " next line', ->
        action()
        expect(textarea.val()).to.eql "- - - - - a\n- "

    context 'start with "* * * * *"', ->
      beforeEach -> line = '* * * * *'

      it 'do nothing', ->
        action()
        expect(textarea.val()).to.eql '* * * * *'

    context 'start with "* * * * * a"', ->
      beforeEach -> line = '* * * * * a'

      it 'start with "* " next line', ->
        action()
        expect(textarea.val()).to.eql "* * * * * a\n* "

    context 'start with "* * - * *"', ->
      beforeEach -> line = '* * - * *'

      it 'start with "* " next line', ->
        action()
        expect(textarea.val()).to.eql "* * - * *\n* "

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

    context 'start with "- [ ] "', ->
      beforeEach -> line = '- [ ] abc'

      it 'start with "- [ ] "', ->
        action()
        expect(textarea.val()).to.eql "- [ ] abc\n- [ ] "

    context 'start with "- [x] "', ->
      beforeEach -> line = '- [x] abc'

      it 'start with "- [x] "', ->
        action()
        expect(textarea.val()).to.eql "- [x] abc\n- [x] "
