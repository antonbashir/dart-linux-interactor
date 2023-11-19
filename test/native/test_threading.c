#include "test_threading.h"
#include <stdlib.h>
#include "interactor_constants.h"
#include "interactor_message.h"
#include "interactor_native.h"
#include "test.h"

static test_threads_t threads;

static inline test_thread_t* thread_by_fd(int fd)
{
    for (int id = 0; id < threads.count; id++)
    {
        if (threads.threads[id]->interactor->ring->ring_fd == fd)
        {
            return threads.threads[id];
        }
    }
    return NULL;
}

test_threads_t* test_threading_threads()
{
  return &threads;
}

test_threads_t* test_threading_initialize(int count)
{
    threads.count = count;
    return &threads;
}

int test_threading_call_native_check()
{
    int sum = 0;
    for (int id = 0; id < threads.count; id++)
    {
        test_thread_t* thread = threads.threads[id];
        test_interactor_process_calls(thread->interactor);
        for (int message_id = 0; message_id < thread->messages_count; message_id++)
        {
            interactor_native_callback_to_dart(thread->interactor, thread->messages[message_id]);
            sum++;
        }
        interactor_native_submit(thread->interactor);
    }
    return sum;
}

void test_threading_call_native_echo(interactor_message_t* message)
{
    test_thread_t* thread = thread_by_fd(message->target);
    if (thread)
    {
        thread->messages[thread->messages_count] = message;
        thread->messages = reallocarray(thread->messages, 1, sizeof(interactor_message_t*));
        thread->messages_count++;
    }
}