import 'package:darx/return.dart';

import 'callable.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'stmt.dart';

class DarxFunction implements Callable {
  late Func declaration;

  DarxFunction(this.declaration);

  @override
  int get arity => declaration.params.length;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    var environment = Environment(interpreter.globals);
    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, environment);
    } on ReturnException catch (returnValue) {
      return returnValue.value;
    }
    return null;
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }
}
