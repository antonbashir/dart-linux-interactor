#ifndef TEST_CALL_H
#define TEST_CALL_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct test_object_child
    {
        int field;
    };

    struct test_object
    {
        int field;
        struct test_object_child child_field;
    };

    void test_call_reset();

    bool test_call_native_check(interactor_native_t* interactor);
    void test_call_native(interactor_message_t* message);

    void test_call_dart_null(interactor_native_t* interactor, int32_t target, uintptr_t method);
    void test_call_dart_bool(interactor_native_t* interactor, int32_t target, uintptr_t method, bool value);
    void test_call_dart_int(interactor_native_t* interactor, int32_t target, uintptr_t method, int value);
    void test_call_dart_double(interactor_native_t* interactor, int32_t target, uintptr_t method, double value);
    void test_call_dart_string(interactor_native_t* interactor, int32_t target, uintptr_t method, const char* value);
    void test_call_dart_object(interactor_native_t* interactor, int32_t target, uintptr_t method, int field);
    void test_call_dart_bytes(interactor_native_t* interactor, int32_t target, uintptr_t method, const uint8_t* value, size_t count);
    interactor_message_t* test_call_dart_check(interactor_native_t* interactor);
    void test_call_dart_callback(interactor_message_t* message, interactor_native_t *interactor);

#if defined(__cplusplus)
}
#endif

#endif
