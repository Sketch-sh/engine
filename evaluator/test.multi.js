const { evaluator: e } = require("./_build/default/evaluator.js");
const assertLib = require("assert");

const util = require("util");

const log = myObject => {
  console.log(util.inspect(myObject, { showHidden: false, depth: null }));
};

const assert = a => {
  log(e.execute(a));
};

assert(`
#help;

print_endline("awesome")

type say = Hello | Goodbye;

fun
| Hello => ()
| Goodbye => ()
| _ => ();

let a = 1
`);

assert(`type tree =
| Leaf
| Node(int, tree, tree);

let rec sum =
fun
| Leaf => 0
| Node(value, left, right) => value + sum(left) + sum(right);

let myTree =
Node(
  1,
  Node(2, Node(4, Leaf, Leaf), Node(6, Leaf, Leaf)),
  Node(3, Node(5, Leaf, Leaf), Node(7, Leaf, Leaf)),
);

sum(myTree);`)
