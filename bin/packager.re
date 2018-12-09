/**
 * How this works? 
 * 1. Build a dependencies list of the current package in the correct loading order
 *    ocamlfind query PACKAGE_NAME -r -p-formate -predicates byte
 * 2. With that list of all packages. We can find cmi and cma files and building them one by one 
 *    ocamlfind query PACKAGE_NAME -i-format -predicates byte
 *    ocamlfind query PACKAGE_NAME -a-format -predicates byte
 * 3. There are some deduplication going on so we don't build the package twice
 */
open Utils;
let verbose = ref(false);
let urlPrefix = ref("https://libraries.sketch.sh");

let execute = cmd => {
  let s = String.concat(" ", cmd);
  if (verbose^) {
    Printf.printf("Executing: %s\n", s);
  };
  let ret = Unix.open_process_in(s);
  let output = ref("");
  try (
    while (true) {
      let l = input_line(ret);
      output := output^ ++ l ++ "\n";
    }
  ) {
  | End_of_file => ()
  };
  output^ |> String.trim;
};

let usage = () => {
  Format.eprintf("Usage: sketch [find packages] @.");
  Format.eprintf(" --verbose@.");
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
  | [x, ...xs] => scan_args([x, ...acc], xs)
  | [] => List.rev(acc);

module SS = Set.Make(String);

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

let build = mainPackageName => {
  if (verbose^) {
    Printf.printf("Building dependencies for: %s\n", mainPackageName);
  };
  let allDeps =
    findDeps(mainPackageName)
    |> String.split_on_char('\n')
    |> List.filter(name => name != "");

  let _ =
    allDeps
    |> List.fold_left(
         (acc, packageName) => {
           let safePackageName = toSafePackageName(packageName);
           let functionName = "sketch__private__" ++ safePackageName;
           let fileName = safePackageName ++ ".lib.sketch.js";
           [
             Printf.sprintf(
               {|importScripts("%s/%s"); %s(self);|},
               urlPrefix^,
               fileName,
               functionName,
             ),
             ...acc,
           ];
         },
         [],
       )
    |> List.rev
    |> String.concat("\n")
    |> writeFileSync(
         ~path=
           "packages/"
           ++ toSafePackageName(mainPackageName)
           ++ ".loader.sketch.js",
       );

  allDeps
  |> List.iter(packageName => {
       let safePackageName =
         packageName |> replace(~find="-", ~replaceWith="_");
       let functionName = "sketch__private__" ++ safePackageName;
       let fileName = safePackageName ++ ".lib.sketch.js";
       let _ =
         execute([
           "js_of_ocaml",
           "--wrap-with-fun=" ++ functionName,
           "--toplevel",
           findCmi(packageName),
           findCma(packageName),
           "-o",
           "packages/" ++ fileName,
         ]);
       ();
     });
};
let _ = {
  let args = List.tl(Array.to_list(Sys.argv));
  let args = scan_args([], args);
  args |> List.iter(build);
  print_endline("Done !");
};
