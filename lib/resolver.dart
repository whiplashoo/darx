// ignore_for_file: constant_identifier_names

import 'dart:collection';

import 'expr.dart';
import 'interpreter.dart';
import 'runtime_error.dart';
import 'stmt.dart';
import 'token.dart';

enum FunctionType { NONE, FUNCTION, INITIALIZER, METHOD, STATIC_METHOD }

enum ClassType {
  NONE,
  CLASS,
  SUBCLASS,
}

class Resolver implements ExprVisitor<Object?>, StmtVisitor {
  Interpreter interpreter;
  Stack<Map<String, bool>> scopes = Stack();
  FunctionType currentFunction = FunctionType.NONE;
  ClassType currentClass = ClassType.NONE;

  Resolver(this.interpreter);

  void resolve(List<Stmt> statements) {
    for (Stmt statement in statements) {
      resolveStmt(statement);
    }
  }

  void resolveFunction(Func function, FunctionType type) {
    FunctionType enclosingFunction = currentFunction;
    currentFunction = type;
    beginScope();
    if (function.params != null) {
      for (Token param in function.params!) {
        declare(param);
        define(param);
      }
    }
    resolve(function.body);
    endScope();
    currentFunction = enclosingFunction;
  }

  void resolveStmt(Stmt stmt) {
    stmt.accept(this);
  }

  void resolveExpr(Expr expr) {
    expr.accept(this);
  }

  void beginScope() {
    scopes.push(<String, bool>{});
  }

  void endScope() {
    scopes.pop();
  }

  void declare(Token name) {
    if (scopes.isEmpty) return;

    Map<String, bool> scope = scopes.peek();
    if (scope.containsKey(name.lexeme)) {
      throw RuntimeError(
          name, "Variable with this name already declared in this scope.");
    }

    scope[name.lexeme] = false;
  }

  void define(Token name) {
    if (scopes.isEmpty) return;
    scopes.peek()[name.lexeme] = true;
  }

  void resolveLocal(Expr expr, Token name) {
    for (int i = scopes.length - 1; i >= 0; i--) {
      if (scopes.elementAt(i).containsKey(name.lexeme)) {
        interpreter.resolve(expr, scopes.length - 1 - i);
        return;
      }
    }
  }

  @override
  void visitAssignExpr(Assign expr) {
    resolveExpr(expr.value);
    resolveLocal(expr, expr.name);
    return;
  }

  @override
  void visitBinaryExpr(Binary expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
  }

  @override
  void visitBlockStmt(Block stmt) {
    beginScope();
    resolve(stmt.statements);
    endScope();
  }

  @override
  void visitBreakStmt(Break stmt) {
    return;
  }

  @override
  void visitCallExpr(Call expr) {
    resolveExpr(expr.callee);
    for (Expr argument in expr.arguments) {
      resolveExpr(argument);
    }
    return;
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    resolveExpr(stmt.expression);
  }

  @override
  void visitFuncStmt(Func stmt) {
    declare(stmt.name);
    define(stmt.name);
    resolveFunction(stmt, FunctionType.FUNCTION);
    return;
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    resolveExpr(expr.expression);
    return;
  }

  @override
  void visitIfStmt(If stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveStmt(stmt.elseBranch!);
    return;
  }

  @override
  void visitLiteralExpr(Literal expr) {
    return;
  }

  @override
  void visitLogicalExpr(Logical expr) {
    resolveExpr(expr.left);
    resolveExpr(expr.right);
    return;
  }

  @override
  void visitPrintStmt(Print stmt) {
    resolveExpr(stmt.expression);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      throw RuntimeError(stmt.keyword, "Cannot return from top-level code.");
    }
    if (stmt.value != null) {
      if (currentFunction == FunctionType.INITIALIZER) {
        throw RuntimeError(
            stmt.keyword, "Cannot return a value from an initializer.");
      }
      resolveExpr(stmt.value!);
    }
  }

  @override
  void visitUnaryExpr(Unary expr) {
    resolveExpr(expr.right);
    return;
  }

  @override
  void visitVarStmt(Var stmt) {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveExpr(stmt.initializer!);
    }
    define(stmt.name);
    return;
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (!scopes.isEmpty && scopes.peek()[expr.name.lexeme] == false) {
      throw RuntimeError(
          expr.name, "Cannot read local variable in its own initializer.");
    }
    resolveLocal(expr, expr.name);
    return;
  }

  @override
  void visitWhileStmt(While stmt) {
    resolveExpr(stmt.condition);
    resolveStmt(stmt.body);
  }

  @override
  void visitClassStmt(Class stmt) {
    ClassType enclosingClass = currentClass;
    currentClass = ClassType.CLASS;
    declare(stmt.name);
    define(stmt.name);
    if (stmt.superclass != null) {
      currentClass = ClassType.SUBCLASS;
      resolveExpr(stmt.superclass!);
    }
    if (stmt.superclass != null) {
      beginScope();
      scopes.peek()["super"] = true;
    }

    if (stmt.superclass != null &&
        stmt.name.lexeme == stmt.superclass!.name.lexeme) {
      throw RuntimeError(
          stmt.superclass!.name, "A class cannot inherit from itself.");
    }
    beginScope();
    scopes.peek()["this"] = true;
    if (stmt.methods != null) {
      for (Func method in stmt.methods!) {
        FunctionType declaration = FunctionType.METHOD;
        if (method.name.lexeme == "init") {
          declaration = FunctionType.INITIALIZER;
        }
        resolveFunction(method, declaration);
      }
    }
    endScope();
    beginScope();
    if (stmt.staticMethods != null) {
      for (Func method in stmt.staticMethods!) {
        FunctionType declaration = FunctionType.STATIC_METHOD;
        resolveFunction(method, declaration);
      }
    }
    endScope();
    if (stmt.superclass != null) endScope();
    currentClass = enclosingClass;
  }

  @override
  void visitGetExpr(Get expr) {
    resolveExpr(expr.object);
  }

  @override
  void visitSetExpr(Set expr) {
    resolveExpr(expr.value);
    resolveExpr(expr.object);
  }

  @override
  void visitThisExpr(This expr) {
    if (currentClass == ClassType.NONE) {
      throw RuntimeError(expr.keyword, "Cannot use 'this' outside of a class.");
    }
    resolveLocal(expr, expr.keyword);
  }

  @override
  Object? visitSuperExpr(Super expr) {
    if (currentClass == ClassType.NONE) {
      throw RuntimeError(
          expr.keyword, "Cannot use 'super' outside of a class.");
    } else if (currentClass != ClassType.SUBCLASS) {
      throw RuntimeError(
          expr.keyword, "Cannot use 'super' in a class with no superclass.");
    }
    resolveLocal(expr, expr.keyword);
    return null;
  }
}

class Stack<T> {
  final _stack = Queue<T>();

  int get length => _stack.length;

  bool get isEmpty => _stack.isEmpty;

  T elementAt(int index) => _stack.elementAt(index);

  bool canPop() => _stack.isNotEmpty;

  void clearStack() {
    while (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  void push(T element) {
    _stack.addLast(element);
  }

  T pop() {
    T lastElement = _stack.last;
    _stack.removeLast();
    return lastElement;
  }

  T peek() => _stack.last;
}
