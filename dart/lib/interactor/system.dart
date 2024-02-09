import 'dart:ffi';

const RTLD_LAZY = 0x00001;
const RTLD_GLOBAL = 0x00100;

@Native<Int Function(Pointer<Void>)>()
external int dlclose(Pointer<Void> handle);

@Native<Pointer<Void> Function(Pointer<Char>, Int)>()
external Pointer<Void> dlopen(Pointer<Char> file, int mode);
