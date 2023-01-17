import 'package:darx/interpreter.dart';

import 'callable.dart';
import 'instance.dart';

class DarxClass implements Callable {
  final String name;

  DarxClass(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  int get arity => 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    DarxInstance instance = DarxInstance(this);
    return instance;
  }
}
