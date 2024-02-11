#ifndef TEST_CALL_H
#define TEST_CALL_H

#include <interactor_native.h>
#include <stdbool.h>

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

    bool test_call_native_check(struct interactor_native* interactor);
    void test_call_native(struct interactor_message* message);

    void test_call_dart_null(struct interactor_native* interactor, int32_t target, uintptr_t method);
    void test_call_dart_bool(struct interactor_native* interactor, int32_t target, uintptr_t method, bool value);
    void test_call_dart_int(struct interactor_native* interactor, int32_t target, uintptr_t method, int value);
    void test_call_dart_double(struct interactor_native* interactor, int32_t target, uintptr_t method, double value);
    void test_call_dart_string(struct interactor_native* interactor, int32_t target, uintptr_t method, const char* value);
    void test_call_dart_object(struct interactor_native* interactor, int32_t target, uintptr_t method, int field);
    void test_call_dart_bytes(struct interactor_native* interactor, int32_t target, uintptr_t method, const uint8_t* value, size_t count);
    struct interactor_message* test_call_dart_check(struct interactor_native* interactor);
    void test_call_dart_callback(struct interactor_message* message);

    intptr_t test_call_native_address_lookup();

#if defined(__cplusplus)
}
#endif

#endif
