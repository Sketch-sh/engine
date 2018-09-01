open Sketch__Types;

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
  | Reason_lexer.Error(_err, loc) => Some(loc)
  | _ => None;

let drainBuffer = bf => {
  let content = Buffer.contents(bf);
  Buffer.clear(bf);
  content;
};

let rec last = (head, tail) =>
  switch (tail) {
  | [] => head
  | [head, ...tail] => last(head, tail)
  };

let buffer = Buffer.create(100);
let stdout_buffer = Buffer.create(100);
let stderr_buffer = Buffer.create(100);

let formatter = Format.formatter_of_buffer(buffer);
/* The generic rule is that it is better to always update max_indent
 * after increasing the margin
 * default value for max_indent is margin - 10
 */
Format.pp_set_margin(formatter, 80);
Format.pp_set_max_indent(formatter, 70);

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

let parse_use_file = lexbuf =>
  try (Ok(Toploop.parse_use_file^(lexbuf))) {
  | exn => Error(exn)
  };

let mod_use_file = name =>
  try (Ok(Toploop.mod_use_file(formatter, name))) {
  | exn => Error(exn)
  };

let mod_use_file = name => {
  Buffer.clear(buffer);
  switch (mod_use_file(name)) {
  | Ok(true) => Ok()
  | Ok(false) => Error(Buffer.contents(buffer))
  | Error(exn) =>
    Errors.report_error(formatter, exn);
    Error(Buffer.contents(buffer));
  };
};

let eval = code => {
  /* Clean up all buffers before executing new block */
  Buffer.clear(buffer);
  Buffer.clear(stderr_buffer);
  Buffer.clear(stdout_buffer);

  let lexbuf = Lexing.from_string(code);
  /* Init location reporting */
  Location.input_lexbuf := Some(lexbuf);

  switch (parse_use_file(lexbuf)) {
  | Error(exn) => [
      {
        Errors.report_error(Format.err_formatter, exn);
        switch (get_error_loc(exn)) {
        | None => Error(report())
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
          | Parsetree.Ptop_def([]) => None
          | Parsetree.Ptop_def([item, ...items]) =>
            let loc = {
              Location.loc_start: item.pstr_loc.Location.loc_start,
              Location.loc_end: last(item, items).pstr_loc.Location.loc_end,
              Location.loc_ghost: false,
            };
            Some(loc);
          | Ptop_dir(_name, _argument) => None
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
          let value = drainBuffer(buffer);
          let stdout_output = drainBuffer(stdout_buffer);

          let outMessages =
            if (value == "" && stdout_output == "") {
              out_messages;
            } else {
              [
                Ok(report(~loc?, ~value, ~stdout=stdout_output, ())),
                ...out_messages,
              ];
            };
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
            | None => Error(report(~loc?, ()))
            | Some(parsedLoc) => Error(report(~loc=parsedLoc, ()))
            };
          [newMessage, ...out_messages];
        };
      };

    List.rev(run([], phrases));
  };
};
