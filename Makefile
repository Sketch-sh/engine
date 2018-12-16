engine:
	esy @sketch build

clean:
	esy @sketch dune clean
	rm -rf build
js:
	# Compiling engine to Javascript
	esy @sketch dune build src/entry/entry.bc.js --profile release
	mkdir -p build/engine
	cp _build/default/src/entry/entry.bc.js ./build/engine/engine.js

packages: engine
	# Compiling libraries to Javascript
	esy @sandbox build

test:
	esy test

all: js

upload:
	surge build/packages

.PHONY: engine js all test clean packages
