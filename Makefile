.PHONY: run watch setup clean

run: build
	open build/index.html

build:
	haxe build.hxml

watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@fswatch -o src/ res/ | xargs -n1 -I{} make build

setup:
	haxelib install heaps
	@echo "Optional: brew install fswatch (for make watch)"

clean:
	rm -rf build/
