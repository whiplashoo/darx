import 'token.dart';

abstract class Expr {}

class Binary extends Expr {
  Binary(this.left, this.operator, this.right);
  final Expr left;
  final Token operator;
  final Expr right;
}

class Grouping extends Expr {
  Grouping(this.expression);
  final Expr expression;
}

class Literal extends Expr {
  Literal(this.value);
  final Object value;
}

class Unary extends Expr {
  Unary(this.operator, this.right);
  final Token operator;
  final Expr right;
}
