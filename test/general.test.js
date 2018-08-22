
const { evaluator: e } = require("../build/toplevel.js");
const objPath = require("object-path");

test("correct values order when having multiple expressions on the same line", () => {
  console.log(e.execute(`let a = [1,2,3,4,5,6]; a |> List.iter(print_int);`))
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
