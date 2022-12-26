import 'runtime_error.dart';
import 'token.dart';
import 'token_type.dart';

class Scanner {
  final String source;
  final List<Token> tokens = [];
  int start = 0;
  int current = 0;
  int line = 1;

  Scanner(this.source);

  static Map<String, TokenType> keywords = {
    "and": TokenType.AND,
    "class": TokenType.CLASS,
    "else": TokenType.ELSE,
    "false": TokenType.FALSE,
    "for": TokenType.FOR,
    "fun": TokenType.FUN,
    "if": TokenType.IF,
    "nil": TokenType.NIL,
    "or": TokenType.OR,
    "print": TokenType.PRINT,
    "return": TokenType.RETURN,
    "super": TokenType.SUPER,
    "this": TokenType.THIS,
    "true": TokenType.TRUE,
    "var": TokenType.VAR,
    "while": TokenType.WHILE,
  };

  List<Token> scanTokens() {
    while (!isAtEnd()) {
      // We are at the beginning of the next lexeme.
      start = current;
      scanToken();
    }

    tokens.add(Token(TokenType.EOF, "", null, line));
    return tokens;
  }

  void scanToken() {
    var c = advance();
    switch (c) {
      case "(":
        addToken(TokenType.LEFT_PAREN);
        break;
      case ')':
        addToken(TokenType.RIGHT_PAREN);
        break;
      case '{':
        addToken(TokenType.LEFT_BRACE);
        break;
      case '}':
        addToken(TokenType.RIGHT_BRACE);
        break;
      case ',':
        addToken(TokenType.COMMA);
        break;
      case '.':
        addToken(TokenType.DOT);
        break;
      case '-':
        addToken(TokenType.MINUS);
        break;
      case '+':
        addToken(TokenType.PLUS);
        break;
      case ';':
        addToken(TokenType.SEMICOLON);
        break;
      case '*':
        addToken(TokenType.STAR);
        break;
      case '!':
        addToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        addToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '>':
        addToken(match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case '<':
        addToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '/':
        if (match('/')) {
          // A comment goes until the end of the line.
          while (peek() != '\n' && !isAtEnd()) {
            advance();
          }
        } else if (match('*')) {
          while (!isAtEnd()) {
            if (peek() == '\n') line++;
            if (peek() == '*' && peekNext() == '/') {
              advance();
              break;
            }
            advance();
            if (isAtEnd()) {
              throw RuntimeError(
                Token(TokenType.SLASH, c, null, line),
                "Unterminated block comment.",
              );
            }
          }
        } else {
          addToken(TokenType.SLASH);
        }
        break;
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;
      case '\n':
        line++;
        break;
      case '"':
        string();
        break;
      default:
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          identifier();
        } else {
          throw RuntimeError(
            Token(TokenType.IDENTIFIER, c, null, line),
            'Unexpected character.',
          );
        }
        break;
    }
  }

  void string() {
    while (peek() != '"' && !isAtEnd()) {
      if (peek() == '\n') line++;
      advance();
    }

    if (isAtEnd()) {
      return;
    }
    advance();

    // Trim the surrounding quotes.
    var value = source.substring(start + 1, current - 1);
    addTokenLiteral(TokenType.STRING, value);
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }

    var text = source.substring(start, current);
    var type = keywords[text] ?? TokenType.IDENTIFIER;
    addToken(type);
  }

  void number() {
    while (isDigit(peek())) {
      advance();
    }
    if (peek() == '.' && isDigit(peekNext())) {
      advance();
      while (isDigit(peek())) {
        advance();
      }
    }

    addTokenLiteral(
        TokenType.NUMBER, double.parse(source.substring(start, current)));
  }

  String peek() {
    if (isAtEnd()) return '\x00';
    return source[current];
  }

  String peekNext() {
    if (current + 1 >= source.length) return '\x00';
    return source[current + 1];
  }

  bool isAtEnd() {
    return current >= source.length;
  }

  String advance() {
    current++;
    return source[current - 1];
  }

  bool match(String expected) {
    if (isAtEnd()) return false;
    if (source[current] != expected) return false;

    current++;
    return true;
  }

  void addToken(TokenType type) {
    addTokenLiteral(type, null);
  }

  bool isDigit(String c) {
    return c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }

  bool isAlpha(String c) {
    return (c.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
            c.codeUnitAt(0) <= 'z'.codeUnitAt(0)) ||
        (c.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
            c.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) ||
        c == '_';
  }

  bool isAlphaNumeric(String c) {
    return isAlpha(c) || isDigit(c);
  }

  void addTokenLiteral(TokenType type, Object? literal) {
    var text = source.substring(start, current);
    tokens.add(Token(type, text, literal, line));
  }
}
