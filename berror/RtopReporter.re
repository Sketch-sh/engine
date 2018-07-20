module HtmlReporter = Refmterr.Reporter.Make(Stylish);
module ReportWarning = Refmterr.ReportWarning.Make(Stylish);
module ReportError = Refmterr.ReportError.Make(Stylish);
module Reporter = Refmterr.Reporter.Make(Stylish);

open Refmterr.BetterErrorsTypes;
open Refmterr.Helpers;
open Stylish;

let prettyPrintParsedResult =
      (~originalRevLines: list(string), ~refmttypePath, result: result)
      : list(string) =>
    switch (result) {
    | Unparsable => originalRevLines
    /* output the line without any decoration around. We previously had some
       cute little ascii red x mark to say "we couldn't parse this but there's
       probably an error". But it's very possible that this line's a continuation
       of a previous error, just that we couldn't parse it. So we try to bolt this
       line right after our supposedly parsed and pretty-printed error to make them
       look like one printed error. */
    /* the effing length we'd go for better errors... someone gimme a cookie */
    | ErrorFile(NonexistentFile) =>
      /* this case is never reached because we don't ever return `ErrorFile NonexistentFile` from
         `ParseError.specialParserThatChecksWhetherFileEvenExists` */
      originalRevLines
    | ErrorFile(Stdin(original)) => [
        sp("%s (from stdin - see message above)", red(~bold=true, "Error:")),
        original,
      ]
    | ErrorFile(CommandLine(moduleName)) => [
        "",
        sp(
          "%s module %s not found.",
          red(~bold=true, "Error:"),
          red(~underline=true, ~bold=true, moduleName),
        ),
        ...originalRevLines,
      ]
    | ErrorFile(NoneFile(filename)) =>
      /* TODO: test case for this. Forgot how to repro it */
      if (Filename.check_suffix(filename, ".cmo")) {
        [
          "Cmo files are artifacts the compiler looks for when compiling/linking dependent files.",
          sp(
            "%s Cannot find file %s.",
            red(~bold=true, "Error:"),
            red(~bold=true, ~underline=true, filename),
          ),
          ...originalRevLines,
        ];
      } else {
        [
          sp(
            "%s Cannot find file %s.",
            red(~bold=true, "Error:"),
            red(~bold=true, filename),
          ),
          ...originalRevLines,
        ];
      }
    | ErrorContent(withFileInfo) =>
      List.concat([
        ["", ""],
        ReportError.report(~refmttypePath, withFileInfo.parsedContent),
        [""],
        Reporter.printFile(withFileInfo),
        [""],
        [""],
        indent(dim("# "), List.map(dim, originalRevLines)),
        [highlight(~dim=true, ~bold=true, "# Unformatted Error Output:")],
      ])
    | Warning(withFileInfo) =>
      List.concat([
        ["", ""],
        ReportWarning.report(
          ~refmttypePath,
          withFileInfo.parsedContent.code,
          withFileInfo.filePath,
          withFileInfo.parsedContent.warningType,
        ),
        [""],
        Reporter.printFile(
          ~isWarningWithCode=withFileInfo.parsedContent.code,
          withFileInfo,
        ),
        [""],
        [""],
        indent(dim("# "), List.map(dim, originalRevLines)),
        [highlight(~dim=true, ~bold=true, "# Unformatted Warning Output:")],
      ])
    };
