let replace = (~find, ~replaceWith) =>
  Str.global_replace(Str.regexp_string(find), replaceWith);

let writeFileSync = (~path, content) => {
  let channel = open_out(path);
  output_string(channel, content);
  close_out(channel);
};

let toSafePackageName = packageName =>
  packageName |> replace(~find="-", ~replaceWith="_");
