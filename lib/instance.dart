import 'class.dart';
import 'runtime_error.dart';
import 'token.dart';

class DarxInstance {
  final DarxClass klass;
  final Map<String, Object?> fields = {};

  DarxInstance(this.klass);

  Object? get(Token name) {
    if (fields.containsKey(name.lexeme)) {
      return fields[name.lexeme];
    }

    throw RuntimeError(name, 'Undefined property "${name.lexeme}".');
  }

  void set(Token name, Object? value) {
    fields[name.lexeme] = value;
  }

  @override
  String toString() {
    return '${klass.name} instance';
  }
}
