#include <interactor_native.h>
#include <liburing.h>
#include <liburing/io_uring.h>
#include <stdint.h>
#include <sys/socket.h>
#include "interactor_collections.h"
#include "interactor_common.h"
#include "interactor_constants.h"
#include "interactor_message.h"

int interactor_native_initialize(interactor_native_t* interactor, interactor_native_configuration_t* configuration, uint8_t id)
{
    interactor->id = id;
    interactor->ring_size = configuration->ring_size;
    interactor->buffer_size = configuration->buffer_size;
    interactor->buffers_count = configuration->buffers_count;
    interactor->cqes = malloc(sizeof(struct io_uring_cqe) * interactor->ring_size);
    interactor->buffers = malloc(sizeof(struct iovec) * configuration->buffers_count);
    interactor->cqe_wait_count = configuration->cqe_wait_count;
    interactor->cqe_peek_count = configuration->cqe_peek_count;
    interactor->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
    if (!interactor->buffers)
    {
        return -ENOMEM;
    }

    interactor_memory_create(&interactor->memory, configuration->quota_size, configuration->preallocation_size, configuration->slab_size);
    interactor_messages_pool_create(&interactor->messages_pool, &interactor->memory);
    interactor_data_pool_create(&interactor->data_pool, &interactor->memory);

    interactor->callbacks = mh_native_callbacks_new();
    if (!interactor->callbacks)
    {
        return -ENOMEM;
    }

    int result = interactor_buffers_pool_create(&interactor->buffers_pool, configuration->buffers_count);
    if (result == -1)
    {
        return -ENOMEM;
    }

    for (size_t index = 0; index < configuration->buffers_count; index++)
    {
        if (posix_memalign(&interactor->buffers[index].iov_base, getpagesize(), configuration->buffer_size))
        {
            return -ENOMEM;
        }
        memset(interactor->buffers[index].iov_base, 0, configuration->buffer_size);
        interactor->buffers[index].iov_len = configuration->buffer_size;

        interactor_buffers_pool_push(&interactor->buffers_pool, index);
    }

    interactor->ring = malloc(sizeof(struct io_uring));
    if (!interactor->ring)
    {
        return -ENOMEM;
    }

    result = io_uring_queue_init(configuration->ring_size, interactor->ring, configuration->ring_flags);
    if (result)
    {
        return result;
    }

    result = io_uring_register_buffers(interactor->ring, interactor->buffers, interactor->buffers_count);
    if (result)
    {
        return result;
    }

    return 0;
}

int interactor_native_initialize_default(interactor_native_t* interactor, uint8_t id)
{
    interactor_native_configuration_t configuration = {
        .buffer_size = 4096,
        .buffers_count = 4096,
        .ring_size = 16384,
        .cqe_peek_count = 1024,
        .cqe_wait_count = 1,
        .cqe_wait_timeout_millis = 1,
        .preallocation_size = 64 * 1024,
        .slab_size = 64 * 1024,
        .quota_size = 16 * 1024 * 1024,
        .ring_flags = 0,
    };
    return interactor_native_initialize(interactor, &configuration, id);
}

void interactor_native_register_callback(interactor_native_t* interactor, uint64_t owner, uint64_t method, void (*callback)(interactor_message_t*))
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

int32_t interactor_native_get_buffer(interactor_native_t* interactor)
{
    return interactor_buffers_pool_pop(&interactor->buffers_pool);
}

int32_t interactor_native_available_buffers(interactor_native_t* interactor)
{
    return interactor->buffers_pool.count;
}

int32_t interactor_native_used_buffers(interactor_native_t* interactor)
{
    return interactor->buffers_count - interactor->buffers_pool.count;
}

void interactor_native_release_buffer(interactor_native_t* interactor, uint16_t buffer_id)
{
    struct iovec* buffer = &interactor->buffers[buffer_id];
    memset(buffer->iov_base, 0, interactor->buffer_size);
    buffer->iov_len = interactor->buffer_size;
    interactor_buffers_pool_push(&interactor->buffers_pool, buffer_id);
}

interactor_message_t* interactor_native_allocate_message(interactor_native_t* interactor)
{
    interactor_message_t* message = interactor_messages_pool_allocate(&interactor->messages_pool);
    memset(message, 0, sizeof(interactor_message_t));
    return message;
}

void interactor_native_free_message(interactor_native_t* interactor, interactor_message_t* message)
{
    interactor_messages_pool_free(&interactor->messages_pool, message);
}

struct interactor_payload_pool* interactor_native_payload_pool_create(interactor_native_t* interactor, size_t size)
{
    struct interactor_payload_pool* pool = malloc(sizeof(struct interactor_payload_pool));
    interactor_payload_pool_create(pool, &interactor->memory, size);
    return pool;
}

intptr_t interactor_native_payload_allocate(struct interactor_payload_pool* pool)
{
    void* payload = (void*)interactor_payload_pool_allocate(pool);
    memset(payload, 0, pool->size);
    return (intptr_t)payload;
}

void interactor_native_payload_free(struct interactor_payload_pool* pool, intptr_t pointer)
{
    interactor_payload_pool_free(pool, pointer);
}

