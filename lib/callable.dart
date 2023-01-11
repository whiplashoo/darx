import 'interpreter.dart';

abstract class Callable {
  int get arity;
  Object? call(Interpreter interpreter, List<Object?> arguments);
}
