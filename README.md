# Darx

## A Dart implementation of the Lox programming language from the book [Crafting Interpreters](http://craftinginterpreters.com/).

### Usage

To generate the AST classes, run the following command:

```bash
dart tool/generate_ast.dart
```

To run the REPL, run the following command:

```bash
dart bin/main.dart 
```

### Example Darx code

```dart
for (var i = 1; i < 5; i = i + 1) {
  print i * i;
}

class Duck {
  init(name) {
    this.name = name;
  }

  quack() {
    print this.name + " quacks";
  }
}

var duck = Duck("Waddles");
duck.quack();

fun make_adder(n) {
  fun adder(i) {
    return n + i;
  }
  return adder;
}
var add5 = make_adder(5);
print add5(1);
print add5(100);

// Output:
// 1
// 4
// 9
// 16
// Waddles quacks
// 6
// 105
```

### License

[MIT](LICENSE)
