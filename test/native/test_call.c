#include "test_call.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "interactor_message.h"

static struct interactor_message* current_message = NULL;

void test_call_reset()
{
    current_message = NULL;
}

bool test_call_native_check(struct interactor_native* interactor)
{
    interactor_native_process_timeout(interactor);
    interactor_native_submit(interactor);
    return current_message != NULL;
}

void test_call_native(struct interactor_message* message)
{
    message->output = message->input;
    message->output_size = message->input_size;
    current_message = message;
}

void test_call_dart_null(struct interactor_native* interactor, int32_t target, uintptr_t method)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_bool(struct interactor_native* interactor, int32_t target, uintptr_t method, bool value)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)value;
    message->input_size = sizeof(bool);
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_int(struct interactor_native* interactor, int32_t target, uintptr_t method, int value)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)(uintptr_t)value;
    message->input_size = sizeof(int);
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_double(struct interactor_native* interactor, int32_t target, uintptr_t method, double value)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)interactor_native_data_allocate(interactor, sizeof(double));
    (*(double*)message->input) = value;
    message->input_size = sizeof(double);
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_string(struct interactor_native* interactor, int32_t target, uintptr_t method, const char* value)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)interactor_native_data_allocate(interactor, strlen(value));
    strcpy(message->input, value);
    message->input_size = strlen(value);
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_object(struct interactor_native* interactor, int32_t target, uintptr_t method, int field)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)interactor_native_payload_allocate(interactor_native_payload_pool_create(interactor, sizeof(struct test_object)));
    ((struct test_object*)message->input)->field = field;
    message->input_size = sizeof(struct test_object);
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_bytes(struct interactor_native* interactor, int32_t target, uintptr_t method, const uint8_t* value, size_t count)
{
    struct interactor_message* message = interactor_native_allocate_message(interactor);
    message->id = 0;
    message->input = (void*)(intptr_t)interactor_native_data_allocate(interactor, count);
    memcpy(message->input, value, count);
    message->input_size = count;
    message->source = interactor->descriptor;
    message->owner = 0;
    message->method = method;
    interactor_native_call_dart(interactor, target, message);
    interactor_native_submit(interactor);
}

void test_call_dart_callback(struct interactor_message* message)
{
    message->output = message->input;
    message->output_size = message->input_size;
    current_message = message;
}

struct interactor_message* test_call_dart_check(struct interactor_native* interactor)
{
    interactor_native_register_callback(interactor, 0, 0, test_call_dart_callback);
    interactor_native_process_timeout(interactor);
    interactor_native_submit(interactor);
    return current_message;
}

intptr_t test_call_native_address_lookup() {
  return (intptr_t)&test_call_native;
}