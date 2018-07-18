const {evaluator: e} = require("./_build/default/evaluator.js");
const assertLib = require("assert");

const assert = (a, b) => {
  assertLib(e.execute(a).trim() === b.trim());  
}

assert(`let a = 1 + 2;`, `let a: int = 3;`);
assert(`let b = a + 2;`, `let b: int = 5;`);
assert(`
let rec factorial = (n) =>
  n <= 0
  ? 1
  : n * factorial(n - 1);

factorial(6);
`, 
`
let factorial: int => int = <fun>;
- : int = 720
`
);

console.log("Done");
