import 'package:darx/interpreter.dart';

import 'callable.dart';
import 'function.dart';
import 'instance.dart';

class DarxClass extends DarxInstance implements Callable {
  final DarxClass? superclass;
  final String name;
  final Map<String, DarxFunction> methods;

  DarxClass? metaclass;

  DarxClass(this.metaclass, this.name, this.superclass, this.methods)
      : super(metaclass);

  @override
  String toString() {
    return name;
  }

  DarxFunction? findMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }
    if (superclass != null) {
      return superclass!.findMethod(name);
    }
    return null;
  }

  @override
  int get arity {
    DarxFunction? initializer = findMethod('init');
    if (initializer == null) return 0;
    return initializer.arity;
  }

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    DarxInstance instance = DarxInstance(this);
    DarxFunction? initializer = findMethod('init');
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }
    return instance;
  }
}
