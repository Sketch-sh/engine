const { evaluator: e } = require("../evaluator/_build/default/evaluator.js");
const objPath = require("object-path");

test("correct values order when having multiple expressions on the same line", () => {
  let result = e
    .execute("let x = 1; let y = 2; let z = 3;")
    .map(phr => objPath.get(phr, "value.value"))
    .map(str => str.trim());

  expect(result).toEqual([
    "let x: int = 1;",
    "let y: int = 2;",
    "let z: int = 3;",
  ]);
});
