let verbose = ref(true);

module Ocamlfind = {
  let cmas: string => string =
    name =>
      Utils.execute(
        ~verbose,
        ["ocamlfind query", name, "-r -predicates byte -a-format"],
      );
  let cmis: string => string =
    name =>
      Utils.execute(
        ~verbose,
        ["ocamlfind query", name, "-r -predicates byte -i-format"],
      );
};

module Ocamlc = {
  let archive = (aFiles, output) => {
    let cma = output ++ ".cma";
    Utils.execute(~verbose, ["ocamlc -a", aFiles, "-o", cma]) |> ignore;
    cma;
  };
};

module Jsoo = {
  let lib = name => name ++ ".sketch.lib.js";

  let autoBootstrap = libName =>
    Utils.execute(
      ~verbose,
      [
        "echo \"sketch_private__" ++ libName ++ "(self);\"",
        ">>",
        lib(libName),
      ],
    )
    |> ignore;

  let compile = (libName, archive, cmis) =>
    Utils.execute(
      ~verbose,
      [
        "js_of_ocaml",
        "--wrap-with-fun=sketch_private__" ++ libName,
        "--toplevel",
        cmis,
        archive,
        "-o",
        lib(libName),
      ],
    )
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
