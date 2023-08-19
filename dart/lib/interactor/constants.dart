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

class interactorDirectories {
  const interactorDirectories._();

  static const native = "/native";
  static const package = "/package";
  static const dotDartTool = ".dart_tool";
}

class interactorPackageConfigFields {
  interactorPackageConfigFields._();

  static const rootUri = 'rootUri';
  static const name = 'name';
  static const packages = 'packages';
}

const interactorBufferUsed = -1;

const interactorEventRead = 1 << 0;
const interactorEventWrite = 1 << 1;
const interactorEventReceiveMessage = 1 << 2;
const interactorEventSendMessage = 1 << 3;
const interactorEventAccept = 1 << 4;
const interactorEventConnect = 1 << 5;
const interactorEventClient = 1 << 6;
const interactorEventFile = 1 << 7;
const interactorEventServer = 1 << 8;

const interactorEventAll = interactorEventRead |
    interactorEventWrite |
    interactorEventAccept |
    interactorEventConnect |
    interactorEventReceiveMessage |
    interactorEventSendMessage |
    interactorEventClient |
    interactorEventFile |
    interactorEventServer;

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
