import 'package:ffi/ffi.dart';

import 'bindings.dart';

const preferInlinePragma = "vm:prefer-inline";

const empty = "";
const unknown = "unknown";
const newLine = "\n";
const slash = "/";
const dot = ".";
const star = "*";
const equalSpaced = " = ";
const openingBracket = "{";
const closingBracket = "}";
const comma = ",";
const parentDirectorySymbol = '..';
const currentDirectorySymbol = './';

const interactorLibraryName = "libinteractor.so";
const interactorPackageName = "linux_interactor";

const packageConfigJsonFile = "package_config.json";

String loadError(path) => "Unable to load library ${path}";

const unableToFindProjectRoot = "Unable to find project root";

const pubspecYamlFile = 'pubspec.yaml';
const pubspecYmlFile = 'pubspec.yml';

class InteractorDirectories {
  const InteractorDirectories._();

  static const native = "/native";
  static const package = "/package";
  static const dotDartTool = ".dart_tool";
}

class InteractorPackageConfigFields {
  InteractorPackageConfigFields._();

  static const rootUri = 'rootUri';
  static const name = 'name';
  static const packages = 'packages';
}

class InteractorMessages {
  InteractorMessages._();

  static final workerMemoryError = "[worker] out of memory";
  static workerError(int result, InteractorBindings bindings) => "[worker] code = $result, message = ${_kernelErrorToString(result, bindings)}";
  static workerTrace(int id, int result, int data, int fd) => "worker = $id, result = $result,  bid = ${((data >> 16) & 0xffff)}, fd = $fd";

  static _kernelErrorToString(int error, InteractorBindings bindings) => bindings.strerror(-error).cast<Utf8>().toDartString();
}

const interactorBufferUsed = -1;

const interactorDartCallback = 1 << 0;
const interactorNativeCallback = 1 << 1;
const interactorDartCall = 1 << 2;
const interactorNativeCall = 1 << 3;

const ringSetupIopoll = 1 << 0;
const ringSetupSqpoll = 1 << 1;
const ringSetupSqAff = 1 << 2;
const ringSetupCqsize = 1 << 3;
const ringSetupClamp = 1 << 4;
const ringSetupAttachWq = 1 << 5;
const ringSetupRDisabled = 1 << 6;
const ringSetupSubmitAll = 1 << 7;
const ringSetupCoopTaskrun = 1 << 8;
const ringSetupTaskrunFlag = 1 << 9;
const ringSetupSqe128 = 1 << 10;
const ringSetupCqe32 = 1 << 11;
const ringSetupSingleIssuer = 1 << 12;
const ringSetupDeferTaskrun = 1 << 13;
