import 'expr.dart';
abstract class Stmt {
  void accept(StmtVisitor visitor);
}
abstract class StmtVisitor {
  void visitExpressionStmt(Expression stmt);
  void visitPrintStmt(Print stmt);
}
class Expression extends Stmt {
    Expression(this.expression);

  @override
  void accept(StmtVisitor visitor) => visitor.visitExpressionStmt(this);

  final Expr expression;
  }
class Print extends Stmt {
    Print(this.expression);

  @override
  void accept(StmtVisitor visitor) => visitor.visitPrintStmt(this);

  final Expr expression;
  }
