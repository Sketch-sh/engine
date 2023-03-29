let verbose = ref(true);
let exec = Utils.execute(~verbose);

module Ocamlfind = {
  let cmas = name =>
    ["ocamlfind query", name, "-r -predicates byte -a-format"] |> exec;
  let cmis = name =>
    ["ocamlfind query", name, "-r -predicates byte -i-format"] |> exec;
};

module Ocamlc = {
  let archive = (aFiles, output) => {
    let cma = output ++ ".cma";
    ["ocamlc -a", aFiles, "-o", cma] |> exec |> ignore;
    cma;
  };
};

module Jsoo = {
  let lib = name => name ++ ".sketch.lib.js";

  let autoBootstrap = libName =>
    ["echo \"sketch_private__" ++ libName ++ "(self);\"", ">>", lib(libName)]
    |> exec
    |> ignore;

  let compile = (libName, archive, cmis) =>
    [
      "js_of_ocaml",
      "--wrap-with-fun=sketch_private__" ++ libName,
      "--toplevel",
      cmis,
      archive,
      "-o",
      lib(libName),
    ]
    |> exec
    |> ignore;
};

module Cli = {
  let run = () => {
    let libName = Sys.argv[1];
    Printf.printf("Beginning build for \"%s\"...\n", libName);

    let cmas = Ocamlfind.cmas(libName);
    let cmis = Ocamlfind.cmis(libName);
    let bundle = Ocamlc.archive(cmas, libName);
    Jsoo.compile(libName, bundle, cmis);
    Jsoo.autoBootstrap(libName);

    Printf.printf("📦 Done!\n");
  };
};

Cli.run();
