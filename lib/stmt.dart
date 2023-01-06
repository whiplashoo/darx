import 'expr.dart';
import 'token.dart';
abstract class Stmt {
  void accept(StmtVisitor visitor);
}
abstract class StmtVisitor {
  void visitExpressionStmt(Expression stmt);
  void visitVarStmt(Var stmt);
  void visitPrintStmt(Print stmt);
}
class Expression extends Stmt {
    Expression(this.expression);

  @override
  void accept(StmtVisitor visitor) => visitor.visitExpressionStmt(this);

  final Expr expression;
  }
class Var extends Stmt {
    Var(this.name, this.initializer);

  @override
  void accept(StmtVisitor visitor) => visitor.visitVarStmt(this);

  final Token name;
  final Expr? initializer;
  }
class Print extends Stmt {
    Print(this.expression);

  @override
  void accept(StmtVisitor visitor) => visitor.visitPrintStmt(this);

  final Expr expression;
  }