class MarkdownEditor
  list_format: /^(\s*(-|\*|\+|\d+?\.)\s+)(\S*)/

  constructor: (@el, @options) ->
    @$el = $(@el)

    @tab_spaces = ''
    @tab_spaces += ' ' for i in [0...@options.tabSize]

    @$el.on 'keydown', (e) =>
      @support_input_list_format(e)
      @tab_to_space(e)

  support_input_list_format: (e) ->
    return if e.keyCode != 13 || e.shiftKey

    text = @$el.val().split('')

    current_line = @get_current_line(text)

    match = current_line.match(@list_format)
    return if !match
    if match[3].length <= 0
      @remove_current_line(text)
      return

    ext_space = if e.ctrlKey then @tab_spaces else ''

    @insert(text, "\n#{ext_space}#{match[1]}")

    e.preventDefault()

    @options.onInsertedList?(e)

  get_current_line: (text_array) ->
    pos = @current_pos() - 1
    current_line = ''
    while text_array[pos] && text_array[pos] != "\n"
      current_line = "#{text_array[pos]}#{current_line}"
      pos--

    current_line

  remove_current_line: (text_array) ->
    end_pos = @current_pos()
    begin_pos = @get_head_pos(text_array, end_pos)

    remove_length = end_pos - begin_pos
    text_array.splice(begin_pos, remove_length)

    @$el.val(text_array.join(''))
    @el.setSelectionRange(begin_pos , begin_pos)

  tab_to_space: (e) =>
    return if e.keyCode != 9
    e.preventDefault()

    text = @$el.val().split('')
    current_line = @get_current_line(text)
    if current_line.match(@list_format)
      pos = @get_head_pos(text)

      if e.shiftKey
        @remove_spaces(text, pos) if current_line.indexOf(@tab_spaces) == 0
      else
        @insert_spaces(text, pos)
    else
      @insert(text, @tab_spaces)

  insert_spaces: (text, pos) ->
    next_pos = @current_pos() + @tab_spaces.length

    @insert(text, @tab_spaces, pos)
    @el.setSelectionRange(next_pos, next_pos)

  remove_spaces: (text, pos) ->
    text.splice(pos, @tab_spaces.length)
    pos = @current_pos() - @tab_spaces.length

    @$el.val(text.join(''))
    @el.setSelectionRange(pos, pos)

  get_head_pos: (text_array, pos = @current_pos()) ->
    pos-- while pos > 0 && text_array[pos-1] != "\n"
    pos

  insert: (text_array, insert_text, pos = @current_pos()) ->
    text_array.splice(pos, 0, insert_text)
    @$el.val(text_array.join(''))

    pos += insert_text.length
    @el.setSelectionRange(pos, pos)

  current_pos: ->
    @$el.caret('pos')

$.fn.markdownEditor = (options = {}) ->
  options = $.extend
    tabSize: 2
    onInsertedList: null
  , options

  @each ->
    $(@).data('markdownEditor', new MarkdownEditor(@, options))

  @
