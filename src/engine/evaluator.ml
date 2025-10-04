open Js_of_ocaml
open Js_of_ocaml_toplevel


(* External for wrapping OCaml functions for JavaScript calls in OCaml 5 *)
external fun_to_js: int -> ('a -> 'b) -> < .. > Js.t = "caml_js_wrap_callback_strict"

module Reason_toolchain = Reason.Reason_toolchain
module Reason_oprint = Reason.Reason_oprint

module ToploopOCaml = struct
  (* Use your original working approach - Reason toolchain ML parser with effects compatibility *)
  let parse_toplevel_phrase lexbuf = 
    Reason_toolchain.To_current.copy_toplevel_phrase 
      (Reason_toolchain.ML.toplevel_phrase lexbuf)
  let parse_use_file lexbuf = 
    List.map Reason_toolchain.To_current.copy_toplevel_phrase
      (Reason_toolchain.ML.use_file lexbuf)
  let print_out_value = !Oprint.out_value
  let print_out_type = !Oprint.out_type
  let print_out_class_type = !Oprint.out_class_type
  let print_out_module_type = !Oprint.out_module_type
  let print_out_type_extension = !Oprint.out_type_extension
  let print_out_sig_item = !Oprint.out_sig_item
  let print_out_signature = !Oprint.out_signature
  let print_out_phrase = !Oprint.out_phrase
end

let mlSyntax () =
  Toploop.parse_toplevel_phrase := ToploopOCaml.parse_toplevel_phrase;
  Toploop.parse_use_file := ToploopOCaml.parse_use_file;
  Toploop.print_out_value := ToploopOCaml.print_out_value;
  Toploop.print_out_type := ToploopOCaml.print_out_type;
  Toploop.print_out_class_type := ToploopOCaml.print_out_class_type;
  Toploop.print_out_module_type := ToploopOCaml.print_out_module_type;
  Toploop.print_out_type_extension := ToploopOCaml.print_out_type_extension;
  Toploop.print_out_sig_item := ToploopOCaml.print_out_sig_item;
  Toploop.print_out_signature := ToploopOCaml.print_out_signature;
  Toploop.print_out_phrase := ToploopOCaml.print_out_phrase

let reasonSyntax () =
  let open Reason_toolchain.From_current in
  let wrap f g fmt x = g fmt (f x) in
  Toploop.parse_toplevel_phrase := Reason_util.correctly_catch_parse_errors
        (fun x -> 
          Reason_toolchain.To_current.copy_toplevel_phrase
            (Reason_toolchain.RE.toplevel_phrase x));
  Toploop.parse_use_file := Reason_util.correctly_catch_parse_errors
    (fun x -> 
      List.map Reason_toolchain.To_current.copy_toplevel_phrase
        (Reason_toolchain.RE.use_file x));
  Toploop.print_out_value :=
    wrap copy_out_value (Reason_oprint.print_out_value);
  Toploop.print_out_type :=
    wrap copy_out_type (Format_doc.deprecated Reason_oprint.print_out_type);
  Toploop.print_out_class_type :=
    wrap copy_out_class_type (Format_doc.deprecated Reason_oprint.print_out_class_type);
  Toploop.print_out_module_type :=
    wrap copy_out_module_type (Format_doc.deprecated Reason_oprint.print_out_module_type);
  Toploop.print_out_type_extension :=
    wrap copy_out_type_extension (Format_doc.deprecated Reason_oprint.print_out_type_extension);
  Toploop.print_out_sig_item :=
    wrap copy_out_sig_item (Format_doc.deprecated Reason_oprint.print_out_sig_item);
  Toploop.print_out_signature :=
    wrap (List.map copy_out_sig_item) (Format_doc.deprecated Reason_oprint.print_out_signature);
  Toploop.print_out_phrase :=
    wrap copy_out_phrase (Reason_oprint.print_out_phrase)

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

let setup () = 
  JsooTop.initialize ()

let insertModule moduleName content lang = 
  begin 
    let result = try  
      let moduleName = Js.to_string moduleName in
      let content = Js.to_string content in
      let lang_string = Js.to_string lang in
      let lang = stringToLang lang_string in 
      begin 
        match lang with 
        | ML -> 
          mlSyntax()
        | RE -> 
          reasonSyntax()
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
      val execute = fun_to_js 1 execute
      val reset = fun_to_js 1 setup
      val reasonSyntax = fun_to_js 1 reasonSyntax
      val mlSyntax = fun_to_js 1 mlSyntax
      val insertModule = fun_to_js 3 insertModule
    end);

  Js.export "refmt" RefmtJsApi.api
end
