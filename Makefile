.PHONY: run build watch setup clean

run: build
	open build/index.html

build: clean
	@mkdir -p build
	haxe build.hxml
	cp index.html build/

watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@fswatch -o src/ res/ | xargs -n1 -I{} make build

setup:
	haxelib install heaps
	@echo "Optional: brew install fswatch (for make watch)"

clean:
	rm -f build/game.js
