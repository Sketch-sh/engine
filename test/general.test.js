const { evaluator: e } = require("./engine.js");
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

test("directives", () => {
  let result = e.execute(`let a = 1; #show a;`);
  expect(result.length).toBe(2);
  expect(result[1].value.stdout.trim()).toMatchInlineSnapshot(`"let a: int;"`);
});

test("directives: #help", () => {
  let result = e.execute(`#help;`);
  expect(result.length).toBe(1);
  expect(result[0].value.stdout.trim()).toMatchSnapshot();
});
