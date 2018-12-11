engine:
	esy @sketch build

clean:
	esy @sketch dune clean

# I'm not sure how to tell dune keeping track of 
# generated js files so a clean is neccessary 
# before copying the js files out
js: clean
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
