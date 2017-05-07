# gulp-riot-tsref

A gulp plugin for riot with TypeScript reference support.
This is a fork of the gulp-riot module (Much appreciate to jigsaw).

[![Circle CI](https://circleci.com/gh/CODEYA/node-gulp-riot-tsref/tree/master.svg?style=svg)](https://circleci.com/gh/CODEYA/node-gulp-riot-tsref/tree/master)
[![npm version](https://badge.fury.io/js/gulp-riot-tsref.svg)](http://badge.fury.io/js/gulp-riot-tsref)
[![npm downloads](https://img.shields.io/npm/dm/gulp-riot-tsref.svg)](https://img.shields.io/npm/dm/gulp-riot-tsref.svg)
[![npm license](https://img.shields.io/npm/l/gulp-riot-tsref.svg)](https://img.shields.io/npm/l/gulp-riot-tsref.svg)
[![Dependency Status](https://gemnasium.com/CODEYA/node-gulp-riot-tsref.svg)](https://gemnasium.com/CODEYA/node-gulp-riot-tsref)

# Install

With [npm](https://www.npmjs.com/) do:

```bash
$ npm install --save-dev gulp-riot-tsref
```

# Usage

This plugin compile [riot](https://github.com/muut/riotjs)'s `.tag` files.
This plugin also extract a script block from `.tag` files.

## Example

### Mode `extract`

`example.tag`:

```jsx
<example>
  <p>This is { sample }</p>

  <script>
    /// <reference path="hoge.d.ts" />
    this.sample = new Hoge.Fuga().getMessage();
  </script>
</example>
```

`gulpfile.js`:

```js
var gulp = require('gulp');
var riot = require('gulp-riot-tsref');

gulp.task('riot:extract', function() {
  return gulp.src('example.tag')
             .pipe(riot({"mode": "extract"}))
             .pipe(gulp.dest('dest'));
});
```

Run task:

```sh
% gulp riot:extract
% cat example.ts
/// <reference path="hoge.d.ts" />
this.sample = new Hoge.Fuga().getMessage();
```

### Mode `compile`

`example.tag`:

```jsx
<example>
  <p>This is { sample }</p>

  <script>
    /// <reference path="hoge.d.ts" />
    this.sample = new Hoge.Fuga().getMessage();
  </script>
</example>
```

[NOTE] The path attribute must be absolute path or relative path from the current working directory.

`hoge.d.ts`

```js
declare module Hoge {
    class Fuga {
        getMessage(): string;
    }
}
```

`gulpfile.js`:

```js
var gulp = require('gulp');
var riot = require('gulp-riot-tsref');

gulp.task('riot:compile', function() {
  return gulp.src('example.tag')
             .pipe(riot())
             .pipe(gulp.dest('dest'));
});
```

Run task:

```sh
% gulp riot:compile
% cat example.js
riot.tag('example', '<p>This is { sample }</p>', function(opts) {
  this.sample = new Hoge.Fuga().getMessage();
})
```

## Compile options

This plugin can give riot's compile options.

```js
  gulp.src('example.tag')
      .pipe(riot({
        compact: true // <- this
      }))
      .pipe(gulp.dest('dest'));
```

### Available option

* mode: `String, compile(default) | extract`
* compact: `Boolean`
  * Minify `</p> <p>` to `</p><p>`
* whitespace: `Boolean`
  * Escape `\n` to `\\n`
* expr: `Boolean`
  * Run expressions through parser defined with `--type`
* type: `String, coffeescript | typescript | cs | es6 | livescript | none`
  * JavaScript parser
* template: `String, jade`
  * Template parser
  * See more: https://muut.com/riotjs/compiler.html
* modular: `Boolean`
  * For AMD and CommonJS option
  * See more: http://riotjs.com/guide/compiler/#pre-compilation
* parsers: `Object`
  * Define custom parsers
  * css: `Function`
    * See more: http://riotjs.com/api/compiler/#css-parser
  * js: `Function`
    * See more: http://riotjs.com/api/compiler/#js-parser
  * html: `Function`
    * See more: http://riotjs.com/api/compiler/#html-parser

# Building

In order to build the gulp-riot-tsref, ensure that you have [git](http://git-scm.com/) and [node.js](http://nodejs.org/) installed.

Clone a copy of the repository:

```bash
$ git clone git@github.com:CODEYA/gulp-riot-tsref.git
```

Change to the gulp-riot-tsref directory:

```bash
$ cd gulp-riot-tsref
```

Install dev dependencies:

```bash
$ npm install
```

Build the gulp-riot-tsref:

```bash
$ npm run build
```

Test the gulp-riot-tsref:

```bash
$ npm test
```
