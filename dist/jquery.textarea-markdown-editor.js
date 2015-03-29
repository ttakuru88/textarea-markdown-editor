(function() {
  var KeyCodes, MarkdownEditor,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  KeyCodes = {
    tab: 9,
    enter: 13
  };

  MarkdownEditor = (function() {
    var emptyRowFormat, hrFormat, listFormat, rowFormat, rowSepFormat;

    listFormat = /^(\s*(-|\*|\+|\d+?\.)\s+(\[(\s|x)\]\s+)?)(\S*)/;

    hrFormat = /^\s*((-\s+-\s+-(\s+-)*)|(\*\s+\*\s+\*(\s+\*)*))\s*$/;

    rowFormat = /^\|(.*?\|)+\s*$/;

    rowSepFormat = /^\|(\s*:?---+:?\s*\|)+\s*$/;

    emptyRowFormat = /^\|(\s*?\|)+\s*$/;

    function MarkdownEditor(el, options1) {
      var i, j, ref;
      this.el = el;
      this.options = options1;
      this.tabToSpace = bind(this.tabToSpace, this);
      this.$el = $(this.el);
      this.selectionBegin = this.selectionEnd = 0;
      this.tabSpaces = '';
      for (i = j = 0, ref = this.options.tabSize; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        this.tabSpaces += ' ';
      }
      this.$el.on('keydown.markdownEditor', (function(_this) {
        return function(e) {
          if (_this.options.list) {
            _this.supportInputListFormat(e);
          }
          if (_this.options.table) {
            _this.supportInputTableFormat(e);
          }
          return _this.tabToSpace(e);
        };
      })(this));
    }

    MarkdownEditor.prototype.getTextArray = function() {
      return this.getText().split('');
    };

    MarkdownEditor.prototype.getText = function() {
      return this.$el.val();
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

    MarkdownEditor.prototype.supportInputTableFormat = function(e) {
      var char, currentLine, i, j, k, l, len, match, pos, prevPos, ref, ref1, row, rows, sep, text;
      if (e.keyCode !== KeyCodes.enter || e.shiftKey) {
        return;
      }
      text = this.getTextArray();
      currentLine = this.replaceEscapedPipe(this.getCurrentLine(text));
      match = currentLine.match(rowFormat);
      if (!match) {
        return;
      }
      if (currentLine.match(emptyRowFormat) && this.isTableBody(text)) {
        this.removeCurrentLine(text);
        return;
      }
      e.preventDefault();
      rows = -1;
      for (j = 0, len = currentLine.length; j < len; j++) {
        char = currentLine[j];
        if (char === '|') {
          rows++;
        }
      }
      prevPos = this.getPosEndOfLine(text);
      sep = '';
      if (!this.isTableBody(text)) {
        sep = "\n|";
        for (i = k = 0, ref = rows; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
          sep += ' --- |';
        }
      }
      row = "\n|";
      for (i = l = 0, ref1 = rows; 0 <= ref1 ? l < ref1 : l > ref1; i = 0 <= ref1 ? ++l : --l) {
        row += '  |';
      }
      text = this.insert(text, sep + row, prevPos);
      pos = prevPos + sep.length + row.length - rows * 3 + 1;
      return this.setSelectionRange(pos, pos);
    };

    MarkdownEditor.prototype.setSelectionRange = function(selectionBegin, selectionEnd) {
      this.selectionBegin = selectionBegin;
      this.selectionEnd = selectionEnd;
      return this.el.setSelectionRange(this.selectionBegin, this.selectionEnd);
    };

    MarkdownEditor.prototype.replaceEscapedPipe = function(text) {
      return text.replace(/\\\|/g, '..');
    };

    MarkdownEditor.prototype.isTableBody = function(textArray, pos) {
      var line;
      if (textArray == null) {
        textArray = this.getTextArray();
      }
      if (pos == null) {
        pos = this.currentPos() - 1;
      }
      line = this.replaceEscapedPipe(this.getCurrentLine(textArray, pos));
      while (line.match(rowFormat) && pos > 0) {
        if (line.match(rowSepFormat)) {
          return true;
        }
        pos = this.getPosBeginningOfLine(textArray, pos) - 2;
        line = this.replaceEscapedPipe(this.getCurrentLine(textArray, pos));
      }
      return false;
    };

    MarkdownEditor.prototype.getPrevLine = function(textArray, pos) {
      if (pos == null) {
        pos = this.currentPos() - 1;
      }
      pos = this.getPosBeginningOfLine(textArray, pos);
      return this.getCurrentLine(textArray, pos - 2);
    };

    MarkdownEditor.prototype.getPosEndOfLine = function(textArray, pos) {
      if (pos == null) {
        pos = this.currentPos();
      }
      while (textArray[pos] && textArray[pos] !== "\n") {
        pos++;
      }
      return pos;
    };

    MarkdownEditor.prototype.getPosBeginningOfLine = function(textArray, pos) {
      if (pos == null) {
        pos = this.currentPos();
      }
      while (textArray[pos - 1] && textArray[pos - 1] !== "\n") {
        pos--;
      }
      return pos;
    };

    MarkdownEditor.prototype.getCurrentLine = function(textArray, pos) {
      var afterChars, beforeChars, initPos;
      if (textArray == null) {
        textArray = this.getTextArray();
      }
      if (pos == null) {
        pos = this.currentPos() - 1;
      }
      initPos = pos;
      beforeChars = '';
      while (textArray[pos] && textArray[pos] !== "\n") {
        beforeChars = "" + textArray[pos] + beforeChars;
        pos--;
      }
      pos = initPos + 1;
      afterChars = '';
      while (textArray[pos] && textArray[pos] !== "\n") {
        afterChars = "" + afterChars + textArray[pos];
        pos++;
      }
      return "" + beforeChars + afterChars;
    };

    MarkdownEditor.prototype.removeCurrentLine = function(textArray) {
      var beginPos, endPos, removeLength;
      endPos = this.getPosEndOfLine(textArray);
      beginPos = this.getPosBeginningOfLine(textArray);
      removeLength = endPos - beginPos;
      textArray.splice(beginPos, removeLength);
      this.$el.val(textArray.join(''));
      return this.setSelectionRange(beginPos, beginPos);
    };

    MarkdownEditor.prototype.tabToSpace = function(e) {
      var currentLine, pos, text;
      if (e.keyCode !== KeyCodes.tab) {
        return;
      }
      e.preventDefault();
      if (this.options.table) {
        text = this.replaceEscapedPipe(this.getText());
        currentLine = this.getCurrentLine(text);
        if (currentLine.match(rowFormat)) {
          if (e.shiftKey) {
            this.moveToPrevCell(text);
          } else {
            this.moveToNextCell(text);
          }
          return;
        }
      }
      if (this.options.tabToSpace) {
        text = this.getTextArray();
        currentLine = this.getCurrentLine(text);
        if (this.options.list && currentLine.match(listFormat)) {
          pos = this.getPosBeginningOfLine(text);
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
      }
    };

    MarkdownEditor.prototype.moveToPrevCell = function(text, pos) {
      var ep, epAdded, overSep, prevLine, sp, ssp;
      if (pos == null) {
        pos = this.currentPos() - 1;
      }
      overSep = false;
      prevLine = false;
      ep = pos;
      while (text[ep]) {
        if (overSep && ep < 0 || !overSep && ep <= 0) {
          return false;
        }
        if (prevLine && text[ep] !== ' ' && text[ep] !== '|') {
          return false;
        }
        if (!overSep) {
          if (text[ep] === '|') {
            overSep = true;
            prevLine = false;
          }
        } else if (text[ep] !== ' ') {
          if (text[ep] === "\n") {
            overSep = false;
            prevLine = true;
          } else {
            if (text[ep] === '|') {
              ep++;
            }
            if (text[ep] === ' ') {
              ep++;
            }
            break;
          }
        }
        ep--;
      }
      if (ep < 0) {
        return false;
      }
      ssp = sp = ep;
      epAdded = false;
      while (text[sp] && text[sp] !== '|') {
        if (text[sp] !== ' ') {
          ssp = sp;
          if (!epAdded) {
            ep++;
            epAdded = true;
          }
        }
        sp--;
      }
      this.setSelectionRange(ssp, ep);
      return true;
    };

    MarkdownEditor.prototype.moveToNextCell = function(text, pos) {
      var eep, ep, overSep, overSepSpace, sp;
      if (pos == null) {
        pos = this.currentPos();
      }
      overSep = false;
      overSepSpace = false;
      eep = null;
      sp = pos;
      while (text[sp]) {
        if (sp > 0 && text[sp - 1] === "\n" && text[sp] !== '|') {
          sp--;
          eep = sp;
          break;
        }
        if (!overSep) {
          if (text[sp] === '|') {
            overSep = true;
          }
        } else if (text[sp] !== ' ') {
          if (text[sp] === "\n") {
            overSep = false;
          } else {
            break;
          }
        } else {
          if (overSepSpace) {
            break;
          }
          overSepSpace = true;
        }
        sp++;
      }
      if (!text[sp]) {
        sp--;
        eep = sp;
      }
      if (!eep) {
        eep = ep = sp;
        while (text[ep] && text[ep] !== '|') {
          if (text[ep] !== ' ') {
            eep = ep + 1;
          }
          ep++;
        }
      }
      this.setSelectionRange(sp, eep);
      return true;
    };

    MarkdownEditor.prototype.insertSpaces = function(text, pos) {
      var nextPos;
      nextPos = this.currentPos() + this.tabSpaces.length;
      this.insert(text, this.tabSpaces, pos);
      return this.setSelectionRange(nextPos, nextPos);
    };

    MarkdownEditor.prototype.removeSpaces = function(text, pos) {
      text.splice(pos, this.tabSpaces.length);
      pos = this.currentPos() - this.tabSpaces.length;
      this.$el.val(text.join(''));
      return this.setSelectionRange(pos, pos);
    };

    MarkdownEditor.prototype.insert = function(textArray, insertText, pos) {
      if (pos == null) {
        pos = this.currentPos();
      }
      textArray.splice(pos, 0, insertText);
      this.$el.val(textArray.join(''));
      pos += insertText.length;
      return this.setSelectionRange(pos, pos);
    };

    MarkdownEditor.prototype.currentPos = function() {
      return this.$el.caret('pos');
    };

    MarkdownEditor.prototype.destroy = function() {
      this.$el.off('keydown.markdownEditor').data('markdownEditor', null);
      return this.$el = null;
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
        list: true,
        table: true
      }, options);
      this.each(function() {
        return $(this).data('markdownEditor', new MarkdownEditor(this, options));
      });
      return this;
    }
  };

}).call(this);
