#include "test_threading.h"
#include <bits/pthreadtypes.h>
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "interactor_message.h"
#include "interactor_native.h"
#include "test.h"

struct test_threads threads;

int* test_threading_interactor_descriptors()
{
    int* descriptors = malloc(sizeof(int) * threads.count);
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        descriptors[id] = ((struct interactor_native*)threads.threads[id].interactor)->descriptor;
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
    return descriptors;
}

static inline struct test_thread* test_threading_thread_by_fd(int fd)
{
    struct test_thread* thread = NULL;
    for (int id = 0; id < threads.count; id++)
    {
        thread = &threads.threads[id];
        if (((struct interactor_native*)thread->interactor)->descriptor == fd)
        {
            return thread;
        }
    }
    return thread;
}

static void* test_threading_run(void* thread)
{
    struct test_thread* casted = (struct test_thread*)thread;
    pthread_mutex_lock((pthread_mutex_t*)casted->initialize_mutex);
    casted->alive = false;
    do
    {
        casted->interactor = test_interactor_initialize();
    } while (!casted->interactor || ((struct interactor_native*)casted->interactor)->descriptor <= 0);
    interactor_native_register_callback((struct interactor_native*)casted->interactor, 0, 0, test_threading_call_dart_callback);
    casted->alive = true;
    pthread_cond_broadcast((pthread_cond_t*)casted->initialize_condition);
    pthread_mutex_unlock((pthread_mutex_t*)casted->initialize_mutex);
    while (casted->alive)
    {
        interactor_native_process_timeout((struct interactor_native*)casted->interactor);
    }
    test_interactor_destroy((struct interactor_native*)casted->interactor);
    free(casted->messages);
    return NULL;
}

bool test_threading_initialize(int thread_count, int isolates_count, int per_thread_messages_count)
{
    threads.count = thread_count;
    threads.threads = malloc(thread_count * sizeof(struct test_thread));
    threads.global_working_mutex = malloc(sizeof(pthread_mutex_t));
    pthread_mutex_init((pthread_mutex_t*)threads.global_working_mutex, NULL);
    for (int thread_id = 0; thread_id < thread_count; thread_id++)
    {
        struct test_thread* thread = &threads.threads[thread_id];
        memset(thread, 0, sizeof(struct test_thread));
        thread->whole_messages_count = per_thread_messages_count;
        thread->received_messages_count = 0;
        thread->messages = malloc(per_thread_messages_count * sizeof(struct interactor_message*));
        thread->initialize_mutex = malloc(sizeof(pthread_mutex_t));
        pthread_mutex_init((pthread_mutex_t*)thread->initialize_mutex, NULL);
        thread->initialize_condition = malloc(sizeof(pthread_cond_t));
        pthread_cond_init((pthread_cond_t*)thread->initialize_condition, NULL);

        pthread_create(&thread->id, NULL, test_threading_run, thread);
        pthread_setname_np(thread->id, "test_threading");

        pthread_mutex_lock((pthread_mutex_t*)thread->initialize_mutex);
        while (!thread->alive)
        {
            struct timespec timeout = {.tv_sec = 1};
            pthread_cond_timedwait((pthread_cond_t*)thread->initialize_condition, (pthread_mutex_t*)thread->initialize_mutex, &timeout);
        }
        pthread_mutex_unlock((pthread_mutex_t*)thread->initialize_mutex);
    }
    return true;
}

int test_threading_call_native_check()
{
    int messages = 0;
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id].received_messages_count;
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
    return messages;
}

int test_threading_call_dart_check()
{
    int messages = 0;
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        messages += threads.threads[id].received_messages_count;
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
    return messages;
}

void test_threading_call_native(struct interactor_message* message)
{
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    struct test_thread* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
}

void test_threading_prepare_call_dart_bytes(int32_t* targets, int32_t target_count)
{
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    for (int id = 0; id < threads.count; id++)
    {
        struct test_thread* thread = &threads.threads[id];
        for (int32_t target = 0; target < target_count; target++)
        {
            for (int message_id = 0; message_id < thread->whole_messages_count / target_count; message_id++)
            {
                struct interactor_message* message = interactor_native_allocate_message((struct interactor_native*)thread->interactor);
                message->id = message_id;
                message->input = (void*)(intptr_t)interactor_native_data_allocate((struct interactor_native*)thread->interactor, 3);
                ((char*)message->input)[0] = 0x1;
                ((char*)message->input)[1] = 0x2;
                ((char*)message->input)[2] = 0x3;
                message->input_size = 3;
                message->owner = 0;
                message->method = 0;
                interactor_native_call_dart((struct interactor_native*)thread->interactor, targets[target], message);
            }
        }
        interactor_native_submit((struct interactor_native*)thread->interactor);
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
}

void test_threading_call_dart_callback(struct interactor_message* message)
{
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    struct test_thread* thread = test_threading_thread_by_fd(message->target);
    if (thread)
    {
        message->output = message->input;
        message->output_size = message->input_size;
        thread->messages[thread->received_messages_count] = message;
        thread->received_messages_count++;
    }
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
}

void test_threading_destroy()
{
    pthread_mutex_lock((pthread_mutex_t*)threads.global_working_mutex);
    for (int thread_id = 0; thread_id < threads.count; thread_id++)
    {
        struct test_thread* thread = &threads.threads[thread_id];
        thread->alive = false;
        pthread_join(thread->id, NULL);
    }
    free(threads.threads);
    pthread_mutex_unlock((pthread_mutex_t*)threads.global_working_mutex);
}

intptr_t test_threading_call_native_address_lookup()
{
    return (intptr_t)&test_threading_call_native;
}