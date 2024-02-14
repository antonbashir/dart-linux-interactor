#include <interactor_native.h>
#include <liburing.h>
#include <liburing/io_uring.h>
#include <stdint.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include "interactor_collections.h"
#include "interactor_common.h"
#include "interactor_constants.h"
#include "interactor_data_pool.h"
#include "interactor_io_buffers.h"
#include "interactor_memory.h"
#include "interactor_message.h"
#include "interactor_messages_pool.h"
#include "interactor_payload_pool.h"
#include "interactor_static_buffers.h"

int interactor_native_initialize(struct interactor_native* interactor, struct interactor_native_configuration* configuration, uint8_t id)
{
    interactor->id = id;
    interactor->ring_size = configuration->ring_size;
    interactor->completions = malloc(sizeof(struct io_uring_cqe*) * interactor->ring_size);
    interactor->cqe_wait_count = configuration->cqe_wait_count;
    interactor->cqe_peek_count = configuration->cqe_peek_count;
    interactor->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
    if (!interactor->completions)
    {
        return -ENOMEM;
    }

    interactor->memory = calloc(1, sizeof(struct interactor_memory));
    if (!interactor->memory)
    {
        return -ENOMEM;
    }

    interactor->messages_pool = calloc(1, sizeof(struct interactor_messages_pool));
    if (!interactor->messages_pool)
    {
        return -ENOMEM;
    }

    interactor->small_data = calloc(1, sizeof(struct interactor_small_data));
    if (!interactor->small_data)
    {
        return -ENOMEM;
    }

    interactor->static_buffers = calloc(1, sizeof(struct interactor_static_buffers));
    if (!interactor->static_buffers)
    {
        return -ENOMEM;
    }

    interactor->io_buffers = calloc(1, sizeof(struct interactor_io_buffers));
    if (!interactor->io_buffers)
    {
        return -ENOMEM;
    }

    if (interactor_memory_create(interactor->memory, configuration->quota_size, configuration->preallocation_size, configuration->slab_size))
    {
        return -ENOMEM;
    }
    if (interactor_messages_pool_create(interactor->messages_pool, interactor->memory))
    {
        return -ENOMEM;
    }
    if (interactor_small_data_create(interactor->small_data, interactor->memory))
    {
        return -ENOMEM;
    }
    interactor->callbacks = mh_native_callbacks_new();
    if (!interactor->callbacks)
    {
        return -ENOMEM;
    }

    if (interactor_static_buffers_create(interactor->static_buffers, configuration->static_buffers_capacity, configuration->static_buffer_size))
    {
        return -ENOMEM;
    }
    if (interactor_io_buffers_create(interactor->io_buffers, interactor->memory))
    {
        return -ENOMEM;
    }

    interactor->ring = calloc(1, sizeof(struct io_uring));
    if (!interactor->ring)
    {
        return -ENOMEM;
    }

    int result = io_uring_queue_init(configuration->ring_size, interactor->ring, configuration->ring_flags);
    if (result)
    {
        return result;
    }

    interactor->descriptor = interactor->ring->ring_fd;

    return interactor->descriptor;
}

int interactor_native_initialize_default(struct interactor_native* interactor, uint8_t id)
{
    struct interactor_native_configuration configuration = {
        .static_buffers_capacity = 4096,
        .static_buffer_size = 4096,
        .ring_size = 16384,
        .ring_flags = 0,
        .cqe_peek_count = 1024,
        .cqe_wait_count = 1,
        .cqe_wait_timeout_millis = 1,
        .preallocation_size = 64 * 1024,
        .slab_size = 64 * 1024,
        .quota_size = 16 * 1024 * 1024,
    };
    return interactor_native_initialize(interactor, &configuration, id);
}

void interactor_native_register_callback(struct interactor_native* interactor, uint64_t owner, uint64_t method, void (*callback)(struct interactor_message*))
{
    struct mh_native_callbacks_node_t node = {
        .callback = callback,
        .key = {
            .method = method,
            .owner = owner,
        },
    };
    mh_native_callbacks_put((struct mh_native_callbacks_t*)interactor->callbacks, &node, NULL, 0);
}

