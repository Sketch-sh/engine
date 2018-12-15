/**
 * How this works?
 * 1. Build a dependencies list of the current package in the correct loading order
 *    ocamlfind query PACKAGE_NAME -r -p-format -predicates byte
 * 2. With that list of all packages. We can find cmi and cma files and building them one by one
 *    ocamlfind query PACKAGE_NAME -i-format -predicates byte
 *    ocamlfind query PACKAGE_NAME -a-format -predicates byte
 * 3. There are some deduplication going on so we don't build the package twice
 */
open Utils;
let verbose = ref(false);
let output = ref(None);

let execute = execute(~verbose);

let usage = () => {
  Format.eprintf("Usage: sketch [find packages] @.");
  Format.eprintf(" --verbose@.");
  Format.eprintf(" --output\t\t\tBuild output directory@.");
  Format.eprintf(" --help\t\t\tDisplay usage@.");
  exit(1);
};

let rec scan_args = acc =>
  fun
  | ["--verbose", ...xs] => {
      verbose := true;
      scan_args(acc, xs);
    }
  | ["--help" | "-h", ..._] => usage()
  | ["--output", outputDir, ...xs] => {
      output := Some(outputDir);
      scan_args(acc, xs);
    }
  | [x, ...xs] => scan_args([x, ...acc], xs)
  | [] => List.rev(acc);

let findDeps = name =>
  execute([
    "ocamlfind",
    "query",
    name,
    "-r",
    "-p-format",
    "-predicates byte",
  ]);
let findCmi = name =>
  execute(["ocamlfind", "query", name, "-i-format", "-predicates byte"]);
let findCma = name =>
  execute(["ocamlfind", "query", name, "-a-format", "-predicates byte"]);

let buildLib = (~outputDir, packageName) => {
  if (verbose^) {
    Printf.printf("Building library with jsoo: %s\n", packageName);
  };
  let safePkgName = toSafePackageName(packageName);
  let funcName = "sketch__private__" ++ safePkgName;

  let cmaPath = findCma(packageName);
  switch (String.trim(cmaPath)) {
  | "" => print_endline("Can't find cma file for package " ++ packageName)
  | _ =>
    execute([
      "js_of_ocaml",
      "--wrap-with-fun=" ++ funcName,
      "--toplevel",
      findCmi(packageName),
      findCma(packageName),
      "-o",
      Filename.concat(outputDir, safePkgName ++ ".lib.sketch.js"),
    ])
    |> ignore
  };
};

module SS = Set.Make(String);
module LibMap = Map.Make(String);

/*
 * These packages are for compatibility with OCaml
 * But Sketch only supports OCaml > 4.06
 * So this will result in not found packages
 */

let excludedPackages = SS.of_list(["uchar", "result", "bytes"]);

module J = Json;

let build = (~outputDir, toplevelPkgs) => {
  /* if (verbose^) {
       Printf.printf("Building dependencies for: %s\n", toplevelPkg);
     }; */
  let libsToBuild = ref(SS.empty);
  let libsWithDependencies =
    toplevelPkgs
    |> List.fold_left(
         (map: LibMap.t(list(string)), pkg) => {
           let allDeps =
             findDeps(pkg)
             |> String.split_on_char('\n')
             |> List.filter(name => name != "")
             |> List.filter(name => !SS.mem(name, excludedPackages));

           let _ =
             allDeps
             |> List.iter(name => libsToBuild := libsToBuild^ |> SS.add(name));

           map |> LibMap.add(pkg, allDeps);
         },
         LibMap.empty,
       );

  let _ = libsToBuild^ |> SS.iter(name => buildLib(~outputDir, name));
  let _ =
    LibMap.fold(
      (topName, libs, acc) => {
        let libField =
          J.Object([
            (topName, J.Array(libs |> List.map(name => J.String(name)))),
          ]);
        [libField, ...acc];
      },
      libsWithDependencies,
      [],
    )
    |> (list => J.Array(list))
    |> (json => J.stringify(json))
    |> writeFileSync(~path=Filename.concat(outputDir, "list.json"));
  ();
};

let _ = {
  let args = List.tl(Array.to_list(Sys.argv));
  let args = scan_args([], args);

  let outputDir =
    switch (output^) {
    | None => Filename.concat(Sys.getcwd(), "packages")
    | Some(output) => output
    };
  mkdirp(outputDir);

  build(~outputDir, args);
  print_endline("Done !");
};
