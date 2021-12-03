# sketch-engine
Exposes toplevel functionality for https://github.com/Sketch-sh/sketch-sh

## Installation
This project uses https://opam.ocaml.org/.

install opam: https://opam.ocaml.org/doc/Install.html

create new local switch
```bash
make create-switch
```

install `dune` in the newly created switch:
```bash
opam install dune
```

install dependencies: 

```bash
make install && \
yarn install
```

you might need to install `reason.dev` package which is retrieved from repository (as 4.13 compatible version is not published in opam as of when this readme was last written):

```bash
opam install reason.dev
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
