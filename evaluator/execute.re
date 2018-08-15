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

let js_of_location = ({loc_start, loc_end}) =>
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
let get_error_loc =
  fun
  | Syntaxerr.Error(x) => Some(Syntaxerr.location_of_error(x))
  | Lexer.Error(_, loc)
  | Typecore.Error(loc, _, _)
  | Typetexp.Error(loc, _, _)
  | Typeclass.Error(loc, _, _)
  | Typemod.Error(loc, _, _)
  | Typedecl.Error(loc, _)
  | Translcore.Error(loc, _)
  | Translclass.Error(loc, _)
  | Translmod.Error(loc, _) => Some(loc)
  | Reason_syntax_util.Error(loc, _) => Some(loc)
  | _ => None;

let drainBuffer = bf => {
  let content = Buffer.contents(bf);
  Buffer.clear(bf);
  content;
};

let buffer = Buffer.create(100);
let stdout_buffer = Buffer.create(100);
let stderr_buffer = Buffer.create(100);

let formatter = Format.formatter_of_buffer(buffer);
Format.pp_set_margin(formatter, 80);

Sys_js.set_channel_flusher(stdout, Buffer.add_string(stdout_buffer));
Sys_js.set_channel_flusher(stderr, Buffer.add_string(stderr_buffer));

let report = (~loc: option(Location.t)=?, ~value=?, ~stdout=?, ~stderr=?, ()) => {
  loc,
  value:
    switch (value) {
    | None => buffer |> drainBuffer
    | Some(content) => content
    },
  stdout:
    switch (stdout) {
    | None => stdout_buffer |> drainBuffer
    | Some(content) => content
    },
  stderr:
    switch (stderr) {
    | None => stderr_buffer |> drainBuffer
    | Some(err) => err
    },
};

let eval = code => {
  /* Clean up all buffers before executing new block */
  Buffer.clear(buffer);
  Buffer.clear(stderr_buffer);
  Buffer.clear(stdout_buffer);

  let lexbuf = Lexing.from_string(code);
  /* Init location reporting */
  Location.input_lexbuf := Some(lexbuf);

  switch (
    try (Ok(Toploop.parse_use_file^(lexbuf))) {
    | x => Error(x)
    }
  ) {
  | Error(exn) => [
      {
        Errors.report_error(Format.err_formatter, exn);
        switch (get_error_loc(exn)) {
        | None => Error(report(~stderr="Unknown error", ()))
        | Some(loc) => Error(report(~loc, ()))
        };
      },
    ]
  | Ok(phrases) =>
    /* build a list of return messages (until there is an error) */
    let rec run = (out_messages, phrases) =>
      switch (phrases) {
      | [] => out_messages
      | [phrase, ...phrases] =>
        let loc =
          switch (phrase) {
          | Parsetree.Ptop_def(structure) =>
            Some(
              structure
              |> List.map(structure_item => structure_item.Parsetree.pstr_loc)
              |> List.hd,
            )
          | Ptop_dir(name, _argument) => None
          };

        Buffer.clear(buffer);
        Buffer.clear(stderr_buffer);
        Buffer.clear(stdout_buffer);

        switch (
          try (Ok(Toploop.execute_phrase(true, formatter, phrase))) {
          | exn => Error(exn)
          }
        ) {
        | Ok(true) =>
          let outMessages = [Ok(report(~loc?, ())), ...out_messages];
          run(outMessages, phrases);
        | Ok(false) => [Error(report(~loc?, ())), ...out_messages]
        | Error(Sys.Break) => [
            Error(report(~loc?, ~stderr="Interupted", ())),
            ...out_messages,
          ]
        | Error(exn) =>
          Errors.report_error(Format.err_formatter, exn);
          let newMessage =
            switch (get_error_loc(exn)) {
            | None => Error(report(~loc?, ~stderr="Unknown error", ()))
            | Some(parsedLoc) => Error(report(~loc=parsedLoc, ()))
            };
          [newMessage, ...out_messages];
        };
      };

    List.rev(run([], phrases));
  };
};
