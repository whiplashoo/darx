import 'dart:io';

import 'package:darx/interpreter.dart';
import 'package:darx/parser.dart';
import 'package:darx/resolver.dart';
import 'package:darx/runtime_error.dart';
import 'package:darx/scanner.dart';
import 'package:darx/stmt.dart';
import 'package:darx/token.dart';

void main(List<String> args) {
  Runner().init(args);
}

class Runner {
  bool hadError = false;
  bool hadRuntimeError = false;
  Interpreter interpreter = Interpreter();

  void init(args) {
    if (args.length > 1) {
      print("Usage: darx [script]");
      exit(64);
    } else if (args.length == 1) {
      runFile(args[0]);
    } else {
      runPrompt();
    }
  }

  void runFile(String path) {
    try {
      File(path).readAsString().then((String contents) {
        run(contents);
      });
    } catch (e) {
      print(e);
    }
  }

  void runPrompt() {
    print("Welcome to Darx!");
    while (true) {
      print("> ");
      String? line = stdin.readLineSync();
      if (line == null) break;
      run(line);
    }
  }

  void run(String source) {
    Scanner scanner = Scanner(source);
    List<Token> tokens = scanner.scanTokens();
    Parser parser = Parser(tokens);
    List<Stmt> statements = parser.parse();

    if (hadError) exit(65);
    Resolver resolver = Resolver(interpreter);
    resolver.resolve(statements);
    if (hadError) exit(65);
    interpreter.interpret(statements);
    if (hadRuntimeError) exit(70);
  }

  void runtimeError(RuntimeError error) {
    print("${error.message} \n at line: ${error.token.line}");
    hadRuntimeError = true;
  }

  void report(int line, String where, String message) {
    print("[line $line] Error$where: $message");
    hadError = true;
  }
}
