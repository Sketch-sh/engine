const { evaluator: e } = require("../build/toplevel.js");
const objPath = require("object-path");

let count = (result, path, value) =>
  result.reduce((acc, phr_result) => {
    let valueAtPath = objPath.get(phr_result, path);
    if (typeof value === "function") {
      if (value(valueAtPath)) {
        return acc + 1;
      }
    } else if (valueAtPath === value) {
      return acc + 1;
    }
    return acc;
  }, 0);

let code = [
  // 0
  `print_endline("awesome")

  type say = Hello | Goodbye;

  fun
  | Hello => ()
  | Goodbye => ()
  | _ => ();

  let a = 1`,
  // 1
  `print_endline("Another stdout")`,
  // 2
  `let a = ref(1); print_int(a^);`,
  // 3
  `let rec factorial = (n) => n <= 0 ? 1 : n * factorial(n - 1); factorial(6);`,
  // 4
  `type tree =
  | Leaf
  | Node(int, tree, tree)
  
  let rec sum =
  fun
  | Leaf => 0
  | Node(value, left, right) => value + sum(left) + sum(right)
  
  let myTree =
  Node(
    1,
    Node(2, Node(4, Leaf, Leaf), Node(6, Leaf, Leaf)),
    Node(3, Node(5, Leaf, Leaf), Node(7, Leaf, Leaf)),
  )
  
  sum(myTree)`,
];

describe.each`
  nth  | phr_count | ok   | error | warning | stdout
  ${0} | ${4}      | ${4} | ${0}  | ${1}    | ${1}
  ${1} | ${1}      | ${1} | ${0}  | ${0}    | ${1}
  ${2} | ${2}      | ${2} | ${0}  | ${0}    | ${1}
  ${3} | ${2}      | ${2} | ${0}  | ${0}    | ${0}
  ${4} | ${4}      | ${4} | ${0}  | ${0}    | ${0}
`("$nth", ({ nth, phr_count, ok, error, warning, stdout }) => {
  let result = e.execute(code[nth]);

  test(`have ${phr_count} phrases`, () => {
    expect(result.length).toBe(phr_count);
  });

  test(`have ${ok} ok phrases`, () => {
    expect(count(result, "kind", "Ok")).toBe(ok);
  });

  test(`have ${error} error phrases`, () => {
    expect(count(result, "kind", "Error")).toBe(error);
  });

  test(`have ${warning} warnings`, () => {
    expect(
      count(result, "value.stderr", stderr => stderr.indexOf("Warning") > 0)
    ).toBe(warning);
  });

  test(`have ${stdout} stdout`, () => {
    expect(count(result, "value.stdout", stderr => stderr !== "")).toBe(stdout);
  });

  test("snapshot", () => {
    expect(result).toMatchSnapshot();
  });
});
