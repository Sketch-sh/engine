evaluator:
	# Building the evaluator and packager
	dune build @install -j 8

js_compile: clear all
	# Compiling evaluator to JS
	dune exec -- make -C build

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
