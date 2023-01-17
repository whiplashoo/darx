import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    print("Usage: generate_ast <output directory>");
    exit(64);
  }
  String outputDir = args[0];

  defineAst(outputDir, "Expr", [
    "Assign   : Token name, Expr value",
    "Binary   : Expr left, Token operator, Expr right",
    "Call     : Expr callee, Token paren, List<Expr> arguments",
    "Grouping : Expr expression",
    "Literal  : Object? value",
    "Logical  : Expr left, Token operator, Expr right",
    "Variable : Token name",
    "Unary    : Token operator, Expr right"
  ]);

  defineAst(outputDir, "Stmt", [
    "Block         : List<Stmt> statements",
    "Class         : Token name, List<Func>? methods",
    "Expression    : Expr expression",
    "Func      : Token name, List<Token> params, List<Stmt> body",
    "If            : Expr condition, Stmt thenBranch, Stmt? elseBranch",
    "Var           : Token name, Expr? initializer",
    "Print         : Expr expression",
    "Return        : Token keyword, Expr? value",
    "While         : Expr condition, Stmt body",
    "Break         : Token keyword",
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  String path = "$outputDir/${baseName.toLowerCase()}.dart";
  File file = File(path);
  IOSink sink = file.openWrite();

  if (baseName == "Stmt") {
    sink.write("import 'expr.dart';\n");
  }
  sink.write("import 'token.dart';\n");
  sink.write("abstract class $baseName {\n");
  if (baseName == "Stmt") {
    sink.write("  void accept(StmtVisitor visitor);\n");
  } else {
    sink.write("  T accept<T>(ExprVisitor<T> visitor);\n");
  }
  sink.write("}\n");

  defineVisitor(sink, baseName, types);

  for (String type in types) {
    String className = type.split(":")[0].trim();
    String fields = type.split(":")[1].trim();
    defineType(sink, baseName, className, fields);
  }

  sink.close();
}

void defineType(
    IOSink sink, String baseName, String className, String fieldList) {
  sink.write("class $className extends $baseName {\n");

  // Constructor.
  var thisFields = fieldList.split(", ").map((field) {
    return "this.${field.split(" ")[1]}";
  }).join(", ");
  sink.write("    $className($thisFields);\n");

  // Visitor pattern.
  sink.write("\n");
  sink.write("  @override\n");
  if (baseName == "Stmt") {
    sink.write(
        "  void accept(StmtVisitor visitor) => visitor.visit$className$baseName(this);\n");
  } else {
    sink.write(
        "  T accept<T>(ExprVisitor<T> visitor) => visitor.visit$className$baseName(this);\n");
  }
  sink.write("\n");

  // Fields.
  List<String> fields = fieldList.split(", ");
  for (String field in fields) {
    sink.write("  final ${field.split(" ")[0]} ${field.split(" ")[1]};\n");
  }

  sink.write("  }\n");
}

void defineVisitor(IOSink sink, String baseName, List<String> types) {
  if (baseName == "Stmt") {
    sink.write("abstract class StmtVisitor {\n");
  } else {
    sink.write("abstract class ExprVisitor<T> {\n");
  }

  for (String type in types) {
    String typeName = type.split(":")[0].trim();
    if (baseName == "Stmt") {
      sink.write(
          "  void visit$typeName$baseName($typeName ${baseName.toLowerCase()});\n");
    } else {
      sink.write(
          "  T visit$typeName$baseName($typeName ${baseName.toLowerCase()});\n");
    }
  }
  sink.write("}\n");
}
