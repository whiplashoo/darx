import 'runtime_error.dart';
import 'token.dart';

class Environment {
  Environment? enclosing;
  final Map<String, Object?> values = {};

  Environment(this.enclosing);

  void define(String name, Object? value) {
    values[name] = value;
  }

  Object? get(Token name) {
    if (values.containsKey(name.lexeme)) {
      // if (values[name.lexeme] == null) {
      //   throw RuntimeError(name, 'Variable "${name.lexeme}" is uninitialized.');
      // }
      return values[name.lexeme];
    }
    if (enclosing != null) return enclosing!.get(name);

    throw RuntimeError(name, 'Undefined variable "${name.lexeme}".');
  }

  void assign(Token name, Object? value) {
    if (values.containsKey(name.lexeme)) {
      values[name.lexeme] = value;
      return;
    }

    if (enclosing != null) {
      enclosing!.assign(name, value);
      return;
    }

    throw RuntimeError(name, 'Undefined variable "${name.lexeme}".');
  }
}
