
dist: src/*.js
	node_modules/babel-cli/bin/babel.js src --out-dir dist

watch:
	while true; do \
	      make dist; \
	      inotifywait -qre close_write .; \
	  done
