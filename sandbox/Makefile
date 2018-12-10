all:
	rm -rf packages
	mkdir -p packages
	esy ./packager.exe --verbose \
		base containers owl-base re lwt \
		sexplib ocamlgraph unix
	echo "libraries.sketch.sh" > packages/CNAME

.PHONY: all
