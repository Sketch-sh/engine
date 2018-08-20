module Sketch__ToploopBackup = struct
  let parse_toplevel_phrase = !Sketch__Toploop.parse_toplevel_phrase
  let parse_use_file = !Sketch__Toploop.parse_use_file
  let print_out_value = !Sketch__Toploop.print_out_value
  let print_out_type = !Sketch__Toploop.print_out_type
  let print_out_class_type = !Sketch__Toploop.print_out_class_type
  let print_out_module_type = !Sketch__Toploop.print_out_module_type
  let print_out_type_extension = !Sketch__Toploop.print_out_type_extension
  let print_out_sig_item = !Sketch__Toploop.print_out_sig_item
  let print_out_signature = !Sketch__Toploop.print_out_signature
  let print_out_phrase = !Sketch__Toploop.print_out_phrase
end

let mlSyntax () = begin 
  Sketch__Toploop.parse_toplevel_phrase := Sketch__ToploopBackup.parse_toplevel_phrase;
  Sketch__Toploop.parse_use_file := Sketch__ToploopBackup.parse_use_file;
  Sketch__Toploop.print_out_value := Sketch__ToploopBackup.print_out_value;
  Sketch__Toploop.print_out_type := Sketch__ToploopBackup.print_out_type;
  Sketch__Toploop.print_out_class_type := Sketch__ToploopBackup.print_out_class_type;
  Sketch__Toploop.print_out_module_type := Sketch__ToploopBackup.print_out_module_type;
  Sketch__Toploop.print_out_type_extension := Sketch__ToploopBackup.print_out_type_extension;
  Sketch__Toploop.print_out_sig_item := Sketch__ToploopBackup.print_out_sig_item;
  Sketch__Toploop.print_out_signature := Sketch__ToploopBackup.print_out_signature;
  Sketch__Toploop.print_out_phrase := Sketch__ToploopBackup.print_out_phrase
end

let reasonSyntax () = begin 
  let open Reason_toolchain.From_current in
  let wrap f g fmt x = g fmt (f x) in
  Sketch__Toploop.parse_toplevel_phrase := Reason_util.correctly_catch_parse_errors
        (fun x -> Reason_toolchain.To_current.copy_toplevel_phrase
            (Reason_toolchain.RE.toplevel_phrase x));
  Sketch__Toploop.parse_use_file := Reason_util.correctly_catch_parse_errors
    (fun x -> List.map Reason_toolchain.To_current.copy_toplevel_phrase
        (Reason_toolchain.RE.use_file x));
  Sketch__Toploop.print_out_value :=
    wrap copy_out_value Reason_oprint.print_out_value;
  Sketch__Toploop.print_out_type :=
    wrap copy_out_type Reason_oprint.print_out_type;
  Sketch__Toploop.print_out_class_type :=
    wrap copy_out_class_type Reason_oprint.print_out_class_type;
  Sketch__Toploop.print_out_module_type :=
    wrap copy_out_module_type Reason_oprint.print_out_module_type;
  Sketch__Toploop.print_out_type_extension :=
    wrap copy_out_type_extension Reason_oprint.print_out_type_extension;
  Sketch__Toploop.print_out_sig_item :=
    wrap copy_out_sig_item Reason_oprint.print_out_sig_item;
  Sketch__Toploop.print_out_signature :=
    wrap (List.map copy_out_sig_item) Reason_oprint.print_out_signature;
  Sketch__Toploop.print_out_phrase :=
    wrap copy_out_phrase Reason_oprint.print_out_phrase;
end

open Js_of_ocaml
open Js_of_ocaml_compiler
let split_primitives p =
  let len = String.length p in
  let rec split beg cur =
    if cur >= len then []
    else if p.[cur] = '\000' then
      String.sub p beg (cur - beg) :: split (cur + 1) (cur + 1)
    else
      split beg (cur + 1) in
  Array.of_list(split 0 0)
  
let setup = lazy (
  Hashtbl.add Sketch__Toploop.directive_table "enable" (Sketch__Toploop.Directive_string Option.Optim.enable);
  Hashtbl.add Sketch__Toploop.directive_table "disable" (Sketch__Toploop.Directive_string Option.Optim.disable);
  Hashtbl.add Sketch__Toploop.directive_table "debug_on" (Sketch__Toploop.Directive_string Option.Debug.enable);
  Hashtbl.add Sketch__Toploop.directive_table "debug_off" (Sketch__Toploop.Directive_string Option.Debug.disable);
  Hashtbl.add Sketch__Toploop.directive_table "tailcall" (Sketch__Toploop.Directive_string (Option.Param.set "tc"));
  Topdirs.dir_directory "/static/cmis";
  let initial_primitive_count =
    Array.length (split_primitives (Symtable.data_primitive_names ())) in

  let compile s =
    let prims =
      split_primitives (Symtable.data_primitive_names ()) in
    let unbound_primitive p =
      try ignore (Js.Unsafe.eval_string p); false with _ -> true in
    let stubs = ref [] in
    Array.iteri
      (fun i p ->
         if i >= initial_primitive_count && unbound_primitive p then
           stubs :=
             Format.sprintf
               "function %s(){caml_failwith(\"%s not implemented\")}" p p
             :: !stubs)
      prims;
    let output_program = Driver.from_string prims s in
    let b = Buffer.create 100 in
    output_program (Pretty_print.to_buffer b);
    Format.(pp_print_flush std_formatter ());
    Format.(pp_print_flush err_formatter ());
    flush stdout; flush stderr;
    let res = Buffer.contents b in
    let res = String.concat "" !stubs ^ res in
    Js.Unsafe.global##toplevelEval res
  in
  Js.Unsafe.global##.toplevelCompile := compile (*XXX HACK!*);
  Js.Unsafe.global##.toplevelEval := (fun x ->
    let f : < .. > Js.t -> unit = Js.Unsafe.eval_string x in
    (fun () -> f Js.Unsafe.global)
  );
  ())

let setup () =
  Sys.interactive := false;
  Lazy.force setup;
  Toploop.initialize_toplevel_env ();
  Toploop.input_name := "//toplevel//";
  Sys.interactive := true

let execute code =
  code 
  |> Js.to_string
  |> Execute.eval 
  |> List.map Sketch__Types.js_of_execResult 
  |> Array.of_list 
  |> Js.array


let () = begin
  setup ();
  reasonSyntax ();

  Js.export "evaluator" (
    object%js
      val execute = execute
      val reset = setup
      val reasonSyntax = reasonSyntax
      val mlSyntax = mlSyntax
    end);
end
