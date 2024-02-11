import 'dart:io';

void main() {
  final result = Process.runSync("dart", ["run", "ffigen"]);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw Exception("dart run ffigen");
  }
  final file = File("lib/interactor/bindings.dart");
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "// ignore_for_file: type=lint",
    "// ignore_for_file: type=lint, unused_field",
  );
  file.writeAsStringSync(content);
}
