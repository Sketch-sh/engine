let createOrUpdateFile name content = 
  try
    let _ = Sys_js.read_file ~name in
    Sys_js.update_file ~name ~content
  with
    Sys_error(_msg) -> 
      Sys_js.create_file ~name ~content
