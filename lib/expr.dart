import 'token.dart';
abstract class Expr {
  T accept<T>(ExprVisitor<T> visitor);
}
abstract class ExprVisitor<T> {
  T visitAssignExpr(Assign expr);
  T visitBinaryExpr(Binary expr);
  T visitGroupingExpr(Grouping expr);
  T visitLiteralExpr(Literal expr);
  T visitVariableExpr(Variable expr);
  T visitUnaryExpr(Unary expr);
}
class Assign extends Expr {
    Assign(this.name, this.value);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitAssignExpr(this);

  final Token name;
  final Expr value;
  }
class Binary extends Expr {
    Binary(this.left, this.operator, this.right);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitBinaryExpr(this);

  final Expr left;
  final Token operator;
  final Expr right;
  }
class Grouping extends Expr {
    Grouping(this.expression);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitGroupingExpr(this);

  final Expr expression;
  }
class Literal extends Expr {
    Literal(this.value);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitLiteralExpr(this);

  final Object? value;
  }
class Variable extends Expr {
    Variable(this.name);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitVariableExpr(this);

  final Token name;
  }
class Unary extends Expr {
    Unary(this.operator, this.right);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitUnaryExpr(this);

  final Token operator;
  final Expr right;
  }
