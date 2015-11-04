describe 'Image upload', ->
    textarea = null
    action = null
    markdownEditor = null
    text = null

    beforeEach ->
      textarea = $('<textarea>').markdownEditor()
      markdownEditor = textarea.data('markdownEditor')

    afterEach ->
      textarea = null
      action = null
      markdownEditor = null
      text = null

    describe '#startUpload', ->
      beforeEach ->
        action = (text, pos) ->
          textarea.val(text)
          markdownEditor.getSelectionStart = -> pos
          markdownEditor.getSelectionEnd = -> pos
          markdownEditor.selectionBegin = pos
          markdownEditor.selectionEnd = pos

          markdownEditor.startUpload('file1')

      context "no \\n", ->
        beforeEach ->
          action('image1:__end__', 7)

        it 'insert uploading text and \\n', ->
          expect(textarea.val()).to.eql "image1:\n![Uploading... file1]()\n__end__"

      context "exists \\n", ->
        beforeEach ->
          action("image1:\n__end__", 7)

        it 'insert uploading text and \\n', ->
          expect(textarea.val()).to.eql "image1:\n![Uploading... file1]()\n__end__"

      context 'exists double \\n', ->
        beforeEach ->
          action("image1:\n\n__end__", 8)

        it 'insert uploading text', ->
          expect(textarea.val()).to.eql "image1:\n![Uploading... file1]()\n__end__"

    describe '#cancelUpload', ->
      beforeEach ->
        action = (text) ->
          textarea.val(text)

          markdownEditor.cancelUpload('file1')

        action("image1:\n![Uploading... file1]()\n__end__")

      it 'remove uploading text', ->
        expect(textarea.val()).to.eql "image1:\n\n__end__"

    describe '#finishUpload', ->
      beforeEach ->
        action = (text, options) ->
          textarea.val(text)
          markdownEditor.finishUpload('file1', 'http://example.com/a.gif', options)

      context 'exists uploading text', ->
        context 'no option', ->
          beforeEach ->
            action("image1: ![Uploading... file1]()")

          it 'replace img markdown', ->
            expect(textarea.val()).to.eql 'image1: ![](http://example.com/a.gif)'

        context 'href option', ->
          beforeEach ->
            action("image1: ![Uploading... file1]()", href: 'http://example.com/a_l.gif')

          it 'replace img markdown', ->
            expect(textarea.val()).to.eql 'image1: [![](http://example.com/a.gif)](http://example.com/a_l.gif)'

        context 'alt option', ->
          beforeEach ->
            action("image1: ![Uploading... file1]()", alt: 'a.gif')

          it 'replace img markdown', ->
            expect(textarea.val()).to.eql 'image1: ![a.gif](http://example.com/a.gif)'

      context 'not exists uploading text', ->
        beforeEach ->
          action('')

        it 'insert img markdown', ->
          expect(textarea.val()).to.eql '![](http://example.com/a.gif)'
