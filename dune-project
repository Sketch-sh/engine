(lang dune 2.0)
(generate_opam_files true)

(name sketch_engine)
(version 0.0.2)

(authors "Khoa Nguyen" "Javier Chávarri")
(license "Apache-2.0")
(source (uri "git+https://github.com/Sketch-sh/engine.git"))
(maintainers "javier.chavarri@ahrefs.com")
(homepage "https://github.com/Sketch-sh/engine")
(bug_reports "https://github.com/Sketch-sh/engine/issues")
(documentation "https://github.com/Sketch-sh/engine")

(package
 (name sketch_engine)
 (synopsis "Toplevel functionality for https://github.com/Sketch-sh/sketch-sh")
 (description "In-browser compiler for https://github.com/Sketch-sh/sketch-sh")
 (depends
  ;; General system dependencies
  (dune (and (>= 2) (< 3)))
  (ocaml (and (>= 4.13.1) (< 4.14)))
  
  ;; Engine dependencies
  (js_of_ocaml (and (>= 3.11.0) (< 3.12.0)))
  (js_of_ocaml-compiler (and (>= 3.11.0) (< 3.12.0)))
  (js_of_ocaml-ppx (and (>= 3.11.0) (< 3.12.0)))
  (js_of_ocaml-toplevel (and (>= 3.11.0) (< 3.12.0)))

  ;; Dev dependencies
  (ocamlformat :dev)
  (ocaml-lsp :dev)
))