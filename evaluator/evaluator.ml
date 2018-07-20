module ToploopBackup = struct
  let parse_toplevel_phrase = !Toploop.parse_toplevel_phrase
  let print_out_value = !Toploop.print_out_value
  let print_out_type = !Toploop.print_out_type
  let print_out_class_type = !Toploop.print_out_class_type
  let print_out_module_type = !Toploop.print_out_module_type
  let print_out_type_extension = !Toploop.print_out_type_extension
  let print_out_sig_item = !Toploop.print_out_sig_item
  let print_out_signature = !Toploop.print_out_signature
  let print_out_phrase = !Toploop.print_out_phrase
end

let mlSyntax () = begin 
  Toploop.parse_toplevel_phrase := ToploopBackup.parse_toplevel_phrase;
  Toploop.print_out_value := ToploopBackup.print_out_value;
  Toploop.print_out_type := ToploopBackup.print_out_type;
  Toploop.print_out_class_type := ToploopBackup.print_out_class_type;
  Toploop.print_out_module_type := ToploopBackup.print_out_module_type;
  Toploop.print_out_type_extension := ToploopBackup.print_out_type_extension;
  Toploop.print_out_sig_item := ToploopBackup.print_out_sig_item;
  Toploop.print_out_signature := ToploopBackup.print_out_signature;
  Toploop.print_out_phrase := ToploopBackup.print_out_phrase
end

let reasonSyntax () = begin 
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

let setup () = JsooTop.initialize ()
  
let execute code =
  let code = Js.to_string code in
  let evaluate_buffer = Buffer.create 100 in
  let stderr_buffer = Buffer.create 100 in
  let stdout_buffer = Buffer.create 100 in

  Sys_js.set_channel_flusher stderr (Buffer.add_string stderr_buffer);
  Sys_js.set_channel_flusher stdout (Buffer.add_string stdout_buffer);

  let formatter = Format.formatter_of_buffer evaluate_buffer in
  JsooTop.execute true formatter code;
  
  object%js
    val evaluate = Js.string (Buffer.contents evaluate_buffer)
    val stderr = Js.string (Buffer.contents stderr_buffer)
    val stdout = Js.string (Buffer.contents stdout_buffer)
  end

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