int32_t interactor_native_get_static_buffer(struct interactor_native* interactor)
{
    return interactor_static_buffers_pop(interactor->static_buffers);
}

int32_t interactor_native_available_static_buffers(struct interactor_native* interactor)
{
    return interactor->static_buffers->available;
}

int32_t interactor_native_used_static_buffers(struct interactor_native* interactor)
{
    return interactor->static_buffers->capacity - interactor->static_buffers->available;
}

void interactor_native_release_static_buffer(struct interactor_native* interactor, int32_t buffer_id)
{
    interactor_static_buffers_push(interactor->static_buffers, buffer_id);
}

struct interactor_message* interactor_native_allocate_message(struct interactor_native* interactor)
{
    struct interactor_message* message = interactor_messages_pool_allocate(interactor->messages_pool);
    memset(message, 0, sizeof(struct interactor_message));
    return message;
}

void interactor_native_free_message(struct interactor_native* interactor, struct interactor_message* message)
{
    interactor_messages_pool_free(interactor->messages_pool, message);
}

struct interactor_payload_pool* interactor_native_payload_pool_create(struct interactor_native* interactor, size_t size)
{
    struct interactor_payload_pool* pool = malloc(sizeof(struct interactor_payload_pool));
    pool->size = size;
    interactor_payload_pool_create(pool, interactor->memory, size);
    return pool;
}

void* interactor_native_payload_allocate(struct interactor_payload_pool* pool)
{
    void* payload = (void*)interactor_payload_pool_allocate(pool);
    memset(payload, 0, pool->size);
    return payload;
}

void interactor_native_payload_free(struct interactor_payload_pool* pool, void* pointer)
{
    interactor_payload_pool_free(pool, pointer);
}

void interactor_native_payload_pool_destroy(struct interactor_payload_pool* pool)
{
    interactor_payload_pool_destroy(pool);
    free(pool);
}

void* interactor_native_data_allocate(struct interactor_native* interactor, size_t size)
{
    void* data = (void*)interactor_small_data_allocate(interactor->small_data, size);
    memset(data, 0, size);
    return data;
}

void interactor_native_data_free(struct interactor_native* interactor, void* pointer, size_t size)
{
    interactor_small_data_free(interactor->small_data, pointer, size);
}

int interactor_native_count_ready(struct interactor_native* interactor)
{
    return io_uring_cq_ready(interactor->ring);
}

int interactor_native_count_ready_submit(struct interactor_native* interactor)
{
    io_uring_submit(interactor->ring);
    return io_uring_cq_ready(interactor->ring);
}

static inline void interactor_native_process_implementation(struct interactor_native* interactor)
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALL)
        {
            struct interactor_message* message = (struct interactor_message*)cqe->user_data;
            void (*pointer)(struct interactor_message*) = (void (*)(struct interactor_message*))message->method;
            pointer(message);
            struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
            uint64_t target = message->source;
            message->source = interactor->descriptor;
            message->target = target;
            io_uring_prep_msg_ring(sqe, target, INTERACTOR_DART_CALLBACK, (uint64_t)((intptr_t)message), 0);
            sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
            continue;
        }

        if (cqe->res == INTERACTOR_NATIVE_CALLBACK)
        {
            struct interactor_message* message = (struct interactor_message*)cqe->user_data;
            struct mh_native_callbacks_key_t key = {
                .owner = message->owner,
                .method = message->method,
            };
            mh_int_t callback;
            if ((callback = mh_native_callbacks_find(interactor->callbacks, key, 0)) != mh_end((struct mh_native_callbacks_t*)interactor->callbacks))
            {
                struct mh_native_callbacks_node_t* node = mh_native_callbacks_node((struct mh_native_callbacks_t*)interactor->callbacks, callback);
                node->callback(message);
            }
            continue;
        }
    }
    io_uring_cq_advance(interactor->ring, count);
}

void interactor_native_process(struct interactor_native* interactor)
{
    interactor_native_process_implementation(interactor);
}

void interactor_native_process_infinity(struct interactor_native* interactor)
{
    io_uring_submit_and_wait(interactor->ring, interactor->cqe_wait_count);
    if (io_uring_cq_ready(interactor->ring) > 0)
    {
        interactor_native_process_implementation(interactor);
    }
}

