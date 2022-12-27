import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    print("Usage: generate_ast <output directory>");
    exit(64);
  }
  String outputDir = args[0];
  defineAst(outputDir, "Expr", [
    "Binary   : Expr left, Token operator, Expr right",
    "Grouping : Expr expression",
    "Literal  : Object? value",
    "Unary    : Token operator, Expr right"
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  String path = "$outputDir/${baseName.toLowerCase()}.dart";
  File file = File(path);
  IOSink sink = file.openWrite();

  sink.write("import 'token.dart';\n");
  sink.write("abstract class $baseName {\n");
  sink.write("  T accept<T>(Visitor<T> visitor);\n");
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
  sink.write(
      "  T accept<T>(Visitor<T> visitor) => visitor.visit$className$baseName(this);\n");
  sink.write("\n");

  // Fields.
  List<String> fields = fieldList.split(", ");
  for (String field in fields) {
    sink.write("  final ${field.split(" ")[0]} ${field.split(" ")[1]};\n");
  }

  sink.write("  }\n");
}

void defineVisitor(IOSink sink, String baseName, List<String> types) {
  sink.write("abstract class Visitor<T> {\n");
  for (String type in types) {
    String typeName = type.split(":")[0].trim();
    sink.write(
        "  T visit$typeName$baseName($typeName ${baseName.toLowerCase()});\n");
  }
  sink.write("}\n");
}
