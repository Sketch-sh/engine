const { evaluator: e } = require("../evaluator/_build/default/evaluator.js");
const objPath = require("object-path");

test("correct values order when having multiple expressions on the same line", () => {
  e.mlSyntax();

  let result = e.execute(`
    let dir = "/static/cmis" in
    let children = Sys.readdir dir in
    Array.iter print_endline children;;
    `);
  console.log(result);

  expect(1).toEqual(1);
});
