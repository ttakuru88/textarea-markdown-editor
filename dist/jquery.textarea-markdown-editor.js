(function() {
  var KeyCodes, MarkdownEditor,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  KeyCodes = {
    tab: 9,
    enter: 13
  };

  MarkdownEditor = (function() {
    var hrFormat, listFormat;

    listFormat = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/;

    hrFormat = /^\s*-\s+-\s+-(\s+-)*\s*$/;

    function MarkdownEditor(el, options1) {
      var i, j, ref;
      this.el = el;
      this.options = options1;
      this.tabToSpace = bind(this.tabToSpace, this);
      this.$el = $(this.el);
      this.tabSpaces = '';
      for (i = j = 0, ref = this.options.tabSize; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        this.tabSpaces += ' ';
      }
      this.$el.on('keydown', (function(_this) {
        return function(e) {
          if (_this.options.list) {
            _this.supportInputListFormat(e);
          }
          if (_this.options.tabToSpace) {
            return _this.tabToSpace(e);
          }
        };
      })(this));
    }

    MarkdownEditor.prototype.getTextArray = function() {
      return this.$el.val().split('');
    };

    MarkdownEditor.prototype.supportInputListFormat = function(e) {
      var base, currentLine, extSpace, match, text;
      if (e.keyCode !== KeyCodes.enter || e.shiftKey) {
        return;
      }
      text = this.getTextArray();
      currentLine = this.getCurrentLine(text);
      if (currentLine.match(hrFormat)) {
        return;
      }
      match = currentLine.match(listFormat);
      if (!match) {
        return;
      }
      if (match[5].length <= 0) {
        this.removeCurrentLine(text);
        return;
      }
      extSpace = e.ctrlKey ? this.tabSpaces : '';
      this.insert(text, "\n" + extSpace + match[1]);
      e.preventDefault();
      return typeof (base = this.options).onInsertedList === "function" ? base.onInsertedList(e) : void 0;
    };

    MarkdownEditor.prototype.getCurrentLine = function(textArray) {
      var afterChars, beforeChars, pos;
      if (textArray == null) {
        textArray = this.getTextArray();
      }
      pos = this.currentPos() - 1;
      beforeChars = '';
      while (textArray[pos] && textArray[pos] !== "\n") {
        beforeChars = "" + textArray[pos] + beforeChars;
        pos--;
      }
      pos = this.currentPos();
      afterChars = '';
      while (textArray[pos] && textArray[pos] !== "\n") {
        afterChars = "" + afterChars + textArray[pos];
        pos++;
      }
      return "" + beforeChars + afterChars;
    };

    MarkdownEditor.prototype.removeCurrentLine = function(textArray) {
      var beginPos, endPos, removeLength;
      endPos = this.currentPos();
      beginPos = this.getHeadPos(textArray, endPos);
      removeLength = endPos - beginPos;
      textArray.splice(beginPos, removeLength);
      this.$el.val(textArray.join(''));
      return this.el.setSelectionRange(beginPos, beginPos);
    };

    MarkdownEditor.prototype.tabToSpace = function(e) {
      var currentLine, pos, text;
      if (e.keyCode !== KeyCodes.tab) {
        return;
      }
      e.preventDefault();
      text = this.getTextArray();
      currentLine = this.getCurrentLine(text);
      if (currentLine.match(listFormat)) {
        pos = this.getHeadPos(text);
        if (e.shiftKey) {
          if (currentLine.indexOf(this.tabSpaces) === 0) {
            return this.removeSpaces(text, pos);
          }
        } else {
          return this.insertSpaces(text, pos);
        }
      } else {
        return this.insert(text, this.tabSpaces);
      }
    };

    MarkdownEditor.prototype.insertSpaces = function(text, pos) {
      var nextPos;
      nextPos = this.currentPos() + this.tabSpaces.length;
      this.insert(text, this.tabSpaces, pos);
      return this.el.setSelectionRange(nextPos, nextPos);
    };

    MarkdownEditor.prototype.removeSpaces = function(text, pos) {
      text.splice(pos, this.tabSpaces.length);
      pos = this.currentPos() - this.tabSpaces.length;
      this.$el.val(text.join(''));
      return this.el.setSelectionRange(pos, pos);
    };

    MarkdownEditor.prototype.getHeadPos = function(textArray, pos) {
      if (pos == null) {
        pos = this.currentPos();
      }
      while (pos > 0 && textArray[pos - 1] !== "\n") {
        pos--;
      }
      return pos;
    };

    MarkdownEditor.prototype.insert = function(textArray, insertText, pos) {
      if (pos == null) {
        pos = this.currentPos();
      }
      textArray.splice(pos, 0, insertText);
      this.$el.val(textArray.join(''));
      pos += insertText.length;
      return this.el.setSelectionRange(pos, pos);
    };

    MarkdownEditor.prototype.currentPos = function() {
      return this.$el.caret('pos');
    };

    return MarkdownEditor;

  })();

  $.fn.markdownEditor = function(options, args) {
    if (options == null) {
      options = {};
    }
    if (args == null) {
      args = void 0;
    }
    if (typeof options === 'string') {
      return this.each(function() {
        var base;
        return typeof (base = $(this).data('markdownEditor'))[options] === "function" ? base[options](args) : void 0;
      });
    } else {
      options = $.extend({
        tabSize: 2,
        onInsertedList: null,
        tabToSpace: true,
        list: true
      }, options);
      this.each(function() {
        return $(this).data('markdownEditor', new MarkdownEditor(this, options));
      });
      return this;
    }
  };

}).call(this);
