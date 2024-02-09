import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'constants.dart';
import 'lookup.dart';
import 'system.dart';

class InteractorNativeModule {
  final String name;
  final String path;
  final Pointer<Void> _handle;

  InteractorNativeModule._(this.name, this.path) : _handle = using((Arena arena) => dlopen(path.toNativeUtf8(allocator: arena).cast(), rtldGlobal | rtldLazy));

  factory InteractorNativeModule.loadByPath(String library) => InteractorNativeModule._(library, library);

  factory InteractorNativeModule.loadByName(String name, {String relativeDirectory = nativeDirectory}) {
    name = name + dot + soFileExtension;
    try {
      return InteractorNativeModule._(Directory.current.path + slash + name, Directory.current.path + slash + name);
    } on ArgumentError {
      final projectRoot = findProjectRoot();
      if (projectRoot == null) throw UnsupportedError(Directory.current.path + slash + name);
      final libraryFile = File(projectRoot + relativeDirectory + slash + name);
      if (libraryFile.existsSync()) {
        return InteractorNativeModule._(name, libraryFile.path);
      }
      throw UnsupportedError(loadError(libraryFile.absolute.path));
    }
  }

  void unload() => dlclose(_handle);

  InteractorNativeModule reload() {
    unload();
    return InteractorNativeModule.loadByPath(path);
  }
}
