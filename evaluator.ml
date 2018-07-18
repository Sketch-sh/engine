(* evaluator.ml *)

let () =
begin
  JsooTop.initialize ();
  let open Reason_toolchain.From_current in
  let wrap f g fmt x = g fmt (f x) in
  Toploop.parse_toplevel_phrase := Reason_util.correctly_catch_parse_errors
        (fun x -> Reason_toolchain.To_current.copy_toplevel_phrase
            (Reason_toolchain.RE.toplevel_phrase x));
  Toploop.print_out_value :=
    wrap copy_out_value Reason_oprint.print_out_value;
  Toploop.print_out_type :=
    wrap copy_out_type Reason_oprint.print_out_type;
  Toploop.print_out_class_type :=
    wrap copy_out_class_type Reason_oprint.print_out_class_type;
  Toploop.print_out_module_type :=
    wrap copy_out_module_type Reason_oprint.print_out_module_type;
  Toploop.print_out_type_extension :=
    wrap copy_out_type_extension Reason_oprint.print_out_type_extension;
  Toploop.print_out_sig_item :=
    wrap copy_out_sig_item Reason_oprint.print_out_sig_item;
  Toploop.print_out_signature :=
    wrap (List.map copy_out_sig_item) Reason_oprint.print_out_signature;
  Toploop.print_out_phrase :=
    wrap copy_out_phrase Reason_oprint.print_out_phrase;
end 

let execute code =
  let code = Js.to_string code in
  let buffer = Buffer.create 100 in
  let formatter = Format.formatter_of_buffer buffer in
  JsooTop.execute true formatter code;
  Js.string (Buffer.contents buffer)

let () =
  Js.export "evaluator" (
    object%js
      val execute = execute
    end)
