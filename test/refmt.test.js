const { refmt } = require("../evaluator/_build/default/evaluator.js");

test("api shape", () => {
  expect(Object.keys(refmt)).toMatchInlineSnapshot(`
Array [
  "parseRE",
  "parseREI",
  "parseML",
  "parseMLI",
  "printRE",
  "printREI",
  "printML",
  "printMLI",
]
`);
});

describe("same language", () => {
  test("parseRE -> printRE", () => {
    expect(
      refmt.printRE(refmt.parseRE(`let f = (a) => a + 1; print_int(f(5))`))
    ).toMatchInlineSnapshot(`
"let f = a => a + 1;
print_int(f(5));
"
`);
  });
  test("parseREI -> printREI", () => {
    expect(refmt.printREI(refmt.parseREI(`let f: (~a: string) => int`)))
      .toMatchInlineSnapshot(`
"let f: (~a: string) => int;
"
`);
  });

  test("parseML -> printML", () => {
    expect(
      refmt.printML(refmt.parseML(`let f a = a + 1 print_int @@ f 5`))
    ).toMatchInlineSnapshot(`"let f a = (a + (1 print_int)) @@ (f 5)"`);
  });
  test("parseMLI -> printMLI", () => {
    expect(
      refmt.printMLI(refmt.parseMLI(`val f : a:string -> int`))
    ).toMatchInlineSnapshot(`"val f : a:string -> int"`);
  });
});

describe("cross language", () => {
  test("parseRE -> printML", () => {
    expect(
      refmt.printML(refmt.parseRE(`let f = (a) => a + 1; print_int(f(5))`))
    ).toMatchInlineSnapshot(`
"let f a = a + 1
;;print_int (f 5)"
`);
  });

  test("parseML -> printRE", () => {
    expect(
      refmt.printRE(refmt.parseML(`let f a = a + 1 let () = print_int @@ f 5`))
    ).toMatchInlineSnapshot(`
"let f = a => a + 1;
let () = print_int @@ f(5);
"
`);
  });
});

describe("error", () => {
  test("parseRE", () => {
    try {
      refmt.parseRE(`let f => =`);
    } catch (error) {
      expect(error).toMatchInlineSnapshot(`
Object {
  "location": Array [
    Array [
      0,
      Object {
        "col": 6,
        "line": 0,
      },
      Object {
        "col": 7,
        "line": 0,
      },
    ],
  ],
  "message": "1694: <syntax error>",
}
`);
    }
  });
  test("parseMLI", () => {
    try {
      refmt.parseMLI(`val f: `);
    } catch (error) {
      expect(error).toMatchInlineSnapshot(`
Object {
  "location": Array [
    Array [
      0,
      Object {
        "col": 7,
        "line": 0,
      },
      Object {
        "col": 7,
        "line": 0,
      },
    ],
  ],
  "message": "File \\"\\", line 1, characters 7-7:
Error: Syntax error",
}
`);
    }
  });
  test("parseRE", () => {
    try {
      refmt.parseRE(`type X = Foo`);
    } catch (error) {
      expect(error).toMatchInlineSnapshot(`
Object {
  "location": Array [
    Array [
      0,
      Object {
        "col": 5,
        "line": 0,
      },
      Object {
        "col": 5,
        "line": 0,
      },
    ],
  ],
  "message": "a type name must start with a lower-case letter or an underscore",
}
`);
    }
  });
});
