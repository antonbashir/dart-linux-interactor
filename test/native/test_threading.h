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
        volatile bool alive;
        interactor_native_t* interactor;
        interactor_message_t** messages;
        size_t messages_count;
        size_t received_messages_count;
        pthread_cond_t shutdown_condition;
        pthread_mutex_t shutdown_mutex;
    } test_thread_t;

    typedef struct test_threads
    {
        test_thread_t** threads;
        size_t count;
    } test_threads_t;

    test_threads_t* test_threading_initialize(int thread_count, int messages_count);
    test_threads_t* test_threading_threads();
    void test_threading_call_native_echo(interactor_message_t* message);
    int test_threading_call_native_check();
    void test_threading_destroy();

#if defined(__cplusplus)
}
#endif

#endif
