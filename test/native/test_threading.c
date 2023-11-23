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
    pthread_mutex_lock(&threads.global_working_mutex);
    test_thread_t* thread = NULL;
    for (int id = 0; id < threads.count; id++)
    {
        if (threads.threads[id]->interactor->ring->ring_fd == fd)
        {
            thread = threads.threads[id];
            break;
        }
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
    return thread;
}

static void* test_threading_run(void* thread)
{
    test_thread_t* casted = (test_thread_t*)thread;
    casted->interactor = test_interactor_initialize();
    interactor_native_register_callback(casted->interactor, 0, 0, test_threading_call_dart_callback);
    interactor_native_process_timeout(casted->interactor);
    casted->alive = true;
    while (casted->alive)
    {
        interactor_native_process_timeout(casted->interactor);
    }
    pthread_mutex_lock(&casted->shutdown_mutex);
    test_interactor_destroy(casted->interactor);
    casted->interactor = NULL;
    pthread_cond_signal(&casted->shutdown_condition);
    pthread_mutex_unlock(&casted->shutdown_mutex);
    return NULL;
}

test_threads_t* test_threading_threads()
{
    return &threads;
}

void test_threading_initialize(int thread_count, int isolates_count, int pre_thread_messages_count)
{
    threads.count = thread_count;
    threads.threads = malloc(thread_count * sizeof(test_thread_t*));
    pthread_mutexattr_t attributes;
    pthread_mutexattr_init(&attributes);
    pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&threads.global_working_mutex, &attributes);
    for (int threadId = 0; threadId < thread_count; threadId++)
    {
        threads.threads[threadId] = malloc(sizeof(test_thread_t));
        threads.threads[threadId]->whole_messages_count = pre_thread_messages_count;
        threads.threads[threadId]->received_messages_count = 0;
        threads.threads[threadId]->messages = malloc(pre_thread_messages_count * sizeof(interactor_message_t*));
        pthread_mutex_init(&threads.threads[threadId]->shutdown_mutex, NULL);
        pthread_cond_init(&threads.threads[threadId]->shutdown_condition, NULL);

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
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id]->received_messages_count;
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
    return messages;
}

int test_threading_call_dart_check()
{
    int messages = 0;
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id]->received_messages_count;
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
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

void test_threading_prepare_call_dart_bytes(int32_t* targets, int32_t count)
{
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        test_thread_t* thread = threads.threads[id];
        for (int32_t target = 0; target < count; target++)
        {
            interactor_message_t* message = interactor_native_allocate_message(thread->interactor);
            message->id = 0;
            message->input = (void*)(intptr_t)interactor_native_data_allocate(thread->interactor, 3);
            ((char*)message->input)[0] = 0x1;
            ((char*)message->input)[1] = 0x2;
            ((char*)message->input)[2] = 0x3;
            message->input_size = 3;
            message->owner = 0;
            message->method = 0;
            interactor_native_call_dart(thread->interactor, target, message);
        }
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
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

void test_threading_destroy()
{
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int thread_id = 0; thread_id < threads.count; thread_id++)
    {
        threads.threads[thread_id]->alive = false;
        pthread_mutex_lock(&threads.threads[thread_id]->shutdown_mutex);
        pthread_cond_wait(&threads.threads[thread_id]->shutdown_condition, &threads.threads[thread_id]->shutdown_mutex);
        pthread_mutex_unlock(&threads.threads[thread_id]->shutdown_mutex);
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
}