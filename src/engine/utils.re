module Option = {
  let map = (f, opt) =>
    switch (opt) {
    | None => None
    | Some(a) => Some(f(a))
    };
};