void interactor_native_payload_pool_destroy(struct interactor_payload_pool* pool)
{
    interactor_payload_pool_destroy(pool);
    free(pool);
}

intptr_t interactor_native_data_allocate(interactor_native_t* interactor, size_t size)
{
    void* data = (void*)interactor_data_pool_allocate(&interactor->data_pool, size);
    memset(data, 0, size);
    return (intptr_t)data;
}

void interactor_native_data_free(interactor_native_t* interactor, intptr_t pointer, size_t size)
{
    interactor_data_pool_free(&interactor->data_pool, pointer, size);
}

inline int interactor_native_peek_infinity(interactor_native_t* interactor)
{
    io_uring_submit_and_wait(interactor->ring, interactor->cqe_wait_count);
    return io_uring_peek_batch_cqe(interactor->ring, &interactor->cqes[0], interactor->cqe_peek_count);
}

int interactor_native_peek_timeout(interactor_native_t* interactor)
{
    struct __kernel_timespec timeout = {
        .tv_nsec = interactor->cqe_wait_timeout_millis * 1e+6,
        .tv_sec = 0,
    };
    io_uring_submit_and_wait_timeout(interactor->ring, &interactor->cqes[0], interactor->cqe_wait_count, &timeout, 0);
    return io_uring_peek_batch_cqe(interactor->ring, &interactor->cqes[0], interactor->cqe_peek_count);
}

static inline void interactor_native_process(interactor_native_t* interactor)
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALL)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            void (*pointer)(interactor_message_t*) = (void (*)(interactor_message_t*))message->method;
            pointer(message);
            struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
            uint64_t target = message->source;
            message->source = interactor->ring->ring_fd;
            message->target = target;
            io_uring_prep_msg_ring(sqe, target, INTERACTOR_DART_CALLBACK, (uint64_t)((intptr_t)message), 0);
            sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
            continue;
        }

        if (cqe->res == INTERACTOR_NATIVE_CALLBACK)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
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

void interactor_native_process_infinity(interactor_native_t* interactor)
{
    io_uring_submit_and_wait(interactor->ring, interactor->cqe_wait_count);
    if (likely(io_uring_peek_batch_cqe(interactor->ring, &interactor->cqes[0], interactor->cqe_peek_count) > 0))
    {
        interactor_native_process(interactor);
    }
}

void interactor_native_process_timeout(interactor_native_t* interactor)
{
    struct __kernel_timespec timeout = {
        .tv_nsec = interactor->cqe_wait_timeout_millis * 1e+6,
        .tv_sec = 0,
    };
    io_uring_submit_and_wait_timeout(interactor->ring, &interactor->cqes[0], interactor->cqe_wait_count, &timeout, 0);
    if (io_uring_peek_batch_cqe(interactor->ring, &interactor->cqes[0], interactor->cqe_peek_count) > 0)
    {
        interactor_native_process(interactor);
    }
}

void interactor_native_foreach(interactor_native_t* interactor, void (*call)(interactor_message_t*), void (*callback)(interactor_message_t*))
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALL && call)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            call(message);
            continue;
        }

        if (cqe->res == INTERACTOR_NATIVE_CALLBACK && callback)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            callback(message);
            continue;
        }
    }
    io_uring_cq_advance(interactor->ring, count);
}

void interactor_native_foreach_call(interactor_native_t* interactor, void (*call)(interactor_message_t*))
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALL)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            call(message);
            continue;
        }
    }
    io_uring_cq_advance(interactor->ring, count);
}

void interactor_native_foreach_callback(interactor_native_t* interactor, void (*callback)(interactor_message_t*))
{
    struct io_uring_cqe* cqe;
    unsigned head;
    unsigned count = 0;
    io_uring_for_each_cqe(interactor->ring, head, cqe)
    {
        count++;
        if (cqe->res == INTERACTOR_NATIVE_CALLBACK)
        {
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            callback(message);
            continue;
        }
    }
    io_uring_cq_advance(interactor->ring, count);
}

int interactor_native_submit(interactor_native_t* interactor)
{
    return io_uring_submit(interactor->ring);
}

void interactor_native_call_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message, int64_t timeout)
{
    message->source = interactor->ring->ring_fd;
    message->target = target_ring_fd;
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_DART_CALL, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_callback_to_dart(interactor_native_t* interactor, interactor_message_t* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    uint64_t target = message->source;
    message->source = interactor->ring->ring_fd;
    message->target = target;
    io_uring_prep_msg_ring(sqe, target, INTERACTOR_DART_CALLBACK, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_destroy(interactor_native_t* interactor)
{
    io_uring_queue_exit(interactor->ring);
    for (size_t index = 0; index < interactor->buffers_count; index++)
    {
        free(interactor->buffers[index].iov_base);
    }
    interactor_buffers_pool_destroy(&interactor->buffers_pool);
    mh_native_callbacks_delete(interactor->callbacks);
    free(interactor->cqes);
    free(interactor->buffers);
    free(interactor->ring);
    free(interactor);
}

void interactor_native_close_descriptor(int fd)
{
    shutdown(fd, SHUT_RDWR);
    close(fd);
}
