let parse = (content, error) => {
  let content = content |> Js.to_string;
  let error = error |> Js.to_string;

  let parseResult = RtopParser.parse(
    ~customErrorParsers=[],
    ~content,
    ~error,
  );

  let originalRevLines = Refmterr.Helpers.splitOnChar('\n', error) |> List.rev;
  
  let html = RtopReporter.prettyPrintParsedResult(~originalRevLines, ~refmttypePath=None, parseResult)
  |> List.rev
  |> Stylish.concatList("");

  html |> Js.string;
};
