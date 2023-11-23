#ifndef TEST_THREADING_H
#define TEST_THREADING_H

#include <interactor_native.h>
#include <pthread.h>
#include "interactor_message.h"

#if defined(__cplusplus)
extern "C"
{
#endif

    typedef struct test_thread
    {
        pthread_t id;

        volatile bool alive;

        size_t whole_messages_count;
        size_t received_messages_count;

        interactor_native_t* interactor;
        interactor_message_t** messages;

        pthread_cond_t initialize_condition;
        pthread_mutex_t initialize_mutex;
    } test_thread_t;

    typedef struct test_threads
    {
        test_thread_t* threads;
        size_t count;
        pthread_mutex_t global_working_mutex;
    } test_threads_t;

    bool test_threading_initialize(int thread_count, int isolates_count, int per_thread_messages_count);
    int* test_threading_interactor_descriptors();

    void test_threading_call_native(interactor_message_t* message);
    int test_threading_call_native_check();

    void test_threading_prepare_call_dart_bytes(int32_t* targets, int32_t count);

    int test_threading_call_dart_check();
    void test_threading_call_dart_callback(interactor_message_t* message);

    void test_threading_destroy();

#if defined(__cplusplus)
}
#endif

#endif
