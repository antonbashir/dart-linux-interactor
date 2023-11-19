#include "test_threading.h"
#include <pthread.h>
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

static void* thread_function(void* thread)
{
    test_thread_t* casted = (test_thread_t*)thread;
    casted->interactor = test_interactor_initialize();
    casted->alive = true;
    while (casted->alive)
    {
        pthread_mutex_lock(&casted->shutdown_mutex);
        pthread_cond_wait(&casted->shutdown_condition, &casted->shutdown_mutex);
        pthread_mutex_unlock(&casted->shutdown_mutex);
    }
    test_interactor_destroy(casted->interactor);
    return NULL;
}

test_threads_t* test_threading_threads()
{
    return &threads;
}

test_threads_t* test_threading_initialize(int thread_count, int messages_count)
{
    threads.count = thread_count;
    threads.threads = malloc(thread_count * sizeof(test_thread_t*));
    for (int threadId = 0; threadId < thread_count; threadId++)
    {
        threads.threads[threadId] = malloc(sizeof(test_thread_t));
        threads.threads[threadId]->messages_count = messages_count;
        threads.threads[threadId]->received_messages_count = 0;
        threads.threads[threadId]->messages = malloc(messages_count * sizeof(interactor_message_t*));
        pthread_mutex_init(&threads.threads[threadId]->shutdown_mutex, NULL);
        pthread_cond_init(&threads.threads[threadId]->shutdown_condition, NULL);
        pthread_t thread;
        pthread_create(&thread, NULL, thread_function, threads.threads[threadId]);
        while (!threads.threads[threadId]->alive)
        {
        }
    }

    return &threads;
}

int test_threading_call_native_check()
{
    int sum = 0;
    for (int id = 0; id < threads.count; id++)
    {
        test_thread_t* thread = threads.threads[id];
        test_interactor_process_calls(thread->interactor);
        for (int message_id = 0; message_id < thread->received_messages_count; message_id++)
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
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
}

void test_threading_destroy()
{
    for (int thread_id = 0; thread_id < threads.count; thread_id++)
    {
        threads.threads[thread_id]->alive = false;
        pthread_mutex_lock(&threads.threads[thread_id]->shutdown_mutex);
        pthread_cond_signal(&threads.threads[thread_id]->shutdown_condition);
        pthread_mutex_unlock(&threads.threads[thread_id]->shutdown_mutex);
        while (threads.threads[thread_id]->alive)
        {
        }
    }
}