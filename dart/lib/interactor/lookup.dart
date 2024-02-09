import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform, Directory, File;

import 'package:ffi/ffi.dart';

import 'constants.dart';
import 'system.dart';

class InteractorLibrary {
  final DynamicLibrary library;
  final String path;

  InteractorLibrary(this.library, this.path) {
    using((Arena arena) => dlopen(path.toNativeUtf8(allocator: arena).cast(), rtldGlobal | rtldLazy));
  }

  factory InteractorLibrary.load({String? libraryPath}) => libraryPath != null
      ? File(libraryPath).existsSync()
          ? InteractorLibrary(DynamicLibrary.open(libraryPath), libraryPath)
          : _load()
      : _load();
}

InteractorLibrary _load() {
  try {
    return InteractorLibrary(
      Platform.isLinux ? DynamicLibrary.open(interactorLibraryName) : throw UnsupportedError(Directory.current.path + slash + interactorLibraryName),
      Directory.current.path + slash + interactorLibraryName,
    );
  } on ArgumentError {
    final dotDartTool = findDotDartTool();
    if (dotDartTool != null) {
      final packageNativeRoot = Directory(findPackageRoot(dotDartTool).toFilePath() + InteractorDirectories.native);
      final libraryFile = File(packageNativeRoot.path + slash + interactorLibraryName);
      if (libraryFile.existsSync()) {
        return InteractorLibrary(DynamicLibrary.open(libraryFile.path), libraryFile.path);
      }
      throw UnsupportedError(loadError(libraryFile.path));
    }
    throw UnsupportedError(unableToFindProjectRoot);
  }
}

Uri? findDotDartTool() {
  Uri root = Platform.script.resolve(currentDirectorySymbol);

  do {
    if (File.fromUri(root.resolve(InteractorDirectories.dotDartTool + slash + packageConfigJsonFile)).existsSync()) {
      return root.resolve(InteractorDirectories.dotDartTool + slash);
    }
  } while (root != (root = root.resolve(parentDirectorySymbol)));

  root = Directory.current.uri;

  do {
    if (File.fromUri(root.resolve(InteractorDirectories.dotDartTool + slash + packageConfigJsonFile)).existsSync()) {
      return root.resolve(InteractorDirectories.dotDartTool + slash);
    }
  } while (root != (root = root.resolve(parentDirectorySymbol)));

  return null;
}

Uri findPackageRoot(Uri dotDartTool) {
  final packageConfigFile = File.fromUri(dotDartTool.resolve(packageConfigJsonFile));
  dynamic packageConfig;
  try {
    packageConfig = json.decode(packageConfigFile.readAsStringSync());
  } catch (ignore) {
    throw UnsupportedError(unableToFindProjectRoot);
  }
  final package = (packageConfig[InteractorPackageConfigFields.packages] ?? []).firstWhere(
    (element) => element[InteractorPackageConfigFields.name] == interactorPackageName,
    orElse: () => throw UnsupportedError(unableToFindProjectRoot),
  );
  return packageConfigFile.uri.resolve(package[InteractorPackageConfigFields.rootUri] ?? empty);
}

String? findProjectRoot() {
  var directory = Directory.current.path;
  while (true) {
    if (File(directory + slash + pubspecYamlFile).existsSync() || File(directory + slash + pubspecYmlFile).existsSync()) return directory;
    final String parent = Directory(directory).parent.path;
    if (directory == parent) return null;
    directory = parent;
  }
}
