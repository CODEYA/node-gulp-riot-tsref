var gulp = require('gulp');
var $ = require('gulp-load-plugins')();

gulp.task('compile', function() {
  return gulp.src('src/*.ls')
             .pipe($.livescript({bare: true}))
             .pipe(gulp.dest('./build'));
});

gulp.task('test-compile', ['compile'], function () {
  return gulp.src('test/*.ls')
             .pipe($.livescript())
             .pipe($.espower())
             .pipe(gulp.dest('./powered-test'));
});
gulp.task('test', ['test-compile'], function() {
  return gulp.src('powered-test/*.js')
             .pipe($.mocha());
});

gulp.task('default', ['test']);
