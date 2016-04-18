describe 'font decoration', ->
  textarea = null
  action = null
  markdownEditor = null
  text = null
  setText = null

  beforeEach ->
    textarea = document.createElement('textarea')
    markdownEditor = window.markdownEditor(textarea)

    action = ->
      markdownEditor.wrap('--')
      markdownEditor.getSelectionStart = -> pos
      markdownEditor.getSelectionEnd = -> pos
      markdownEditor.selectionBegin = pos
      markdownEditor.selectionEnd = pos

  describe '#wrap', ->
    beforeEach ->
      textarea.value = '!LGTM!'
      markdownEditor.getSelectionStart = -> 1
      markdownEditor.getSelectionEnd = -> 5
      markdownEditor.selectionBegin = 1
      markdownEditor.selectionEnd = 5
      markdownEditor.wrap('--')

    it 'wrapped in "--"', ->
      expect(textarea.value).to.eql '!--LGTM--!'
