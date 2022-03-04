const { refmt } = require("./engine.js");

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
  "message": "Line 1, characters 6-8:
Error: syntax error, consider adding a \`;' before

",
}
`);
    }
  });
  test("parseMLI", () => {
    try {
      refmt.parseMLI(`val f: `);
    } catch (error) {
      expect(error).toMatchInlineSnapshot(`
Array [
  0,
  Array [
    248,
    qT {
      "c": "Syntaxerr.Error",
      "l": 15,
      "t": 0,
    },
    31,
  ],
  Array [
    5,
    Array [
      0,
      Array [
        0,
        qT {
          "c": "",
          "l": 0,
          "t": 0,
        },
        1,
        0,
        7,
      ],
      Array [
        0,
        qT {
          "c": "",
          "l": 0,
          "t": 0,
        },
        1,
        0,
        7,
      ],
      0,
    ],
  ],
]
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
  "message": "Line 1, characters 5-6:
Error: a type name must start with a lower-case letter or an underscore

",
}
`);
    }
  });
});
