import 'dart:io';

void main(List<String> args) {
  Runner.init(args);
}

class Runner {
  static bool hadError = false;

  static void init(args) {
    if (args.length > 1) {
      print("Usage: darx [script]");
      exit(64);
    } else if (args.length == 1) {
      runFile(args[0]);
    } else {
      runPrompt();
    }
  }

  static void runFile(String path) {
    try {
      File(path).readAsString().then((String contents) {
        print(contents);
      });
    } catch (e) {
      print(e);
    }
  }

  static void runPrompt() {
    print("Welcome to Darx!");
    while (true) {
      print("> ");
      String? line = stdin.readLineSync();
      if (line == null) break;
      print(line);
    }
  }

  run() {}

  static void error(int line, String message) {
    report(line, "", message);
  }

  static void report(int line, String where, String message) {
    print("[line $line] Error$where: $message");
    hadError = true;
  }
}
