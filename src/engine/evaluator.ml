open Js_of_ocaml
open Js_of_ocaml_toplevel

(* External for wrapping OCaml functions for JavaScript calls in OCaml 5 *)
external fun_to_js: int -> ('a -> 'b) -> < .. > Js.t = "caml_js_wrap_callback_strict"

module Reason_toolchain = Reason.Reason_toolchain
module Reason_oprint = Reason.Reason_oprint

module ToploopBackup = struct
  (* Use the original OCaml functions directly, as defined in topcommon.ml *)
  let parse_toplevel_phrase = fun lexbuf -> 
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] ToploopBackup.parse_toplevel_phrase called") in
    try
      let result = Reason_toolchain.To_current.copy_toplevel_phrase 
        (Reason_toolchain.ML.toplevel_phrase lexbuf) in
      let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] ToploopBackup.parse_toplevel_phrase succeeded") in
      result
    with
    | exn -> 
      let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] ToploopBackup.parse_toplevel_phrase failed: " ^ (Printexc.to_string exn))) in
      raise exn
  let parse_use_file = fun lexbuf ->
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] ToploopBackup.parse_use_file called") in
    try
      let result = List.map Reason_toolchain.To_current.copy_toplevel_phrase 
        (Reason_toolchain.ML.use_file lexbuf) in
      let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] ToploopBackup.parse_use_file succeeded with " ^ (string_of_int (List.length result)) ^ " phrases")) in
      result
    with
    | exn ->
      let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] ToploopBackup.parse_use_file failed: " ^ (Printexc.to_string exn))) in
      raise exn
  let print_out_value = !Oprint.out_value
  let print_out_type = !Oprint.out_type
  let print_out_class_type = !Oprint.out_class_type
  let print_out_module_type = !Oprint.out_module_type
  let print_out_type_extension = !Oprint.out_type_extension
  let print_out_sig_item = !Oprint.out_sig_item
  let print_out_signature = !Oprint.out_signature
  let print_out_phrase = !Oprint.out_phrase
end

let mlSyntax () = begin 
  let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] mlSyntax() ENTRY - function called") in
  try
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] mlSyntax() called - switching to ML syntax") in
    Toploop.parse_toplevel_phrase := ToploopBackup.parse_toplevel_phrase;
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] mlSyntax() setting Toploop.parse_use_file to ML parser") in
    Toploop.parse_use_file := ToploopBackup.parse_use_file;
  Toploop.print_out_value := ToploopBackup.print_out_value;
  Toploop.print_out_type := ToploopBackup.print_out_type;
  Toploop.print_out_class_type := ToploopBackup.print_out_class_type;
  Toploop.print_out_module_type := ToploopBackup.print_out_module_type;
  Toploop.print_out_type_extension := ToploopBackup.print_out_type_extension;
  Toploop.print_out_sig_item := ToploopBackup.print_out_sig_item;
  Toploop.print_out_signature := ToploopBackup.print_out_signature;
  Toploop.print_out_phrase := ToploopBackup.print_out_phrase;
  let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] mlSyntax() completed successfully") in
  ()
  with
  | exn -> 
    let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] mlSyntax() failed with exception: " ^ (Printexc.to_string exn))) in
    ()
end

let reasonSyntax () = 
  let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] reasonSyntax() ENTRY - function called") in
  try
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] reasonSyntax() called - switching to Reason syntax") in
    let open Reason_toolchain.From_current in
    let wrap f g fmt x = g fmt (f x) in
    Toploop.parse_toplevel_phrase := Reason_util.correctly_catch_parse_errors
          (fun x -> Reason_toolchain.To_current.copy_toplevel_phrase
              (Reason_toolchain.RE.toplevel_phrase x));
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] reasonSyntax() setting Toploop.parse_use_file to Reason parser") in
    Toploop.parse_use_file := Reason_util.correctly_catch_parse_errors
      (fun x -> 
        let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] Reason parser called via Toploop.parse_use_file") in
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
      wrap copy_out_phrase (Reason_oprint.print_out_phrase);
    let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] reasonSyntax() completed successfully") in
    ()
  with
  | exn -> 
    let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] reasonSyntax() failed with exception: " ^ (Printexc.to_string exn))) in
    ()

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
  let () = Js.Unsafe.global##.console##log (Js.string "[DEBUG] setup() called - calling JsooTop.initialize()") in
  JsooTop.initialize ()

let insertModule moduleName content lang = 
  begin 
    let result = try  
      let moduleName = Js.to_string moduleName in
      let content = Js.to_string content in
      let lang_string = Js.to_string lang in
      let lang = stringToLang lang_string in 
      let () = Js.Unsafe.global##.console##log (Js.string ("[DEBUG] insertModule: lang string = " ^ lang_string ^ ", parsed lang = " ^ (match lang with ML -> "ML" | RE -> "RE"))) in
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
      val execute = fun_to_js 1 execute
      val reset = fun_to_js 0 setup
      val reasonSyntax = reasonSyntax
      val mlSyntax = mlSyntax
      val insertModule = fun_to_js 3 insertModule
    end);

  Js.export "refmt" RefmtJsApi.api
end
