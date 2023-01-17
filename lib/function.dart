import 'package:darx/return.dart';

import 'callable.dart';
import 'environment.dart';
import 'instance.dart';
import 'interpreter.dart';
import 'stmt.dart';

class DarxFunction implements Callable {
  late Func declaration;
  late Environment closure;
  bool isInitializer;

  DarxFunction(this.declaration, this.closure, this.isInitializer);

  @override
  int get arity => declaration.params.length;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    var environment = Environment(closure);
    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, environment);
    } on ReturnException catch (returnValue) {
      if (isInitializer) return closure.getAt(0, 'this');
      return returnValue.value;
    }
    if (isInitializer) return closure.getAt(0, 'this');
    return null;
  }

  DarxFunction bind(DarxInstance instance) {
    var environment = Environment(closure);
    environment.define('this', instance);
    return DarxFunction(declaration, environment, isInitializer);
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }
}
