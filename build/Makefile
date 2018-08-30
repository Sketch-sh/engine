# This Makefile is adopted from 
# https://github.com/ocsigen/js_of_ocaml/blob/d31eecb413c2dc7ca5369caa4f89966ecef4a908/toplevel/examples/lwt_toplevel_bin/Makefile

all: toplevel.js

ifeq ($(shell ocamlc -safe-string 2> /dev/null ; echo $$?),0)
SAFESTRING=-safe-string
else
SAFESTRING=-package bytes
endif


PACKAGES= \
	sketch_evaluator \
	compiler-libs.common \
	# owl-base \

ifeq ($(WITH_ASYNC_JS),YES)
PACKAGES += async_js core_kernel async_kernel base
JSFILES += +base/runtime.js +core_kernel/runtime.js +bin_prot/runtime.js +ppx_expect/collector/runtime.js
endif

ifeq ($(WITH_PPX),YES)
PACKAGES += js_of_ocaml-ppx.as-lib
endif

ifeq ($(WITH_GRAPHICS),YES)
JSFILES += +graphics.js
PACKAGES += graphics js_of_ocaml-lwt.graphics
endif

MKTOP=jsoo_mktop -verbose $(SAFESTRING) -g \
	${addprefix -top-syntax , ${SYNTAXES}} \
	${addprefix -export-package , ${PACKAGES}} \
	# -jsopt "--disable shortvar --pretty" \

JSFILES= +toplevel.js +dynlink.js +nat.js

TOPLEVEL_NAME=toplevel
$(TOPLEVEL_NAME).js:
	$(MKTOP) \
	$(BER) \
	${addprefix -jsopt , ${JSFILES}} \
	-o $(TOPLEVEL_NAME).byte

clear:
	rm -f *.js *.byte

CMA_PATH=$(shell ocamlfind query owl-base -a-format -predicates byte)
CMA_FOLDER=$(shell ocamlfind query owl-base)

plugin:
	js_of_ocaml --wrap-with-fun=owlBaseCma ${CMA_PATH} -o owl-base.cma.js && \
	jsoo_mkcmis owl-base -o owl-base.cmis.js
