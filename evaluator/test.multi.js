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
