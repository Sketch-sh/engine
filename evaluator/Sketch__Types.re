type position =
  Lexing.position = {
    pos_fname: string,
    pos_lnum: int,
    pos_bol: int,
    pos_cnum: int,
  };

let js_of_position = pos => [%js
  {val line = pos.pos_lnum; val col = pos.pos_cnum - pos.pos_bol}
];
let show_position = pos =>
  Printf.sprintf("(%i, %i)", pos.pos_lnum, pos.pos_cnum - pos.pos_bol);

type location =
  Location.t = {
    loc_start: position,
    loc_end: position,
    loc_ghost: bool,
  };

let js_of_location = ({loc_start, loc_end, loc_ghost: _}) =>
  Js.array([|js_of_position(loc_start), js_of_position(loc_end)|]);

let show_location = location =>
  Printf.sprintf(
    "%s - %s",
    location.loc_start |> show_position,
    location.loc_end |> show_position,
  );

type execContent = {
  loc: option(Location.t),
  value: string,
  stderr: string,
  stdout: string,
};

let js_of_execContent = ({loc, value, stderr, stdout}) => [%js
  {
    val loc = loc |> Utils.Option.map(js_of_location) |> Js.Opt.option;
    val value = Js.string(value);
    val stderr = Js.string(stderr);
    val stdout = Js.string(stdout)
  }
];

let show_execContent = ({loc, value, stderr, stdout}) =>
  Printf.sprintf(
    "{
  loc: %s,
  value: %s,
  stderr: %s,
  stdout: %s,
}",
    switch (loc) {
    | None => "None"
    | Some(loc) => "Some(" ++ show_location(loc) ++ ")"
    },
    value,
    stderr,
    stdout,
  );

type execResult = result(execContent, execContent);

let show_execResult =
  fun
  | Ok(execContent) =>
    Printf.sprintf("Ok: %s", show_execContent(execContent))
  | Error(execContent) =>
    Printf.sprintf("Error: %s", show_execContent(execContent));

let js_of_execResult =
  fun
  | Ok(execContent) => [%js
      {
        val kind = Js.string("Ok");
        val value = js_of_execContent(execContent)
      }
    ]
  | Error(execContent) => [%js
      {
        val kind = Js.string("Error");
        val value = js_of_execContent(execContent)
      }
    ];
