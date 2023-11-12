#include <interactor_native.h>
#include <liburing.h>
#include <liburing/io_uring.h>
#include <stdint.h>
#include <sys/socket.h>
#include "interactor_collections.h"
#include "interactor_common.h"
#include "interactor_constants.h"
#include "interactor_message.h"
#include "liburing.h"

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
    if (!interactor->buffers)
    {
        return -ENOMEM;
    }

    interactor_memory_create(&interactor->memory, configuration->quota_size, configuration->preallocation_size, configuration->slab_size);
    interactor_messages_pool_create(&interactor->messages_pool, &interactor->memory);

    interactor->events = mh_events_new();
    if (!interactor->events)
    {
        return -ENOMEM;
    }
    mh_events_reserve((struct mh_events_t*)interactor->events, interactor->buffers_count, 0);

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
        .preallocation_size = 64 * 1024,
        .slab_size = 64 * 1024,
        .quota_size = 16 * 1024 * 1024,
        .ring_flags = 0,
    };
    return interactor_native_initialize(interactor, &configuration, id);
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
    return interactor_messages_pool_allocate(&interactor->messages_pool);
}

void interactor_native_free_message(interactor_native_t* interactor, interactor_message_t* message)
{
    interactor_messages_pool_free(&interactor->messages_pool, message);
}

struct interactor_payloads_pool* interactor_native_payload_pool_create(interactor_native_t* interactor, size_t size)
{
    struct interactor_payloads_pool* pool = malloc(sizeof(struct interactor_payloads_pool));
    interactor_payloads_pool_create(pool, &interactor->memory, size);
    return pool;
}

intptr_t interactor_native_payload_allocate(struct interactor_payloads_pool* pool)
{
    return interactor_payloads_pool_allocate(pool);
}

void interactor_native_payload_free(struct interactor_payloads_pool* pool, intptr_t pointer)
{
    interactor_payloads_pool_free(pool, pointer);
}

void interactor_native_payload_pool_destroy(struct interactor_payloads_pool* pool)
{
    interactor_payloads_pool_destroy(pool);
    free(pool);
}

static inline void interactor_native_add_event(interactor_native_t* interactor, int fd, uint64_t data, int64_t timeout)
{
    struct mh_events_node_t node = {
        .data = data,
        .timeout = timeout,
        .timestamp = time(NULL),
        .fd = fd,
    };
    mh_events_put((struct mh_events_t*)interactor->events, &node, NULL, 0);
}

void interactor_native_cancel_by_fd(interactor_native_t* interactor, int fd)
{
    mh_int_t index;
    mh_int_t to_delete[((struct mh_events_t*)interactor->events)->size];
    int to_delete_count = 0;
    mh_foreach(((struct mh_events_t*)interactor->events), index)
    {
        struct mh_events_node_t* node = mh_events_node(interactor->events, index);
        if (node->fd == fd)
        {
            struct io_uring* ring = interactor->ring;
            struct io_uring_sqe* sqe = interactor_provide_sqe(ring);
            io_uring_prep_cancel(sqe, (void*)node->data, IORING_ASYNC_CANCEL_ALL);
            sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
            to_delete[to_delete_count++] = index;
        }
    }
    for (int index = 0; index < to_delete_count; index++)
    {
        mh_events_del(interactor->events, to_delete[index], 0);
    }
    io_uring_submit(interactor->ring);
}

int interactor_native_peek_infinity(interactor_native_t* interactor)
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

void interactor_native_check_event_timeouts(interactor_native_t* interactor)
{
    mh_int_t index;
    mh_int_t to_delete[((struct mh_events_t*)interactor->events)->size];
    int to_delete_count = 0;
    mh_foreach(((struct mh_events_t*)interactor->events), index)
    {
        struct mh_events_node_t* node = mh_events_node(interactor->events, index);
        int64_t timeout = node->timeout;
        if (timeout == INTERACTOR_TIMEOUT_INFINITY)
        {
            continue;
        }
        uint64_t timestamp = node->timestamp;
        uint64_t data = node->data;
        time_t current_time = time(NULL);
        if (current_time - timestamp > timeout)
        {
            struct io_uring* ring = interactor->ring;
            struct io_uring_sqe* sqe = interactor_provide_sqe(ring);
            io_uring_prep_cancel(sqe, (void*)data, IORING_ASYNC_CANCEL_ALL);
            sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
            to_delete[to_delete_count++] = index;
        }
    }
    for (int index = 0; index < to_delete_count; index++)
    {
        mh_events_del(interactor->events, to_delete[index], 0);
    }
    io_uring_submit(interactor->ring);
}

void interactor_native_remove_event(interactor_native_t* interactor, uint64_t data)
{
    mh_int_t event;
    if ((event = mh_events_find(interactor->events, data, 0)) != mh_end((struct mh_events_t*)interactor->events))
    {
        mh_events_del(interactor->events, event, 0);
    }
}

void interactor_native_destroy(interactor_native_t* interactor)
{
    io_uring_queue_exit(interactor->ring);
    for (size_t index = 0; index < interactor->buffers_count; index++)
    {
        free(interactor->buffers[index].iov_base);
    }
    interactor_buffers_pool_destroy(&interactor->buffers_pool);
    mh_events_delete(interactor->events);
    free(interactor->cqes);
    free(interactor->buffers);
    free(interactor->ring);
    free(interactor);
}

void interactor_native_cqe_advance(struct io_uring* ring, int count)
{
    io_uring_cq_advance(ring, count);
}

int interactor_native_submit(interactor_native_t* interactor)
{
  return io_uring_submit(interactor->ring);
}

void interactor_native_call_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_DART_CALL, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_callback_to_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_DART_CALLBACK, (uint64_t)((intptr_t)message), 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_native_close_descriptor(int fd)
{
    shutdown(fd, SHUT_RDWR);
    close(fd);
}
