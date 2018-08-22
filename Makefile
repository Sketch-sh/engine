all:
	refmterr dune build @install -j 8

clear:
	rm -rf packages/*
	$(MAKE) -C build clear

toplevel: clear all
	dune exec -- make -C build

test: 
	cd test && npm test

ci: toplevel test

plugin: 
	$(MAKE) -C generate re unix owl	

package: all
	dune exec -- sketch re owl-base

.PHONY: all toplevel test ci package
