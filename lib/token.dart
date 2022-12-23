import 'dart:core';

import 'token_type.dart';

class Token {
  Token(this.type, this.lexeme, this.literal, this.line);

  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;

  @override
  String toString() {
    return "$type $lexeme $literal";
  }
}
