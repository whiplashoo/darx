import 'expr.dart';
import 'token.dart';
abstract class Stmt {
  void accept(StmtVisitor visitor);
}
abstract class StmtVisitor {
  void visitBlockStmt(Block stmt);
  void visitClassStmt(Class stmt);
  void visitExpressionStmt(Expression stmt);
  void visitFuncStmt(Func stmt);
  void visitIfStmt(If stmt);
  void visitVarStmt(Var stmt);
  void visitPrintStmt(Print stmt);
  void visitReturnStmt(Return stmt);
  void visitWhileStmt(While stmt);
  void visitBreakStmt(Break stmt);
}
class Block extends Stmt {
    Block(this.statements);

  @override
  void accept(StmtVisitor visitor) => visitor.visitBlockStmt(this);

  final List<Stmt> statements;
  }
class Class extends Stmt {
    Class(this.name, this.superclass, this.methods, this.staticMethods);

  @override
  void accept(StmtVisitor visitor) => visitor.visitClassStmt(this);

  final Token name;
  final Variable? superclass;
  final List<Func>? methods;
  final List<Func>? staticMethods;
  }
class Expression extends Stmt {
    Expression(this.expression);

  @override
  void accept(StmtVisitor visitor) => visitor.visitExpressionStmt(this);

  final Expr expression;
  }
class Func extends Stmt {
    Func(this.name, this.params, this.body);

  @override
  void accept(StmtVisitor visitor) => visitor.visitFuncStmt(this);

  final Token name;
  final List<Token> params;
  final List<Stmt> body;
  }
class If extends Stmt {
    If(this.condition, this.thenBranch, this.elseBranch);

  @override
  void accept(StmtVisitor visitor) => visitor.visitIfStmt(this);

  final Expr condition;
  final Stmt thenBranch;
  final Stmt? elseBranch;
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
class Return extends Stmt {
    Return(this.keyword, this.value);

  @override
  void accept(StmtVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;
  final Expr? value;
  }
class While extends Stmt {
    While(this.condition, this.body);

  @override
  void accept(StmtVisitor visitor) => visitor.visitWhileStmt(this);

  final Expr condition;
  final Stmt body;
  }
class Break extends Stmt {
    Break(this.keyword);

  @override
  void accept(StmtVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;
  }
