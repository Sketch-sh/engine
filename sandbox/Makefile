all:
	rm -rf packages
	mkdir -p packages
	esy ./packager.exe base containers owl-base re
	echo "libraries.sketch.sh" > packages/CNAME

.PHONY: all
