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

      if opts["mode"] == "compile" && opts["precompiled"] != null
        configureTypeScriptMerger callback, opts["precompiled"]
      else
        configureTypeScriptCompiler callback

      try
        gutil.log(gutil.colors.grey('Compiling riot tag : ' + file.path))
        if(!opts["parserOptions"])
          opts["parserOptions"]       = {}
        if(!opts["parserOptions"]["js"])
          opts["parserOptions"]["js"] = {}
        if opts["mode"] == "extract"
          opts["entities"] = true
          opts["parserOptions"]["js"]["mode"] = "extract"
        else
          opts["parserOptions"]["js"]["path"] = file.path
          opts["parserOptions"]["js"]["base"] = file.base
        compiled-code = compile file.contents.to-string!, opts, file.path
        if opts["mode"] == "extract"
          if(compiled-code && compiled-code.length > 0 && compiled-code[0]["js"])
            compiled-code = compiled-code[0]["js"]
          else
            compiled-code = ""
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
      file.path = convertTagnameToScriptname file.path
      callback null, file

  # TypeScript のコードから "/// <reference />" を切り出す regexp
  REFERENCES = /\/\/\/\s*<reference(\s+[^>]*)?\/>\n?/gi

  # 拡張子を置き換え Tag 名を Script 名に変換する
  convertTagnameToScriptname = (tagname) ->
    splited-path = tagname.split \.
    if opts["mode"] === "extract"
      if opts["type"] === "typescript"
        splited-path[*-1] = \ts
      else if opts["type"] === "livescript"
        splited-path[*-1] = \ls
      else if opts["type"] === "coffee"
        splited-path[*-1] = \coffee
      else if opts["type"] === "coffeescript"
        splited-path[*-1] = \coffee
      else
        splited-path[*-1] = \js
    else
      splited-path[*-1] = \js
    return splited-path.join \.

  # TypeScript コンパイラーをラップし、precompiled code を利用するようにする。
  configureTypeScriptMerger = (callback, precompiled) ->
    # "tss" を置き換える。
    parsers["js"]["typescript"] = (code, options) ->
      // precompiled code のパスを作成する。
      tagFile = convertTagnameToScriptname options["path"]
      tagBase = options["base"]
      precompiledTagFile = path.resolve path.join(precompiled, tagFile.replace(tagBase, ""))
      // precompiled code を返す。
      return fs.readFileSync(precompiledTagFile, 'utf-8')

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
        if options["mode"] === "extract"
          return code
        else
          # "<reference>" の置換を行う。
          tagFile = options["path"]
          tagDir = path.parse(tagFile).dir
          code = code.replace REFERENCES, (_m, _attrs, _script) ->
            refPath = _attrs.replace /^.*?path="([^"]*)".*?$/gi (_m2, _attrs2, _script) ->
              return (path.resolve path.join(tagDir, _attrs2)).toString().trim()
            try
              refContents = fs.readFileSync(refPath, 'utf-8')
              gutil.log(gutil.colors.grey('Referenced file found : ' + refPath))
            catch err
              gutil.log(gutil.colors.red('No referenced file found : ' + refPath))
              return ""
            return refContents + "\n\n"
          tss(code, options)

  through.obj transform
