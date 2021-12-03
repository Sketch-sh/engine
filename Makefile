project_name = sketch_engine

opam_file = $(project_name).opam

create-switch:
	opam switch create . 4.13.1 --deps-only

# Alias to update the opam file and install the needed deps
install: $(opam_file)

fmt:
	dune build @fmt --auto-promote
	
build:
	dune build

clean:
	dune clean
	rm -rf build

js:
	# Compiling engine to Javascript
	dune build  --profile release src/entry/entry.js
	mkdir -p build/engine
	cp _build/default/src/entry/entry.js ./build/engine/engine.js

packages: engine
	# Compiling libraries to Javascript
	sketch.packager --output build/packages base containers lwt owl-base re ocamlgraph sexplib unix

test:
	yarn test

all: js

.PHONY: create-switch install fmt build js all test clean packages

# Update the package dependencies when new deps are added to dune-project
$(opam_file): dune-project
	-dune build @install        # Update the $(project_name).opam file
	opam install . --deps-only  # Install the new dependencies