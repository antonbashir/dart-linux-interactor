#include "test_threading.h"
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "interactor_constants.h"
#include "interactor_message.h"
#include "interactor_native.h"
#include "test.h"

static test_threads_t threads;

test_threads_t* test_threading_threads()
{
    return &threads;
}

int* test_threading_interactor_descriptors()
{
    int* descriptors = malloc(sizeof(int) * threads.count);
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        descriptors[id] = threads.threads[id]->interactor->descriptor;
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
    return descriptors;
}

static inline test_thread_t* test_threading_thread_by_fd(int fd)
{
    test_thread_t* thread = NULL;
    for (int id = 0; id < threads.count; id++)
    {
        if (threads.threads[id]->interactor->ring->ring_fd == fd)
        {
            return threads.threads[id];
        }
    }
    return thread;
}

static void* test_threading_run(void* thread)
{
    test_thread_t* casted = (test_thread_t*)thread;
    pthread_mutex_lock(&casted->initialize_mutex);
    casted->alive = false;
    do
    {
        casted->interactor = test_interactor_initialize();
    } while (!casted->interactor || casted->interactor->descriptor <= 0);
    interactor_native_register_callback(casted->interactor, 0, 0, test_threading_call_dart_callback);
    casted->alive = true;
    pthread_cond_broadcast(&casted->initialize_condition);
    pthread_mutex_unlock(&casted->initialize_mutex);
    while (casted->alive)
    {
        interactor_native_process_timeout(casted->interactor);
    }
    test_interactor_destroy(casted->interactor);
    free(casted->messages);
    return NULL;
}

bool test_threading_initialize(int thread_count, int isolates_count, int per_thread_messages_count)
{
    threads.count = thread_count;
    threads.threads = malloc(thread_count * sizeof(test_thread_t*));
    pthread_mutex_init(&threads.global_working_mutex, NULL);
    for (int thread_id = 0; thread_id < thread_count; thread_id++)
    {
        threads.threads[thread_id] = malloc(sizeof(test_thread_t));
        threads.threads[thread_id]->whole_messages_count = per_thread_messages_count;
        threads.threads[thread_id]->received_messages_count = 0;
        threads.threads[thread_id]->messages = malloc(per_thread_messages_count * sizeof(interactor_message_t*));
        pthread_mutex_init(&threads.threads[thread_id]->initialize_mutex, NULL);
        pthread_cond_init(&threads.threads[thread_id]->initialize_condition, NULL);

        pthread_create(&threads.threads[thread_id]->id, NULL, test_threading_run, threads.threads[thread_id]);
        pthread_setname_np(threads.threads[thread_id]->id, "test_threading");

        pthread_mutex_lock(&threads.threads[thread_id]->initialize_mutex);
        while (!threads.threads[thread_id]->alive)
        {
            struct timespec timeout = {.tv_sec = 1};
            pthread_cond_timedwait(&threads.threads[thread_id]->initialize_condition, &threads.threads[thread_id]->initialize_mutex, &timeout);
        }
        pthread_mutex_unlock(&threads.threads[thread_id]->initialize_mutex);
    }
    return true;
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
    pthread_mutex_lock(&threads.global_working_mutex);
    test_thread_t* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
}

void test_threading_prepare_call_dart_bytes(int32_t* targets, int32_t target_count)
{
    pthread_mutex_lock(&threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        test_thread_t* thread = threads.threads[id];
        for (int32_t target = 0; target < target_count; target++)
        {
            for (int message_id = 0; message_id < thread->whole_messages_count / target_count; message_id++)
            {
                interactor_message_t* message = interactor_native_allocate_message(thread->interactor);
                message->id = message_id;
                message->input = (void*)(intptr_t)interactor_native_data_allocate(thread->interactor, 3);
                ((char*)message->input)[0] = 0x1;
                ((char*)message->input)[1] = 0x2;
                ((char*)message->input)[2] = 0x3;
                message->input_size = 3;
                message->owner = 0;
                message->method = 0;
                interactor_native_call_dart(thread->interactor, targets[target], message);
            }
        }
        interactor_native_submit(thread->interactor);
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
}

void test_threading_call_dart_callback(interactor_message_t* message)
{
    pthread_mutex_lock(&threads.global_working_mutex);
    test_thread_t* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
    pthread_mutex_unlock(&threads.global_working_mutex);
}

void test_threading_destroy()
{
    for (int thread_id = 0; thread_id < threads.count; thread_id++)
    {
        threads.threads[thread_id]->alive = false;
        pthread_join(threads.threads[thread_id]->id, NULL);
        free(threads.threads[thread_id]);
    }
}