void interactor_native_process_timeout(struct interactor_native* interactor)
{
    struct __kernel_timespec timeout = {
        .tv_nsec = interactor->cqe_wait_timeout_millis * 1e+6,
        .tv_sec = 0,
    };
    io_uring_submit_and_wait_timeout(interactor->ring, &interactor->completions[0], interactor->cqe_wait_count, &timeout, 0);
    if (io_uring_cq_ready(interactor->ring) > 0)
    {
        interactor_native_process_implementation(interactor);
    }
}

void interactor_native_foreach(struct interactor_native* interactor, void (*call)(struct interactor_message*), void (*callback)(struct interactor_message*))
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALL && call)
        {
            struct interactor_message* message = (struct interactor_message*)cqe->user_data;
            call(message);
            continue;
        }

        if (cqe->res == INTERACTOR_NATIVE_CALLBACK && callback)
        {
            struct interactor_message* message = (struct interactor_message*)cqe->user_data;
            callback(message);
            continue;
        }
    }
    io_uring_cq_advance(interactor->ring, count);
}

int interactor_native_submit(struct interactor_native* interactor)
{
    return io_uring_submit(interactor->ring);
}

void interactor_native_call_dart(struct interactor_native* interactor, int target_ring_fd, struct interactor_message* message)
{
    message->source = interactor->descriptor;
    message->target = target_ring_fd;
    message->flags |= INTERACTOR_DART_CALL;
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_DART_CALL, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_callback_to_dart(struct interactor_native* interactor, struct interactor_message* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    uint64_t target = message->source;
    message->source = interactor->descriptor;
    message->target = target;
    message->flags |= INTERACTOR_DART_CALLBACK;
    io_uring_prep_msg_ring(sqe, target, INTERACTOR_DART_CALLBACK, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_destroy(struct interactor_native* interactor)
{
    io_uring_queue_exit(interactor->ring);
    interactor_static_buffers_destroy(interactor->static_buffers);
    interactor_io_buffers_destroy(interactor->io_buffers);
    interactor_small_data_destroy(interactor->small_data);
    interactor_messages_pool_destroy(interactor->messages_pool);
    interactor_memory_destroy(interactor->memory);
    mh_native_callbacks_delete(interactor->callbacks);
    free(interactor->static_buffers);
    free(interactor->io_buffers);
    free(interactor->small_data);
    free(interactor->messages_pool);
    free(interactor->memory);
    free(interactor->ring);
    free(interactor->completions);
}

void interactor_native_close_descriptor(int fd)
{
    shutdown(fd, SHUT_RDWR);
    close(fd);
}

struct interactor_input_buffer* interactor_native_io_buffers_allocate_input(struct interactor_native* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_input(interactor->io_buffers, initial_capacity);
}

struct interactor_output_buffer* interactor_native_io_buffers_allocate_output(struct interactor_native* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_output(interactor->io_buffers, initial_capacity);
}

void interactor_native_io_buffers_free_input(struct interactor_native* interactor, struct interactor_input_buffer* buffer)
{
    interactor_io_buffers_free_input(interactor->io_buffers, buffer);
}

void interactor_native_io_buffers_free_output(struct interactor_native* interactor, struct interactor_output_buffer* buffer)
{
    interactor_io_buffers_free_output(interactor->io_buffers, buffer);
}

uint8_t* interactor_native_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_reserve(buffer, size);
}

uint8_t* interactor_native_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_allocate(buffer, size);
}

uint8_t* interactor_native_input_buffer_allocate_reserve(struct interactor_input_buffer* buffer, size_t delta, size_t size)
{
    return interactor_input_buffer_allocate_reserve(buffer, delta, size);
}

uint8_t* interactor_native_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_reserve(buffer, size);
}

uint8_t* interactor_native_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_allocate(buffer, size);
}

uint8_t* interactor_native_output_buffer_allocate_reserve(struct interactor_output_buffer* buffer, size_t delta, size_t size)
{
    return interactor_output_buffer_allocate_reserve(buffer, delta, size);
}