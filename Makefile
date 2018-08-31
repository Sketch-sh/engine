evaluator:
	esy b $(MAKE) -C evaluator build


copy-evaluator: 
	cp ./evaluator/_build/default/evaluator.js ../rtop_ui/client/public/reason_v2.js

berror:
	$(MAKE) -C berror build

copy-berror: 
	cp ./berror/_build/default/berror.js ../rtop_ui/public/berror.js

clean:
	esy b $(MAKE) -C evaluator clean
	esy b $(MAKE) -C berror clean

test: 
	cd test && npm test

copy: copy-berror copy-evaluator

build: evaluator berror

all: clean evaluator test

ci: evaluator test

.PHONY: evaluator copy-evaluator berror copy-berror clean build all test ci-evaluator ci
