module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    clean:
      all: ['dist']
      options:
        'no-write': true
    watch:
      coffee:
        tasks: ['coffee']
        files: ['src/*.coffee']
      html:
        tasks: ['copy']
        files: ['src/index.html', 'src/marked.min.js']
    coffee:
      main:
        files:
          'dist/textarea-markdown-editor.js': 'src/textarea-markdown-editor.coffee'
    copy:
      main:
        files:
          'dist/index.html': 'src/index.html'
          'dist/marked.min.js': 'bower_components/marked/marked.min.js'
    karma:
      continuous:
        configFile: 'karma.conf.coffee'

  grunt.registerTask 'default', ['clean', 'coffee', 'copy']

  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-karma')
