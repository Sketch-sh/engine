# sketch-engine
Exposes toplevel functionality for https://github.com/Sketch-sh/sketch-sh

## Installation
This project uses https://esy.sh

install esy: `npm install -g esy`

install dependencies: 

```bash
esy @sketch install && \
esy @sandbox install && \
cd test && npm install
```

## Build

- For engine and packager development:

```
make engine
```

- For compiling engine to Javascript (this takes awhile):

```
make js
````

Build artifacts in `build/engine`

- For compiling packages to Javscript

```
make packages
```

Build artifacts in `build/packages`

## Adding new package to the sandbox

```
esy @sandbox add @opam/PACKAGE_NAME
```

Open `sandbox.json` and add the name of the package to `esy.build`

## Test

```
make test
```
