all:
	esy b jbuilder build @install -j 8 --dev

clear:
	$(MAKE) -C build clear

toplevel: clear all
	esy b jbuilder exec -- make -C build

test: 
	cd test && jest

ci: toplevel test

.PHONY: all toplevel test ci
