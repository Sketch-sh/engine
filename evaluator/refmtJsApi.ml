(* 
  This file is taken and modified from 
  https://github.com/facebook/reason/blob/9bb16162a68486851069f295bc19d9fb81fca763/bspacks/refmtJsApi.ml
*)

module RE = Reason_toolchain.RE
module ML = Reason_toolchain.ML

let locationToJsObj (loc: Location.t) =
  let (_file, start_line, start_char) = Location.get_pos_info loc.loc_start in
  let (_, end_line, end_char) = Location.get_pos_info loc.loc_end in
  (* The right way of handling ocaml syntax error locations. Do do this at home
    copied over from
    https://github.com/BuckleScript/bucklescript/blob/2ad2310f18567aa13030cdf32adb007d297ee717/jscomp/super_errors/super_location.ml#L73
  *)
  let normalizedRange =
    if start_char == -1 || end_char == -1 then
      (* happens sometimes. Syntax error for example *)
      None
    else if start_line = end_line && start_char >= end_char then
      (* in some errors, starting char and ending char can be the same. But
         since ending char was supposed to be exclusive, here it might end up
         smaller than the starting char if we naively did start_char + 1 to
         just the starting char and forget ending char *)
      let same_char = start_char + 1 in
      Some ((start_line, same_char), (end_line, same_char))
    else
      (* again: end_char is exclusive, so +1-1=0 *)
      Some ((start_line, start_char + 1), (end_line, end_char))
  in
  match normalizedRange with
  | None -> Js.undefined
  | Some ((start_line, start_line_start_char), (end_line, end_line_end_char)) ->
    (*
      Converting from 1-indexed to 0-indexed
      The above logic is so dangerous that I don't even want to touch it
    *)
    let start_line = start_line - 1 in 
    let start_line_start_char = start_line_start_char - 1 in 
    let end_line = end_line - 1 in 
    let end_line_end_char = end_line_end_char - 1 in 

    let intToJsFloatToAny i =
      i |> float_of_int |> Js.number_of_float |> Js.Unsafe.inject
    in
    Js.def (Js.array [|
        Js.Unsafe.obj [|
          ("line", intToJsFloatToAny start_line);
          ("col", intToJsFloatToAny start_line_start_char);
        |],
        Js.Unsafe.obj [|
          ("line", intToJsFloatToAny end_line);
          ("col", intToJsFloatToAny end_line_end_char);
        |]
      |]
    )


let parseWith f code =
  (* you can't throw an Error here. jsoo parses the string and turns it
    into something else *)
  let throwAnything = Js.Unsafe.js_expr "function(a) {throw a}" in
  try
    (code
    |> Js.to_string
    |> Lexing.from_string
    |> f)
  with
  (* from ocaml and reason *)
  | Syntaxerr.Error err ->
    let location = Syntaxerr.location_of_error err in
    let jsLocation = locationToJsObj location in
    Syntaxerr.report_error Format.str_formatter err;
    let errorString = Format.flush_str_formatter () in
    let jsError =
      Js.Unsafe.obj [|
        ("message", Js.Unsafe.inject (Js.string errorString));
        ("location", Js.Unsafe.inject jsLocation);
      |]
    in
    Js.Unsafe.fun_call throwAnything [|Js.Unsafe.inject jsError|]
  (* from reason *)
  | Reason_syntax_util.Error (location, Syntax_error err) ->
    let jsLocation = locationToJsObj location in
    let jsError =
      Js.Unsafe.obj [|
        ("message", Js.Unsafe.inject (Js.string err));
        ("location", Js.Unsafe.inject jsLocation);
      |]
    in
    Js.Unsafe.fun_call throwAnything [|Js.Unsafe.inject jsError|]
  | Reason_lexer.Error (err, loc) ->
    let reportedError =
      Location.error_of_printer loc Reason_lexer.report_error err
    in
    let jsLocation = locationToJsObj reportedError.loc in
    let jsError =
      Js.Unsafe.obj [|
        ("message", Js.Unsafe.inject (Js.string reportedError.msg));
        ("location", Js.Unsafe.inject jsLocation);
      |]
    in
    Js.Unsafe.fun_call throwAnything [|Js.Unsafe.inject jsError|]

let parseRE = parseWith RE.implementation_with_comments
let parseREI = parseWith RE.interface_with_comments
let parseML = parseWith ML.implementation_with_comments
let parseMLI = parseWith ML.interface_with_comments


let printWith f structureAndComments =
  f Format.str_formatter structureAndComments;
  Format.flush_str_formatter () |> Js.string

let printRE = printWith RE.print_implementation_with_comments
let printREI = printWith RE.print_interface_with_comments
let printML = printWith ML.print_implementation_with_comments
let printMLI = printWith ML.print_interface_with_comments

let api = object%js
  val parseRE = parseRE
  val parseREI = parseREI
  val parseML = parseML
  val parseMLI = parseMLI

  val printRE = printRE
  val printREI = printREI
  val printML = printML
  val printMLI = printMLI
end;
