let execute = (~verbose, cmd) => {
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

let replace = (~find, ~replaceWith) =>
  Str.global_replace(Str.regexp_string(find), replaceWith);

let writeFileSync = (~path, content) => {
  let channel = open_out(path);
  output_string(channel, content);
  close_out(channel);
};

let maybeStat = path =>
  try (Some(Unix.stat(path))) {
  | Unix.Unix_error(Unix.ENOENT, _, _) => None
  };

let isDirectory = path =>
  switch (maybeStat(path)) {
  | Some({Unix.st_kind: Unix.S_DIR, _}) => true
  | _ => false
  };

let exists = (path) =>
  switch (maybeStat(path)) {
  | None => false
  | Some(_) => true
  };

let rec mkdirp = dest =>
  if (!exists(dest)) {
    let parent = Filename.dirname(dest);
    mkdirp(parent);
    Unix.mkdir(dest, 0o740);
  };

let toSafePackageName = packageName =>
  packageName
  |> replace(~find="-", ~replaceWith="_")
  |> replace(~find=".", ~replaceWith="_");
