import 'package:darx/expr.dart';
import 'package:darx/return.dart';

import 'callable.dart';
import 'environment.dart';
import 'interpreter.dart';

class DarxFunction implements Callable {
  String? name;
  late FuncExpr declaration;
  late Environment closure;

  DarxFunction(this.name, this.declaration, this.closure);

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
      return returnValue.value;
    }
    return null;
  }

  @override
  String toString() {
    return name != null ? "<fn $name>" : "anonymous function";
  }
}
