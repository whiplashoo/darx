import 'package:darx/return.dart';
import 'package:darx/runtime_error.dart';
import 'package:darx/stmt.dart';

import 'callable.dart';
import 'class.dart';
import 'environment.dart';
import 'expr.dart';
import 'function.dart';
import 'instance.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object?>, StmtVisitor {
  final globals = Environment(null);
  late Environment environment;
  final locals = <Expr, int>{};

  Interpreter() {
    globals.define("clock", Clock());
    environment = globals;
  }

  void interpret(List<Stmt> statements) {
    try {
      for (Stmt statement in statements) {
        execute(statement);
      }
    } on RuntimeError catch (error) {
      print(error);
      return;
    }
  }

  Object? evaluate(Expr expr) {
    return expr.accept(this);
  }

  void execute(Stmt stmt) {
    stmt.accept(this);
  }

  void resolve(Expr expr, int depth) {
    locals[expr] = depth;
  }

  void executeBlock(List<Stmt> statements, Environment environment) {
    Environment previous = this.environment;
    try {
      this.environment = environment;
      for (Stmt statement in statements) {
        execute(statement);
      }
    } finally {
      this.environment = previous;
    }
  }

  @override
  Object? visitBinaryExpr(Binary expr) {
    Object? left = evaluate(expr.left);
    Object? right = evaluate(expr.right);
    switch (expr.operator.type) {
      case TokenType.MINUS:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) - (right as num);
      case TokenType.SLASH:
        checkNumberOperands(expr.operator, left, right);
        if ((right as num) == 0) {
          throw RuntimeError(expr.operator, 'Division by zero.');
        }
        return (left as num) / right;
      case TokenType.STAR:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) * (right as num);
      case TokenType.PLUS:
        if (left is num && right is num) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        if (left is num && right is String) {
          return left.truncate().toString() + right;
        }
        if (left is String && right is num) {
          return left + right.truncate().toString();
        }
        throw RuntimeError(
            expr.operator, 'Operands must be two numbers or two strings.');
      case TokenType.GREATER:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) > (right as num);
      case TokenType.GREATER_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) >= (right as num);
      case TokenType.LESS:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) < (right as num);
      case TokenType.LESS_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        return (left as num) <= (right as num);
      case TokenType.BANG_EQUAL:
        return !isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        return isEqual(left, right);
    }
    return null;
  }

  @override
  Object? visitGroupingExpr(Grouping expr) {
    return evaluate(expr.expression);
  }

  @override
  Object? visitLiteralExpr(Literal expr) {
    return expr.value;
  }

  @override
  Object? visitUnaryExpr(Unary expr) {
    Object? right = evaluate(expr.right);
    switch (expr.operator.type) {
      case TokenType.MINUS:
        checkNumberOperand(expr.operator, right);
        return -(right as num);
      case TokenType.BANG:
        return !isTruthy(right);
    }
    return null;
  }

  bool isTruthy(Object? object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool isEqual(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a == null) return false;
    return a == b;
  }

  String stringify(Object? value) {
    if (value == null) {
      return 'nil';
    } else if (value is double) {
      final text = value.toString();
      if (text.endsWith('.0')) {
        return text.split('.').first;
      } else {
        return text;
      }
    } else {
      return value.toString();
    }
  }

  void checkNumberOperand(Token operator, Object? operand) {
    if (operand is num) return;
    throw RuntimeError(operator, 'Operand must be a number.');
  }

  void checkNumberOperands(Token operator, Object? left, Object? right) {
    if (left is num && right is num) return;
    throw RuntimeError(operator, 'Operands must be numbers.');
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    evaluate(stmt.expression);
    return;
  }

  @override
  void visitPrintStmt(Print stmt) {
    Object? value = evaluate(stmt.expression);
    print(stringify(value));
    return;
  }

  @override
  void visitVarStmt(Var stmt) {
    Object? value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer!);
    }
    environment.define(stmt.name.lexeme, value);
    return;
  }

  @override
  Object? visitVariableExpr(Variable expr) {
    return lookUpVariable(expr.name, expr);
  }

  Object? lookUpVariable(Token name, Expr expr) {
    int? distance = locals[expr];
    if (distance != null) {
      return environment.getAt(distance, name.lexeme);
    } else {
      return globals.get(name);
    }
  }

  @override
  Object? visitAssignExpr(Assign expr) {
    Object? value = evaluate(expr.value);
    int? distance = locals[expr];
    if (distance != null) {
      environment.assignAt(distance, expr.name, value);
    } else {
      globals.assign(expr.name, value);
    }
    return value;
  }

  @override
  void visitBlockStmt(Block stmt) {
    executeBlock(stmt.statements, Environment(environment));
    return;
  }

  @override
  void visitIfStmt(If stmt) {
    if (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      execute(stmt.elseBranch!);
    }
    return;
  }

  @override
  Object? visitLogicalExpr(Logical expr) {
    Object? left = evaluate(expr.left);
    if (expr.operator.type == TokenType.OR) {
      if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }
    return evaluate(expr.right);
  }

  @override
  void visitWhileStmt(While stmt) {
    try {
      while (isTruthy(evaluate(stmt.condition))) {
        execute(stmt.body);
      }
    } on BreakException catch (e) {
      print(e.message);
    }
    return;
  }

  @override
  void visitBreakStmt(Break stmt) {
    throw BreakException(stmt.keyword, "");
  }

  @override
  Object? visitCallExpr(Call expr) {
    Object? callee = evaluate(expr.callee);
    List<Object?> arguments = [];
    for (Expr argument in expr.arguments) {
      arguments.add(evaluate(argument));
    }
    if (callee is! Callable) {
      throw RuntimeError(expr.paren, 'Can only call functions and classes.');
    }
    Callable function = callee;
    if (arguments.length != function.arity) {
      throw RuntimeError(expr.paren,
          'Expected ${function.arity} arguments but got ${arguments.length}.');
    }
    return function.call(this, arguments);
  }

  @override
  void visitFuncStmt(Func stmt) {
    DarxFunction function = DarxFunction(stmt, environment);
    environment.define(stmt.name.lexeme, function);
    return;
  }

  @override
  void visitReturnStmt(Return stmt) {
    Object? value;
    if (stmt.value != null) value = evaluate(stmt.value!);
    throw ReturnException(value);
  }

  @override
  void visitClassStmt(Class stmt) {
    environment.define(stmt.name.lexeme, null);
    Map<String, DarxFunction> methods = {};
    if (stmt.methods != null) {
      for (Func method in stmt.methods!) {
        DarxFunction function = DarxFunction(method, environment);
        methods[method.name.lexeme] = function;
      }
    }
    DarxClass klass = DarxClass(stmt.name.lexeme, methods);
    environment.assign(stmt.name, klass);
    return;
  }

  @override
  Object? visitGetExpr(Get expr) {
    Object? object = evaluate(expr.object);
    if (object is DarxInstance) {
      return object.get(expr.name);
    }
    throw RuntimeError(expr.name, "Only instances have properties.");
  }

  @override
  Object? visitSetExpr(Set expr) {
    Object? object = evaluate(expr.object);
    if (object is DarxInstance) {
      Object? value = evaluate(expr.value);
      object.set(expr.name, value);
      return value;
    }
    throw RuntimeError(expr.name, "Only instances have fields.");
  }

  @override
  Object? visitThisExpr(This expr) {
    return lookUpVariable(expr.keyword, expr);
  }
}

class BreakException extends RuntimeError {
  BreakException(super.token, super.message);
}
// var i = 0; while (i < 10) { i = i +1; print i; if (i == 5) { break; } }

class Clock implements Callable {
  @override
  int arity = 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    return DateTime.now().millisecondsSinceEpoch / 1000;
  }

  @override
  String toString() {
    return '<native fn>';
  }
}
