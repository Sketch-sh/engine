evaluator:
	esy @sketch dune build @install -j 8

js_compile:
	# Compiling evaluator to JS
	dune build evaluator/toplevel.byte --verbose
	cp _build/default/evaluator/*.js ./build

clear:
	rm -rf sandbox/packages/*
	dune clean

test:
	cd test && npm test

build_packager:
	# Build external dependencies with packager
	dune build bin/packager.exe
	cp ./_build/default/bin/packager.exe ./sandbox/packager.exe
	$(MAKE) -C sandbox all

all: js_compile build_packager

upload:
	surge build/packages

.PHONY: evaluator js_compile build_packager all test clear
