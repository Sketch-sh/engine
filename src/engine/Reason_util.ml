(**
 * Some of this was coppied from @whitequark's m17n project.
 *)
(*
 * Portions Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

let transmogrify_exn exn template =
  assert (Obj.tag (Obj.repr exn) = 0);
  Obj.set_field (Obj.repr exn) 0 (Obj.field (Obj.repr template) 0);
  exn

let extract_exn src name =
  try
    ignore (!Toploop.parse_toplevel_phrase (Lexing.from_string src));
    assert false
  with exn ->
    assert (Printexc.exn_slot_name exn = name);
    exn

let exn_Lexer_Error = extract_exn "\128" "Lexer.Error"
let exn_Syntaxerr_Error = extract_exn "fun" "Syntaxerr.Error"

let rec skip_phrase lexbuf =
  try
    match Reason_lexer.token lexbuf with
    | (Reason_parser.SEMI, _, _) | (Reason_parser.EOF, _, _) -> ()
    | _ -> skip_phrase lexbuf
  with
  | Reason_errors.Reason_error (Lexing_error (Unterminated_comment _), _)
  | Reason_errors.Reason_error (Lexing_error (Unterminated_string), _)
  | Reason_errors.Reason_error (Lexing_error (Unterminated_string_in_comment _), _)
  | Reason_errors.Reason_error (Lexing_error (Illegal_character _), _) ->
    skip_phrase lexbuf

let maybe_skip_phrase lexbuf =
  if Parsing.is_current_lookahead Reason_parser.SEMI
  || Parsing.is_current_lookahead Reason_parser.EOF
  then ()
  else skip_phrase lexbuf


let correctly_catch_parse_errors fn lexbuf =
  fn lexbuf