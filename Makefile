evaluator:
	dune build @evaluator/all

js_compile:
	# Compiling evaluator to JS
	dune build evaluator/toplevel.byte --verbose
	cp _build/default/evaluator/*.js ./build

clear:
	rm -rf sandbox/packages/*
	$(MAKE) -C build clear

test:
	cd test && npm test

build_packager:
	# Build external dependencies with packager
	cp ./_build/default/bin/packager.exe ./sandbox/packager.exe
	$(MAKE) -C sandbox all

all: evaluator js_compile build_packager

upload:
	surge sandbox/packages

.PHONY: evaluator js_compile build_packager all test clear
