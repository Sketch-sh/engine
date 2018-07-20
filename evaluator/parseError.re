let parseFromRtop = (~customErrorParsers, ~content: string, ~error as err) => {
  open Refmterr.BetterErrorsTypes;
  open Refmterr.Helpers;
  open Refmterr.Index;

  /* we know whatever err is, it starts with "File: ..." because that's how `parse`
     is used */
  let err = String.trim(err);
  
  switch (Re.Pcre.full_split(~rex=fileR, err)) {
  | [Re.Pcre.Delim(_), Group(_, filePath), Group(_, lineNum), col1, col2, Text(body)] =>
    /* important, otherwise leaves random blank lines that defies some of
       our regex logic, maybe */
    let body = String.trim(body);
    let errorCapture = get_match_maybe({|^Error: ([\s\S]+)|}, body);

    let cachedContent = String.split_on_char('\n', content);
    /* sometimes there's only line, but no characters */
    let (col1Raw, col2Raw) =
      switch (col1, col2) {
      | (Group(_, c1), Group(_, c2)) =>
        /* bug: https://github.com/mmottl/pcre-ocaml/issues/5 */
        if (String.trim(c1) == "" || String.trim(c2) == "") {
          raise(Invalid_argument("HUHUHUH"));
        } else {
          (Some(c1), Some(c2));
        }
      | _ => (None, None)
      };
    let range =
      normalizeCompilerLineColsToRange(
        ~fileLines=cachedContent,
        ~lineRaw=lineNum,
        ~col1Raw,
        ~col2Raw,
      );
    let warningCapture =
      switch (execMaybe({|^Warning (\d+): ([\s\S]+)|}, body)) {
      | None => (None, None)
      | Some(capture) => (getSubstringMaybe(capture, 1), getSubstringMaybe(capture, 2))
      };
    switch (errorCapture, warningCapture) {
    | (Some(errorBody), (None, None)) =>
      ErrorContent({
        filePath,
        cachedContent,
        range,
        parsedContent: Refmterr.ParseError.parse(~customErrorParsers, ~errorBody, ~cachedContent, ~range),
      })
    | (None, (Some(code), Some(warningBody))) =>
      let code = int_of_string(code);
      Warning({
        filePath,
        cachedContent,
        range,
        parsedContent: {
          code,
          warningType: Refmterr.ParseWarning.parse(code, warningBody, filePath, cachedContent, range),
        },
      });
    | _ => raise(Invalid_argument(err))
    };
  /* not an error, not a warning. False alarm? */
  | _ => Unparsable
  };
};

let parse = (content, error) => {
  let content = Js.to_string(content);
  let error = Js.to_string(error);
  parseFromRtop(
    ~customErrorParsers=[],
    ~content,
    ~error,
  )
};
