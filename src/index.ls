require! {
  \gulp-util : gutil
  through2: through
  riot: {compile, parsers}
  path: path
  fs: fs
}

module.exports = (opts = {})->
  transform = (file, encoding, callback)->
    | file.is-null! => callback null, file
    | file.is-stream! => callback new gutil.PluginError \gulp-riot, 'Stream not supported'
    | otherwise =>
      if opts.parsers?
        Object
          .keys opts.parsers
          .for-each (x)->
            Object
              .keys opts.parsers[x]
              .for-each (y)-> parsers[x][y] = opts.parsers[x][y]
        delete opts.parsers

      configureTypeScriptCompiler callback

      try
        gutil.log(gutil.colors.grey('Compiling riot tag : ' + file.path))
        compiled-code = compile file.contents.to-string!, opts, file.path
      catch err
        return callback new gutil.PluginError \gulp-riot, "#{file.path}: Compiler Error: #{err}"

      if opts.modular
        compiled-code = """
          (function(tagger) {
            if (typeof define === 'function' && define.amd) {
              define(['riot'], function(riot) { tagger(riot); });
            } else if (typeof module !== 'undefined' && typeof module.exports !== 'undefined') {
              tagger(require('riot'));
            } else {
              tagger(window.riot);
            }
          })(function(riot) {
          #{compiledCode}

          });
        """

      file.contents = new Buffer compiledCode
      splited-path = file.path.split \.
      splited-path[*-1] = \js
      file.path = splited-path.join \.
      callback null, file

  # TypeScript のコードから "/// <reference />" を切り出す regexp
  REFERENCES = /\/\/\/\s*<reference(\s+[^>]*)?\/>\n?/gi

  # TypeScript コンパイラーをラップし、"<reference>" の置換を行うようにする。
  configureTypeScriptCompiler = (callback) ->
    parser = parsers["js"]["typescript"]
    # TypeScript コンパイラーが "_loadParser" の場合(初回実行の場合)
    if (typeof parser === 'function') && ("" + parser).startsWith("function _loadParser")
      # "_loadParser" を実行し、"tss" に置き換える。
      parser("", {}, "", 0)
      # "tss" を取得。
      tss = parsers["js"]["typescript"]
      # "tss" をラップする。
      parsers["js"]["typescript"] = (code, options) ->
        # "<reference>" の置換を行う。
        code = code.replace REFERENCES, (_m, _attrs, _script) ->
          refPath = _attrs.replace /^.*?path="([^"]*)".*?$/gi (_m2, _attrs2, _script) ->
            return (path.resolve _attrs2).toString().trim()
          try
            refContents = fs.readFileSync(refPath, 'utf-8')
            gutil.log(gutil.colors.grey('Referenced file found : ' + refPath))
          catch err
            gutil.log(gutil.colors.red('No referenced file found : ' + refPath))
            return ""
          return refContents + "\n\n"
        tss(code, options)

  through.obj transform
