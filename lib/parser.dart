import 'package:darx/runtime_error.dart';
import 'package:darx/token_type.dart';

import 'expr.dart';
import 'stmt.dart';
import 'token.dart';

class Parser {
  final List<Token> tokens;
  int current = 0;
  int loopDepth = 0;

  Parser(this.tokens);

  List<Stmt> parse() {
    List<Stmt> statements = [];
    while (!isAtEnd()) {
      statements.add(declaration());
    }
    return statements;
  }

  Expr expression() {
    return assignment();
  }

  Stmt declaration() {
    try {
      if (match([TokenType.CLASS])) return classDeclaration();
      if (match([TokenType.FUN])) return function('function');
      if (match([TokenType.VAR])) return varDeclaration();
      return statement();
    } on RuntimeError {
      synchronize();
      return Expression(Literal(null));
    }
  }

  Stmt classDeclaration() {
    Token name = consume(TokenType.IDENTIFIER, 'Expect class name.');
    Variable? superclass;
    if (match([TokenType.LESS])) {
      consume(TokenType.IDENTIFIER, 'Expect superclass name.');
      superclass = Variable(previous());
    }
    consume(TokenType.LEFT_BRACE, 'Expect \'{\' before class body.');
    List<Func> methods = [];
    while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      methods.add(function('method'));
    }
    consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after class body.');
    return Class(name, superclass, methods);
  }

  Stmt statement() {
    if (match([TokenType.FOR])) return forStatement();
    if (match([TokenType.BREAK])) return breakStatement();
    if (match([TokenType.IF])) return ifStatement();
    if (match([TokenType.WHILE])) return whileStatement();
    if (match([TokenType.PRINT])) return printStatement();
    if (match([TokenType.RETURN])) return returnStatement();
    if (match([TokenType.LEFT_BRACE])) return Block(block());
    return expressionStatement();
  }

  Stmt breakStatement() {
    if (loopDepth == 0) {
      throw RuntimeError(previous(), 'Cannot use \'break\' outside of a loop.');
    }
    consume(TokenType.SEMICOLON, 'Expect \';\' after break.');
    return Break(previous());
  }

  Stmt forStatement() {
    consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'for\'.');
    Stmt initializer;
    if (match([TokenType.SEMICOLON])) {
      initializer = Expression(Literal(null));
    } else if (match([TokenType.VAR])) {
      initializer = varDeclaration();
    } else {
      initializer = expressionStatement();
    }
    Expr? condition;
    if (!check(TokenType.SEMICOLON)) {
      condition = expression();
    }
    consume(TokenType.SEMICOLON, 'Expect \';\' after loop condition.');

    Expr? increment;
    if (!check(TokenType.RIGHT_PAREN)) {
      increment = expression();
    }
    consume(TokenType.RIGHT_PAREN, 'Expect \')\' after for clauses.');

    try {
      loopDepth++;
      Stmt body = statement();
      if (increment != null) {
        body = Block([body, Expression(increment)]);
      }
      condition ??= Literal(true);
      body = While(condition, body);
      body = Block([initializer, body]);

      return body;
    } finally {
      loopDepth--;
    }
  }

  Stmt ifStatement() {
    consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'if\'.');
    Expr condition = expression();
    consume(TokenType.RIGHT_PAREN, 'Expect \')\' after if condition.');
    Stmt thenBranch = statement();
    Stmt? elseBranch;
    if (match([TokenType.ELSE])) {
      elseBranch = statement();
    }
    return If(condition, thenBranch, elseBranch);
  }

  Stmt whileStatement() {
    consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'while\'.');
    Expr condition = expression();
    consume(TokenType.RIGHT_PAREN, 'Expect \')\' after while condition.');
    try {
      loopDepth++;
      Stmt body = statement();
      return While(condition, body);
    } finally {
      loopDepth--;
    }
  }

  Stmt printStatement() {
    Expr value = expression();
    consume(TokenType.SEMICOLON, 'Expect \';\' after value.');
    return Print(value);
  }

  Stmt returnStatement() {
    Token keyword = previous();
    Expr? returnExpr;
    if (!check(TokenType.SEMICOLON)) {
      returnExpr = expression();
    }
    consume(TokenType.SEMICOLON, 'Expect \';\' after return statement.');
    return Return(keyword, returnExpr);
  }

  Stmt varDeclaration() {
    Token name = consume(TokenType.IDENTIFIER, 'Expect variable name.');
    Expr? initializer;
    if (match([TokenType.EQUAL])) {
      initializer = expression();
    }
    consume(TokenType.SEMICOLON, 'Expect \';\' after variable declaration.');
    return Var(name, initializer);
  }

  Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.SEMICOLON, 'Expect \';\' after expression.');
    return Expression(expr);
  }

  Func function(String kind) {
    Token name = consume(TokenType.IDENTIFIER, 'Expect $kind name.');
    consume(TokenType.LEFT_PAREN, 'Expect \'(\' after $kind name.');
    List<Token> parameters = [];
    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        if (parameters.length >= 255) {
          error(peek(), 'Cannot have more than 255 parameters.');
        }
        parameters.add(consume(TokenType.IDENTIFIER, 'Expect parameter name.'));
      } while (match([TokenType.COMMA]));
    }
    consume(TokenType.RIGHT_PAREN, 'Expect \')\' after parameters.');
    consume(TokenType.LEFT_BRACE, 'Expect \'{\' before $kind body.');
    List<Stmt> body = block();
    return Func(name, parameters, body);
  }

  List<Stmt> block() {
    List<Stmt> statements = [];
    while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      statements.add(declaration());
    }
    consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after block.');
    return statements;
  }

  Expr assignment() {
    Expr expr = or();
    if (match([TokenType.EQUAL])) {
      Token equals = previous();
      Expr value = assignment();
      if (expr is Variable) {
        Token name = expr.name;
        return Assign(name, value);
      } else if (expr is Get) {
        return Set(expr.object, expr.name, value);
      }
      error(equals, 'Invalid assignment target.');
    }
    return expr;
  }

  Expr or() {
    Expr expr = and();
    while (match([TokenType.OR])) {
      Token operator = previous();
      Expr right = and();
      expr = Logical(expr, operator, right);
    }
    return expr;
  }

  Expr and() {
    Expr expr = equality();
    while (match([TokenType.AND])) {
      Token operator = previous();
      Expr right = equality();
      expr = Logical(expr, operator, right);
    }
    return expr;
  }

  Expr equality() {
    Expr expr = comparison();
    while (match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = previous();
      Expr right = comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr comparison() {
    Expr expr = term();
    while (match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      var operator = previous();
      Expr right = term();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr term() {
    Expr expr = factor();
    while (match([TokenType.MINUS, TokenType.PLUS])) {
      Token operator = previous();
      Expr right = factor();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr factor() {
    Expr expr = unary();
    while (match([TokenType.SLASH, TokenType.STAR])) {
      Token operator = previous();
      Expr right = unary();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  Expr unary() {
    if (match([TokenType.BANG, TokenType.MINUS])) {
      Token operator = previous();
      Expr right = unary();
      return Unary(operator, right);
    }
    return call();
  }

  Expr finishCall(Expr callee) {
    List<Expr> arguments = [];
    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        if (arguments.length >= 255) {
          error(peek(), 'Cannot have more than 255 arguments.');
        }
        arguments.add(expression());
      } while (match([TokenType.COMMA]));
    }
    Token paren =
        consume(TokenType.RIGHT_PAREN, 'Expect \')\' after arguments.');
    return Call(callee, paren, arguments);
  }

  Expr call() {
    Expr expr = primary();
    while (true) {
      if (match([TokenType.LEFT_PAREN])) {
        expr = finishCall(expr);
      } else if (match([TokenType.DOT])) {
        Token name =
            consume(TokenType.IDENTIFIER, 'Expect property name after \'.\'.');
        expr = Get(expr, name);
      } else {
        break;
      }
    }
    return expr;
  }

  Expr primary() {
    if (match([TokenType.FALSE])) return Literal(false);
    if (match([TokenType.TRUE])) return Literal(true);
    if (match([TokenType.NIL])) return Literal(null);

    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(previous().literal!);
    }

    if (match([TokenType.SUPER])) {
      Token keyword = previous();
      consume(TokenType.DOT, "Expect '.' after 'super'.");
      Token method = consume(
          TokenType.IDENTIFIER, "Expect superclass method name after '.'.");
      return Super(keyword, method);
    }

    if (match([TokenType.THIS])) {
      return This(previous());
    }

    if (match([TokenType.IDENTIFIER])) {
      return Variable(previous());
    }

    if (match([TokenType.LEFT_PAREN])) {
      Expr expr = expression();
      consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expr);
    }
    throw error(peek(), 'Expect expression.');
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();
    throw error(peek(), message);
  }

  Exception error(Token token, String message) {
    return RuntimeError(token, message);
  }

  void synchronize() {
    advance();
    while (!isAtEnd()) {
      if (previous().type == TokenType.SEMICOLON) return;
      switch (peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.IF:
        case TokenType.PRINT:
        case TokenType.RETURN:
        case TokenType.VAR:
        case TokenType.WHILE:
          return;
      }
      advance();
    }
  }

  bool match(List<TokenType> types) {
    for (var type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) current++;
    return previous();
  }

  bool isAtEnd() {
    return peek().type == TokenType.EOF;
  }

  Token peek() {
    return tokens[current];
  }

  Token previous() {
    return tokens[current - 1];
  }
}
