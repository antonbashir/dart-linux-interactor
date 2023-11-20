#include "test_threading.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "interactor_constants.h"
#include "interactor_message.h"
#include "interactor_native.h"
#include "test.h"

static test_threads_t threads;

static inline test_thread_t* test_threading_thread_by_fd(int fd)
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

static void* test_threading_run(void* thread)
{
    test_thread_t* casted = (test_thread_t*)thread;
    casted->interactor = test_interactor_initialize();
    casted->alive = true;
    interactor_native_register_callback(casted->interactor, 0, 0, test_threading_call_dart_callback);
    while (casted->alive)
    {
        interactor_native_process_timeout(casted->interactor);
    }
    test_interactor_destroy(casted->interactor);
    return NULL;
}

test_threads_t* test_threading_threads()
{
    return &threads;
}

void test_threading_initialize(int thread_count, int messages_count)
{
    threads.count = thread_count;
    threads.threads = malloc(thread_count * sizeof(test_thread_t*));
    for (int threadId = 0; threadId < thread_count; threadId++)
    {
        threads.threads[threadId] = malloc(sizeof(test_thread_t));
        threads.threads[threadId]->messages_count = messages_count;
        threads.threads[threadId]->received_messages_count = 0;
        threads.threads[threadId]->messages = malloc(messages_count * sizeof(interactor_message_t*));
        pthread_t thread;
        pthread_create(&thread, NULL, test_threading_run, threads.threads[threadId]);
        while (!threads.threads[threadId]->alive)
        {
        }
    }
}

int test_threading_call_native_check()
{
    int messages = 0;
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id]->received_messages_count;
    }
    return messages;
}

void test_threading_call_native(interactor_message_t* message)
{
    test_thread_t* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
}

void test_threading_call_dart_bytes(int32_t target, uintptr_t method, const uint8_t* value, size_t count)
{
    for (int id = 0; id < threads.count; id++)
    {
        test_thread_t* thread = threads.threads[id];
        interactor_message_t* message = interactor_native_allocate_message(thread->interactor);
        message->id = 0;
        message->input = (void*)(intptr_t)interactor_native_data_allocate(thread->interactor, count);
        memcpy(message->input, value, count);
        message->input_size = count;
        message->owner = 0;
        message->method = method;
        interactor_native_call_dart(thread->interactor, target, message, -1);
        interactor_native_submit(thread->interactor);
    }
}

void test_threading_call_dart_callback(interactor_message_t* message)
{
    test_thread_t* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
}

int test_threading_call_dart_check()
{
    int messages = 0;
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id]->received_messages_count;
    }
    return messages;
}

void test_threading_destroy()
{
    for (int thread_id = 0; thread_id < threads.count; thread_id++)
    {
        threads.threads[thread_id]->alive = false;
        while (threads.threads[thread_id]->alive)
        {
        }
    }
}