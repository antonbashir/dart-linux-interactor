#ifndef TEST_THREADING_H
#define TEST_THREADING_H

#include <interactor_native.h>
#include "interactor_message.h"

#if defined(__cplusplus)
extern "C"
{
#endif

    typedef struct test_thread
    {
        interactor_native_t* interactor;
        interactor_message_t** messages;
        size_t messages_count;
    } test_thread_t;

    typedef struct test_threads
    {
        test_thread_t** threads;
        size_t count;
    } test_threads_t;

    test_threads_t* test_threading_initialize(int count);
    test_threads_t* test_threading_threads();
    void test_threading_call_native_echo(interactor_message_t* message);
    int test_threading_call_native_check();

#if defined(__cplusplus)
}
#endif

#endif
