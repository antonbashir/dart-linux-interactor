// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint, unused_field
import 'dart:ffi' as ffi;
import 'package:linux_interactor/interactor/bindings.dart' as linux_interactor;

@ffi.Native<ffi.Pointer<test_interactor_native> Function()>(
    symbol: 'test_interactor_initialize',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external ffi.Pointer<test_interactor_native> test_interactor_initialize();

@ffi.Native<ffi.Int Function(ffi.Pointer<test_interactor_native>)>(
    symbol: 'test_interactor_descriptor',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external int test_interactor_descriptor(
  ffi.Pointer<test_interactor_native> interactor,
);

@ffi.Native<ffi.Void Function(ffi.Pointer<test_interactor_native>)>(
    symbol: 'test_interactor_destroy',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_interactor_destroy(
  ffi.Pointer<test_interactor_native> interactor,
);

@ffi.Native<ffi.Void Function()>(
    symbol: 'test_call_reset',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_reset();

@ffi.Native<ffi.Bool Function(ffi.Pointer<test_interactor_native>)>(
    symbol: 'test_call_native_check',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external bool test_call_native_check(
  ffi.Pointer<test_interactor_native> interactor,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<linux_interactor.interactor_message>)>(
    symbol: 'test_call_native',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_native(
  ffi.Pointer<linux_interactor.interactor_message> message,
);

@ffi.Native<
        ffi.Void Function(
            ffi.Pointer<test_interactor_native>, ffi.Int32, ffi.UintPtr)>(
    symbol: 'test_call_dart_null',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_null(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Bool)>(
    symbol: 'test_call_dart_bool',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_bool(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  bool value,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Int)>(
    symbol: 'test_call_dart_int',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_int(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  int value,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Double)>(
    symbol: 'test_call_dart_double',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_double(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  double value,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Pointer<ffi.Char>)>(
    symbol: 'test_call_dart_string',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_string(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  ffi.Pointer<ffi.Char> value,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Int)>(
    symbol: 'test_call_dart_object',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_object(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  int field,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<test_interactor_native>, ffi.Int32,
            ffi.UintPtr, ffi.Pointer<ffi.Uint8>, ffi.Size)>(
    symbol: 'test_call_dart_bytes',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_bytes(
  ffi.Pointer<test_interactor_native> interactor,
  int target,
  int method,
  ffi.Pointer<ffi.Uint8> value,
  int count,
);

@ffi.Native<
        ffi.Pointer<linux_interactor.interactor_message> Function(
            ffi.Pointer<test_interactor_native>)>(
    symbol: 'test_call_dart_check',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external ffi.Pointer<linux_interactor.interactor_message> test_call_dart_check(
  ffi.Pointer<test_interactor_native> interactor,
);

@ffi.Native<
        ffi.Void Function(ffi.Pointer<linux_interactor.interactor_message>)>(
    symbol: 'test_call_dart_callback',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_call_dart_callback(
  ffi.Pointer<linux_interactor.interactor_message> message,
);

@ffi.Native<ffi.IntPtr Function()>(
    symbol: 'test_call_native_address_lookup',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external int test_call_native_address_lookup();

@ffi.Native<ffi.Bool Function(ffi.Int, ffi.Int, ffi.Int)>(
    symbol: 'test_threading_initialize',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external bool test_threading_initialize(
  int thread_count,
  int isolates_count,
  int per_thread_messages_count,
);

@ffi.Native<ffi.Pointer<ffi.Int> Function()>(
    symbol: 'test_threading_interactor_descriptors',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external ffi.Pointer<ffi.Int> test_threading_interactor_descriptors();

@ffi.Native<
        ffi.Void Function(ffi.Pointer<linux_interactor.interactor_message>)>(
    symbol: 'test_threading_call_native',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_threading_call_native(
  ffi.Pointer<linux_interactor.interactor_message> message,
);

@ffi.Native<ffi.Int Function()>(
    symbol: 'test_threading_call_native_check',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external int test_threading_call_native_check();

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Int32>, ffi.Int32)>(
    symbol: 'test_threading_prepare_call_dart_bytes',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_threading_prepare_call_dart_bytes(
  ffi.Pointer<ffi.Int32> targets,
  int count,
);

@ffi.Native<ffi.Int Function()>(
    symbol: 'test_threading_call_dart_check',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external int test_threading_call_dart_check();

@ffi.Native<
        ffi.Void Function(ffi.Pointer<linux_interactor.interactor_message>)>(
    symbol: 'test_threading_call_dart_callback',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_threading_call_dart_callback(
  ffi.Pointer<linux_interactor.interactor_message> message,
);

@ffi.Native<ffi.Void Function()>(
    symbol: 'test_threading_destroy',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external void test_threading_destroy();

@ffi.Native<ffi.IntPtr Function()>(
    symbol: 'test_threading_call_native_address_lookup',
    assetId: 'interactor-bindings-test',
    isLeaf: true)
external int test_threading_call_native_address_lookup();

final class interactor_native extends ffi.Opaque {}

typedef test_interactor_native = interactor_native;

final class max_align_t extends ffi.Opaque {}

final class __fsid_t extends ffi.Struct {
  @ffi.Array.multi([2])
  external ffi.Array<ffi.Int> __val;
}

final class interactor_completion_event extends ffi.Struct {
  @ffi.UnsignedLongLong()
  external int user_data;

  @ffi.Int()
  external int res;

  @ffi.UnsignedInt()
  external int flags;

  @ffi.Array.multi([2])
  external ffi.Array<ffi.UnsignedLongLong> big_cqe;
}

final class test_object_child extends ffi.Struct {
  @ffi.Int()
  external int field;
}

final class test_object extends ffi.Struct {
  @ffi.Int()
  external int field;

  external test_object_child child_field;
}

final class pthread_cond_t extends ffi.Opaque {}

final class pthread_mutex_t extends ffi.Opaque {}

final class test_thread extends ffi.Struct {
  @pthread_t()
  external int id;

  @ffi.Bool()
  external bool alive;

  @ffi.Size()
  external int whole_messages_count;

  @ffi.Size()
  external int received_messages_count;

  external ffi.Pointer<test_interactor_native> interactor;

  external ffi.Pointer<ffi.Pointer<linux_interactor.interactor_message>>
      messages;

  external ffi.Pointer<test_cond_t> initialize_condition;

  external ffi.Pointer<test_mutex_t> initialize_mutex;
}

typedef pthread_t = ffi.UnsignedLong;
typedef Dartpthread_t = int;
typedef test_cond_t = pthread_cond_t;
typedef test_mutex_t = pthread_mutex_t;

final class test_threads extends ffi.Struct {
  external ffi.Pointer<test_thread> threads;

  @ffi.Size()
  external int count;

  external ffi.Pointer<test_mutex_t> global_working_mutex;
}
