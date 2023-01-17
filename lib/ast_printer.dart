import 'expr.dart';

class AstPrinter implements ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return parenthesize(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return parenthesize("group", [expr.expression]);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return parenthesize(expr.operator.lexeme, [expr.right]);
  }

  String parenthesize(String name, List<Expr> exprs) {
    var builder = StringBuffer();

    builder.write("(");
    builder.write(name);
    for (var expr in exprs) {
      builder.write(" ");
      builder.write(expr.accept(this));
    }
    builder.write(")");

    return builder.toString();
  }

  @override
  String visitVariableExpr(Variable expr) {
    // TODO: implement visitVariableExpr
    throw UnimplementedError();
  }

  @override
  String visitAssignExpr(Assign expr) {
    // TODO: implement visitAssignExpr
    throw UnimplementedError();
  }

  @override
  String visitLogicalExpr(Logical expr) {
    // TODO: implement visitLogicalExpr
    throw UnimplementedError();
  }

  @override
  String visitCallExpr(Call expr) {
    // TODO: implement visitCallExpr
    throw UnimplementedError();
  }

  @override
  String visitGetExpr(Get expr) {
    // TODO: implement visitGetExpr
    throw UnimplementedError();
  }

  @override
  String visitSetExpr(Set expr) {
    // TODO: implement visitSetExpr
    throw UnimplementedError();
  }

  @override
  String visitThisExpr(This expr) {
    // TODO: implement visitThisExpr
    throw UnimplementedError();
  }
}
