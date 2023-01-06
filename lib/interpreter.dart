import 'package:darx/runtime_error.dart';
import 'package:darx/stmt.dart';

import 'expr.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object?>, StmtVisitor {
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
}
