const { evaluator: e } = require("../evaluator/_build/default/evaluator.js");
const objPath = require("object-path");

test("mod_use valid file", () => {
  e.reset();
  let insertModule = e.insertModule(
    "awesome",
    `let x = 1; let y = 2; let z = 3;`,
    "re"
  );

  expect(objPath.get(insertModule, "kind")).toBe("Ok");

  let result = e
    .execute("let x = Awesome.x; let y = Awesome.y; let z = Awesome.z;")
    .map(phr => objPath.get(phr, "value.value"))
    .map(str => str.trim());

  expect(result).toEqual([
    "let x: int = 1;",
    "let y: int = 2;",
    "let z: int = 3;",
  ]);
});

test("mod_use valid file ml syntax", () => {
  e.reset();
  let insertModule = e.insertModule(
    "awesome",
    `let x = 1;; let y = 2;; let z = 3;;`,
    "ml"
  );

  expect(objPath.get(insertModule, "kind")).toBe("Ok");

  e.reasonSyntax();

  let result = e
    .execute("let x = Awesome.x; let y = Awesome.y; let z = Awesome.z;")
    .map(phr => objPath.get(phr, "value.value"))
    .map(str => str.trim());

  expect(result).toEqual([
    "let x: int = 1;",
    "let y: int = 2;",
    "let z: int = 3;",
  ]);
});

test("mod_use with syntax error", () => {
  e.reset();
  let insertModule = e.insertModule("syntax_error", `let x = () =>;`, "re");

  expect(objPath.get(insertModule, "kind")).toBe("Error");
  expect(objPath.get(insertModule, "value").trim()).toMatchInlineSnapshot(`
"File \\"/static/Syntax_error.re\\", line 1, characters 13-14:
Error: 1160: <syntax error>"
`);
});

test("mod_use with type error", () => {
  e.reset();
  let insertModule = e.insertModule("type_error", `let x: string = 1`, "re");

  expect(objPath.get(insertModule, "kind")).toBe("Error");
  expect(objPath.get(insertModule, "value").trim()).toMatchInlineSnapshot(`
"File \\"/static/Type_error.re\\", line 1, characters 16-17:
Error: This expression has type int but an expression was expected of type
         string"
`);
});
