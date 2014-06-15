module.exports = function(grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        
        codo: {
                options: {
		    undocumented: true, 
		    title: "<%= pkg.name %>",
                    output: "dist/docs",
                    flags: ['--verbose'],
                    inputs: ["coffee"]
	          }
	},


        // use concat to put all the js into one file.
        concat: {
            options: {
                separator: ';'
            },
            dist: {
                src: ['dist/js/**/!(*concat).js', 'dist/js/!(*concat).js'],
                dest: 'dist/js/<%= pkg.name %>_concat.js'
            }
	},

        uglify: {
            options: {
                banner: '/*! <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
            },
            dist: {
                files: {
                    'dist/<%= pkg.name %>.min.js': ['<%= concat.dist.dest %>']
                }
            }
        },
        
        qunit: {
            files: ['test/**/*.html']
        },

        jshint: {
            files: ['js/**/!(*compiled).js'],
            options: {
                globals: {
                    console: true,
                    module: true,
                },
	        force: true
            }
        },

        coffee: {
            compile: {
                options: {
                    join: true,
                },
		files: {'dist/js/SVGNodeView_compiled.js': ['coffee/registerGlobal.coffee',
			                                    'coffee/SVGNodeView.coffee']
                }
            }
        },

        compass: {
            dist: {
		options: {
                    cssDir: 'dist/css/',
		    sassDir: 'scss/'
                    }
	    }
        },


        watch: {
            css: {
                files: 'scss/*.scss',
                tasks: ['compass']
            },
            coffee: {
                files: ['coffee/**/*.coffee', 'test/coffee/**/*.coffee'],
                tasks: ['coffee', 'codo']
            },
            js: {
                files: ['js/**/*.js', 'test/**/*.js'],
                tasks: ['jshint', 'concat', 'uglify']
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-qunit');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-compass');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-codo');

    grunt.registerTask('default', ['watch']);


};
