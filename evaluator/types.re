let js_of_position = pos => [%js
  {val line = pos.Lexing.pos_lnum; val col = pos.pos_cnum - pos.pos_bol}
];

let js_of_location = ({Location.loc_start, loc_end, loc_ghost: _}) =>
  Js.array([|js_of_position(loc_start), js_of_position(loc_end)|]);

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

type execResult = result(execContent, execContent);

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
