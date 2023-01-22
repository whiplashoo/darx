# Darx

## A Dart implementation of the Lox programming language from the book [Crafting Interpreters](http://craftinginterpreters.com/).

### Usage

```bash
dart bin/main.dart or drun
```

### Tests

```bash
dart test/darx_test.dart
```

### License

[MIT](LICENSE)

class Math {
    class square(n) {
        return n * n;
    }
}
print Math.square(3);

class Math { class square(n) { return n * n; } } print Math.square(3);