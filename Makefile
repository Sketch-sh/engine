all:
	jbuilder build @install -j 8 --dev

clear:
	$(MAKE) -C build clear

toplevel: clear all
	jbuilder exec -- make -C build

test: 
	cd test && npm test

ci: toplevel test

do_it: toplevel
	$(MAKE) -C build plugin

.PHONY: all toplevel test ci
