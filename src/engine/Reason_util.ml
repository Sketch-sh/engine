(**
 * Some of this was coppied from @whitequark's m17n project.
 *)
(*
 * Portions Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

let correctly_catch_parse_errors fn lexbuf =
  fn lexbuf
