let sp = Printf.sprintf;

  let concatList = (connector, list) =>
    list
    |> List.rev
    |> List.fold_left(
         (line, acc) =>
           line |> String.trim == "" ? acc : acc ++ connector ++ "<p>" ++ line ++ "</p>",
         "",
       );

  let dim = sp({|<span class="dim">%s</span>|});
  let underline = sp({|<span class="underline">%s</span>|});
  let bold = sp({|<span class="bold">%s</span>|});

  /* TODO: invert modifier is not possbile in HTML */
  let invert = sp("<span>%s</span>");

  let makeColor = (~underline=false, ~invert=false, ~dim=false, ~bold=false, ~className, s) => {
    let className =
      ref(
        switch (className) {
        | None => []
        | Some(c) => [invert ? "bg-" ++ c : c]
        },
      );
    if (underline) {
      className := ["underline", ...className^];
    };
    if (dim) {
      className := [invert ? "bg-dim" : "dim", ...className^];
    };
    if (bold) {
      className := ["bold", ...className^];
    };

    sp({|<span class="%s">%s</span>|}, className^ |> String.concat(" "), s);
  };

  let normal = makeColor(~className=None);

  let red = makeColor(~className=Some("red"));

  let yellow = makeColor(~className=Some("yello"));

  let blue = makeColor(~className=Some("blue"));

  let green = makeColor(~className=Some("green"));

  let cyan = makeColor(~className=Some("cyan"));

  let purple = makeColor(~className=Some("purple"));

  let stringSlice = (~first=0, ~last=?, str) => {
    let last =
      switch (last) {
      | Some(l) => min(l, String.length(str))
      | None => String.length(str)
      };
    if (last <= first) {
      "";
    } else {
      String.sub(str, first, last - first);
    };
  };

  let highlight =
      (
        ~underline=false,
        ~invert=false,
        ~dim=false,
        ~bold=false,
        ~color=normal,
        ~first=0,
        ~last=99999,
        str,
      ) =>
    stringSlice(~last=first, str)
    ++ color(~underline, ~dim, ~invert, ~bold, stringSlice(~first, ~last, str))
    ++ stringSlice(~first=last, str);
