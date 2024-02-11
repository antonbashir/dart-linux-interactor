#ifndef TEST_THREADING_H
#define TEST_THREADING_H

#include <interactor_native.h>
#include <pthread.h>
#include <stdbool.h>
#include "interactor_message.h"

#if defined(__cplusplus)
extern "C"
{
#endif

    struct test_thread
    {
        pthread_t id;

        volatile bool alive;

        size_t whole_messages_count;
        size_t received_messages_count;

        struct interactor_native* interactor;
        struct interactor_message** messages;

        pthread_cond_t initialize_condition;
        pthread_mutex_t initialize_mutex;
    };

    struct test_threads
    {
        struct test_thread* threads;
        size_t count;
        pthread_mutex_t global_working_mutex;
    };

    bool test_threading_initialize(int thread_count, int isolates_count, int per_thread_messages_count);
    int* test_threading_interactor_descriptors();

    void test_threading_call_native(struct interactor_message* message);
    int test_threading_call_native_check();

    void test_threading_prepare_call_dart_bytes(int32_t* targets, int32_t count);

    int test_threading_call_dart_check();
    void test_threading_call_dart_callback(struct interactor_message* message);

    void test_threading_destroy();

    intptr_t test_threading_call_native_address_lookup();

#if defined(__cplusplus)
}
#endif

#endif
