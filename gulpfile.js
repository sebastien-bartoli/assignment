var gulp = require('gulp');
var browserSync = require('browser-sync').create();
var sass = require('gulp-sass');
var coffeescript = require('gulp-coffee');

// Static Server
gulp.task('serve', function() {
    browserSync.init({
        server: "."
    });
});

// Watching scss/less/html files
gulp.task('watch', ['sass', 'coffee'], function() {
    gulp.watch("assets/scss/*.scss", ['sass']);
    gulp.watch("assets/js/coffeescript/*.coffee", ['coffee']);
    gulp.watch("assets/less/*.less", ['less']);
    gulp.watch("*.html").on('change', browserSync.reload);
});

gulp.task('coffee', function() {
  gulp.src('assets/js/coffeescript/*.coffee')
    .pipe(coffeescript({bare: true}))
    .pipe(gulp.dest('assets/js/'));
});

// Compile SASS into CSS & auto-inject into browsers
gulp.task('sass', function() {
  return gulp.src("assets/scss/*.scss")
    .pipe(sass({
      sourceComments: 'map',
      sourceMap: 'scss',
      includePaths: [
        'node_modules/foundation-sites/scss'
      ]
    }))
    .pipe(gulp.dest("assets/css"))
    .pipe(browserSync.stream());
});

// Compile LESS into CSS & auto-inject into browsers
gulp.task('less', function() {
  return gulp.src("assets/less/*.less")
    .pipe(less({
      sourceMap: {
        sourceMapRootpath: './assets/less' // Optional absolute or relative path to your LESS files
      }
    }))
    .pipe(gulp.dest("assets/css"))
    .pipe(browserSync.stream());
});


gulp.task('default', ['serve']);
gulp.task('server', ['serve']);
gulp.task('dev', ['watch']);