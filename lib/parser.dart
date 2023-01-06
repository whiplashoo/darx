import 'package:darx/runtime_error.dart';
import 'package:darx/token_type.dart';

import 'expr.dart';
import 'stmt.dart';
import 'token.dart';

class Parser {
  final List<Token> tokens;
  int current = 0;

  Parser(this.tokens);

  List<Stmt> parse() {
    List<Stmt> statements = [];
    while (!isAtEnd()) {
      statements.add(declaration());
    }
    return statements;
  }

  Expr expression() {
    return equality();
  }

  Stmt declaration() {
    try {
      if (match([TokenType.VAR])) return varDeclaration();
      return statement();
    } on RuntimeError {
      synchronize();
      return Expression(Literal(null));
    }
  }

  Stmt statement() {
    if (match([TokenType.PRINT])) return printStatement();
    return expressionStatement();
  }

  Stmt printStatement() {
    Expr value = expression();
    consume(TokenType.SEMICOLON, 'Expect \';\' after value.');
    return Print(value);
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
    return primary();
  }

  Expr primary() {
    if (match([TokenType.FALSE])) return Literal(false);
    if (match([TokenType.TRUE])) return Literal(true);
    if (match([TokenType.NIL])) return Literal(null);

    if (match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(previous().literal!);
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
