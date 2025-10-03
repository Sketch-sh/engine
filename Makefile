project_name = sketch_engine

opam_file = $(project_name).opam

.DEFAULT_GOAL := help

.PHONY: help
help: ## Print this help message
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: create-switch
create-switch:
	opam switch create . 5.3.0 --deps-only

.PHONY: install
install: $(opam_file) ## Alias to update the opam file and install the needed deps

.PHONY: format
format: ## Format the codebase with ocamlformat
	dune build @fmt --auto-promote
	
.PHONY: build
build: ## Build the project, including non installable libraries and executables
	dune build @@default

.PHONY: clean
clean: ## Clean the project
	dune clean
	rm -rf build

.PHONY: js_dev
js_dev: ## Create engine .js artifact in dev mode
	# Compiling engine to Javascript with dev mode
	dune build @@src/entry/dev
	mkdir -p build/engine
	cp _build/default/src/entry/entry_dev.js ./build/engine/engine.js

.PHONY: js_prod
js_prod: ## Create engine .js artifact in prod mode
	# Compiling engine to Javascript with prod mode (no --pretty)
	dune build @@src/entry/prod
	mkdir -p build/engine
	cp _build/default/src/entry/entry.js ./build/engine/engine.js

.PHONY: packages
packages: engine ## Compiling libraries to Javascript
	sketch.packager --output build/packages base containers lwt owl-base re ocamlgraph sexplib unix

.PHONY: test
test: js_prod ## Run end-to-end tests
	yarn test

.PHONY: test_promote
test_promote: js_prod ## Run end-to-end tests and promote snapshot
	yarn test-promote

# Update the package dependencies when new deps are added to dune-project
$(opam_file): dune-project $(opam_file).template
	-dune build @install        # Update the $(project_name).opam file
	opam install . --deps-only  # Install the new dependencies
