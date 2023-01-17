import 'package:darx/interpreter.dart';

import 'callable.dart';
import 'function.dart';
import 'instance.dart';

class DarxClass implements Callable {
  final String name;
  final Map<String, DarxFunction> methods;

  DarxClass(this.name, this.methods);

  @override
  String toString() {
    return name;
  }

  DarxFunction? findMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }
    return null;
  }

  @override
  int get arity => 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    DarxInstance instance = DarxInstance(this);
    return instance;
  }
}
