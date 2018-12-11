engine:
	esy @sketch build

clean:
	esy @sketch dune clean

js:
	# Compiling engine to Javascript
	esy @sketch dune build src/engine/engine.byte
	mkdir -p build/engine
	cp _build/default/src/engine/*.js ./build/engine

packages: engine
	# Compiling libraries to Javascript
	esy @sandbox build

test:
	esy test

all: js

upload:
	surge build/packages

.PHONY: engine js all test clean packages
