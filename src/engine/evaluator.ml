open Js_of_ocaml
open Js_of_ocaml_toplevel

module ToploopBackup = struct
  let parse_toplevel_phrase = !Toploop.parse_toplevel_phrase
  let parse_use_file = !Toploop.parse_use_file
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
  Toploop.parse_use_file := ToploopBackup.parse_use_file;
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
  Toploop.parse_use_file := Reason_util.correctly_catch_parse_errors
    (fun x -> List.map Reason_toolchain.To_current.copy_toplevel_phrase
        (Reason_toolchain.RE.use_file x));
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

type lang = RE | ML

let stringToLang = 
  function
  | "ml" | "ocaml" -> ML
  | "re" | "reason"
  | _ -> RE

let langToExtension = 
  function 
  | RE -> "re"
  | ML -> "ml"

let moduleToFileName moduleName lang =
  "/static/" ^ (String.capitalize_ascii moduleName) ^ "." ^ (langToExtension lang)

let setup () = JsooTop.initialize ()

let insertModule moduleName content lang = 
  begin 
    let result = try  
      let moduleName = Js.to_string moduleName in
      let content = Js.to_string content in
      let lang = Js.to_string lang in
      let lang = stringToLang lang in 
      begin 
        match lang with 
        | ML -> mlSyntax()
        | RE -> reasonSyntax()
      end;

      let fileName = moduleToFileName moduleName lang in
      let _ = File__System.createOrUpdateFile fileName content in
      Execute.mod_use_file fileName
    with
      | exn -> 
        let buffer = Buffer.create 100 in
        let formatter = Format.formatter_of_buffer buffer in 
        Errors.report_error formatter exn;
        let error_message = Buffer.contents buffer in 
        Error(error_message) in
    match result with 
    | Ok(_) -> 
      object%js 
        val kind = Js.string "Ok"
        val value = Js.string "unit"
      end
    | Error(message) -> 
      object%js 
        val kind = Js.string "Error"
        val value = Js.string message
      end
  end

let execute code =
  code 
  |> Js.to_string
  |> Execute.eval 
  |> List.map Execute.toString
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
      val insertModule = insertModule
    end);

  Js.export "refmt" RefmtJsApi.api
end
