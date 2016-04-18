describe 'Support list input', ->
    textarea = null
    action = null
    line = null
    keyCode = null
    selectionStart = null
    selectionEnd = null
    markdownEditor = null
    shiftKey = false

    beforeEach ->
      textarea = document.createElement('textarea')
      markdownEditor = window.markdownEditor(textarea)
      selectionStart = null
      selectionEnd = null
      shiftKey = false

      action = ->
        textarea.value = line

        selectionStart ?= line.length
        markdownEditor.getSelectionStart = -> selectionStart

        selectionEnd ?= selectionStart
        markdownEditor.getSelectionEnd = -> selectionEnd

        event = new Event('keydown')
        event.keyCode = keyCode
        event.shiftKey = shiftKey
        textarea.dispatchEvent(event)

    context 'press space', ->
      beforeEach -> keyCode = 32

      context 'checked checkbox line', ->
        beforeEach -> line = '- [x] a'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql '- [x] a'

      context 'checkbox line', ->
        beforeEach -> line = '- [ ] a'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql '- [ ] a'

      context 'list line', ->
        beforeEach -> line = '- a'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql '- a'

      context 'and press shift key', ->
        beforeEach -> shiftKey = true

        context 'checked checkbox line', ->
          beforeEach -> line = '- [x] a'

          it 'uncheck', ->
            action()
            expect(textarea.value).to.eql '- [ ] a'

        context 'checkbox line', ->
          beforeEach -> line = '- [ ] a'

          it 'check', ->
            action()
            expect(textarea.value).to.eql '- [x] a'

        context 'list line', ->
          beforeEach -> line = '- a'

          it 'do nothing', ->
            action()
            expect(textarea.value).to.eql '- a'

    context 'press tab', ->
      beforeEach -> keyCode = 9

      context 'not selection range', ->
        context 'not list line', ->
          beforeEach -> line = 'aaa'

          it 'insert space', ->
            action()
            expect(textarea.value).to.eql 'aaa    '

        context 'hr line', ->
          beforeEach -> line = '- - - - - -'

          it 'insert tab', ->
            action()
            expect(textarea.value).to.eql '- - - - - -    '

        context 'list line', ->
          beforeEach -> line = '- aaa'

          it 'inert space at head', ->
            action()
            expect(textarea.value).to.eql '    - aaa'

      context 'selection range', ->
        context 'list lines', ->
          beforeEach ->
            line = "- abc\n  - def"
            selectionStart = 1
            selectionEnd = 13

            action()

          it 'insert space to all beginning of lines', ->
            expect(textarea.value).to.eql "    - abc\n      - def"

          it 'selected indent lines', ->
            expect(markdownEditor.selectionBegin).to.eql 0
            expect(markdownEditor.selectionEnd).to.eql 21

        context 'not list lines', ->
          beforeEach ->
            line = "12345\n  abcde"
            selectionStart = 1
            selectionEnd = 13

            action()

          it 'insert space to all beginning of lines', ->
            expect(textarea.value).to.eql "    12345\n      abcde"

          it 'selected indent lines', ->
            expect(markdownEditor.selectionBegin).to.eql 0
            expect(markdownEditor.selectionEnd).to.eql 21

      context 'with shift key', ->
        beforeEach ->
          shiftKey = true
          line = "- a\n    - b\n    - c"

        context 'on beginning of line', ->
          beforeEach ->
            selectionStart = 4
            action()

          it 'remove space on second line', ->
            expect(textarea.value).to.eql "- a\n- b\n    - c"

          it 'cursor position is beginning of line', ->
            expect(markdownEditor.selectionBegin).to.eql 4

        context 'on end of line', ->
          beforeEach ->
            selectionStart = 9
            action()

          it 'remove space on second line', ->
            expect(textarea.value).to.eql "- a\n- b\n    - c"

          it 'cursor position is beginning of line', ->
            expect(markdownEditor.selectionBegin).to.eql 5

    context 'press enter', ->
      beforeEach -> keyCode = 13

      context 'empty line', ->
        beforeEach -> line = ''

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql ''

      context 'chars line', ->
        beforeEach -> line = 'abc'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql 'abc'

      context 'start with "- - - - -"', ->
        beforeEach -> line = '- - - - -'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql '- - - - -'

      context 'start with "- - - - - a"', ->
        beforeEach -> line = '- - - - - a'

        it 'start with "- " next line', ->
          action()
          expect(textarea.value).to.eql "- - - - - a\n- "

      context 'start with "* * * * *"', ->
        beforeEach -> line = '* * * * *'

        it 'do nothing', ->
          action()
          expect(textarea.value).to.eql '* * * * *'

      context 'start with "* * * * * a"', ->
        beforeEach -> line = '* * * * * a'

        it 'start with "* " next line', ->
          action()
          expect(textarea.value).to.eql "* * * * * a\n* "

      context 'start with "* * - * *"', ->
        beforeEach -> line = '* * - * *'

        it 'start with "* " next line', ->
          action()
          expect(textarea.value).to.eql "* * - * *\n* "

      context 'only "- "', ->
        beforeEach -> line = '- '

        it 'delete line', ->
          action()
          expect(textarea.value).to.eql ''

      context 'start with "- "', ->
        beforeEach -> line = '- abc'

        context 'cursor on end of line', ->
          it 'start with "- " next line', ->
            action()
            expect(textarea.value).to.eql "- abc\n- "

        context 'cursor on beginning of line', ->
          beforeEach -> selectionStart = 0

          it 'do nothing', ->
            action()
            expect(textarea.value).to.eql "- abc"

      context 'start with "* "', ->
        beforeEach -> line = '* abc'

        it 'start with "* " next line', ->
          action()
          expect(textarea.value).to.eql "* abc\n* "

      context 'start with "55. "', ->
        beforeEach -> line = '55. abc'

        it 'start with "55. " next line', ->
          action()
          expect(textarea.value).to.eql "55. abc\n55. "

      context 'has many spaces', ->
        beforeEach -> line = '-  abc'

        it 'keep spaces next line', ->
          action()
          expect(textarea.value).to.eql "-  abc\n-  "

      context 'start with "- [ ] "', ->
        beforeEach -> line = '- [ ] abc'

        it 'start with "- [ ] "', ->
          action()
          expect(textarea.value).to.eql "- [ ] abc\n- [ ] "

      context 'start with "- [x] "', ->
        beforeEach -> line = '- [x] abc'

        it 'start with "- [x] "', ->
          action()
          expect(textarea.value).to.eql "- [x] abc\n- [x] "
