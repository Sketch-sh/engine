let load_cmos = () => {
  try ({
    let all_cmos = Array.to_list(Sys.readdir("/static/"));
    let all_cmos = List.filter(f => !Sys.is_directory(f), all_cmos);
    List.iter(Topdirs.dir_load(Format.std_formatter), all_cmos);
  }) {
  | exn => Firebug.console##log_2 (
   Js.string("Exn: "), 
   Js.string (Printexc.to_string (exn))
  );
  }
};
