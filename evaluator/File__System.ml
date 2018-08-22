let createOrUpdateFile name content = 
  let name = name ^ ".re" in
  try
    let _ = Sys_js.read_file name in
    Sys_js.update_file ~name ~content
  with
    Sys_error(msg) -> 
      Sys_js.create_file ~name ~content
