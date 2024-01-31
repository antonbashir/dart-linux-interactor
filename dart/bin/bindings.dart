import 'dart:io';

void main() {
  final result = Process.runSync("dart", ["run", "ffigen"]);
  if (result.exitCode != 0) {
    throw Exception("dart run ffigen");
  }
  print(result.stdout);
  print(result.stderr);
  final file = File("lib/interactor/bindings.dart");
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "external ffi.Pointer<small_mempool> small_mempool",
    "external ffi.Pointer<small_mempool> small_mempool_",
  );
  content = content.replaceAll(
    "external ffi.Pointer<mempool> mempool",
    "// external ffi.Pointer<mempool> mempool_",
  );
  content = content.replaceAll(
    "external ffi.Pointer<quota> quota",
    "// external ffi.Pointer<quota> quota_",
  );
  content = content.replaceAll(
    "final class io_uring_cqe extends ffi.Opaque {}",
    "final class io_uring_cqe extends ffi.Struct {@ffi.UnsignedLongLong()external int user_data; @ffi.Int() external int res; @ffi.UnsignedInt()external int flags;}",
  );
  content = content.replaceAll(
    "// ignore_for_file: type=lint",
    "// ignore_for_file: type=lint, unused_field",
  );
  file.writeAsStringSync(content);
}
