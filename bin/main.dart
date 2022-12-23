import 'dart:io';

import 'package:darx/scanner.dart';
import 'package:darx/token.dart';

void main(List<String> args) {
  Runner().init(args);
}

class Runner {
  bool hadError = false;

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

    // For now, just print the tokens.
    for (Token token in tokens) {
      print(token);
    }
  }

  void error(int line, String message) {
    report(line, "", message);
  }

  void report(int line, String where, String message) {
    print("[line $line] Error$where: $message");
    hadError = true;
  }
}
