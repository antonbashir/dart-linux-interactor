#include "interactor_dart.h"
#include <interactor_memory.h>
#include <liburing.h>
#include <liburing/io_uring.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include "interactor_common.h"
#include "interactor_constants.h"
#include "interactor_data_pool.h"
#include "interactor_io_buffers.h"
#include "interactor_static_buffers.h"
#include "msgpuck.h"

int interactor_dart_initialize(struct interactor_dart* interactor, struct interactor_dart_configuration* configuration, uint8_t id)
{
    interactor->id = id;
    interactor->ring_size = configuration->ring_size;
    interactor->delay_randomization_factor = configuration->delay_randomization_factor;
    interactor->base_delay_micros = configuration->base_delay_micros;
    interactor->max_delay_micros = configuration->max_delay_micros;
    interactor->cqes = malloc(sizeof(struct io_uring_cqe*) * interactor->ring_size);
    interactor->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
    interactor->cqe_wait_count = configuration->cqe_wait_count;
    interactor->cqe_peek_count = configuration->cqe_peek_count;
    if (!interactor->cqes)
    {
        return -ENOMEM;
    }

    if (interactor_memory_create(&interactor->memory, configuration->quota_size, configuration->preallocation_size, configuration->slab_size))
    {
        return -ENOMEM;
    }
    if (interactor_messages_pool_create(&interactor->messages_pool, &interactor->memory))
    {
        return -ENOMEM;
    }
    if (interactor_data_pool_create(&interactor->data_pool, &interactor->memory))
    {
        return -ENOMEM;
    }
    if (interactor_static_buffers_create(&interactor->static_buffers, configuration->static_buffers_capacity, configuration->static_buffer_size))
    {
        return -ENOMEM;
    }
    if (interactor_io_buffers_create(&interactor->io_buffers, &interactor->memory))
    {
        return -ENOMEM;
    }

    int result = io_uring_queue_init(configuration->ring_size, &interactor->ring, configuration->ring_flags);
    if (result)
    {
        return result;
    }

    interactor->descriptor = interactor->ring.ring_fd;

    return interactor->descriptor;
}

int32_t interactor_dart_get_static_buffer(struct interactor_dart* interactor)
{
    return interactor_static_buffers_pop(&interactor->static_buffers);
}

int32_t interactor_dart_available_static_buffers(struct interactor_dart* interactor)
{
    return interactor->static_buffers.available;
}

int32_t interactor_dart_used_static_buffers(struct interactor_dart* interactor)
{
    return interactor->static_buffers.capacity - interactor->static_buffers.available;
}

void interactor_dart_release_static_buffer(struct interactor_dart* interactor, int32_t buffer_id)
{
    interactor_static_buffers_push(&interactor->static_buffers, buffer_id);
}

struct interactor_message* interactor_dart_allocate_message(struct interactor_dart* interactor)
{
    struct interactor_message* message = interactor_messages_pool_allocate(&interactor->messages_pool);
    memset(message, 0, sizeof(struct interactor_message));
    return message;
}

void interactor_dart_free_message(struct interactor_dart* interactor, struct interactor_message* message)
{
    interactor_messages_pool_free(&interactor->messages_pool, message);
}

struct interactor_payload_pool* interactor_dart_payload_pool_create(struct interactor_dart* interactor, size_t size)
{
    struct interactor_payload_pool* pool = malloc(sizeof(struct interactor_payload_pool));
    pool->size = size;
    interactor_payload_pool_create(pool, &interactor->memory, size);
    return pool;
}

void* interactor_dart_payload_allocate(struct interactor_payload_pool* pool)
{
    void* payload = interactor_payload_pool_allocate(pool);
    memset(payload, 0, pool->size);
    return payload;
}

void interactor_dart_payload_free(struct interactor_payload_pool* pool, void* pointer)
{
    interactor_payload_pool_free(pool, pointer);
}

void interactor_dart_payload_pool_destroy(struct interactor_payload_pool* pool)
{
    interactor_payload_pool_destroy(pool);
    free(pool);
}

void* interactor_dart_data_allocate(struct interactor_dart* interactor, size_t size)
{
    void* data = interactor_data_pool_allocate(&interactor->data_pool, size);
    memset(data, 0, size);
    return data;
}

void interactor_dart_data_free(struct interactor_dart* interactor, void* pointer, size_t size)
{
    interactor_data_pool_free(&interactor->data_pool, pointer, size);
}

int interactor_dart_peek(struct interactor_dart* interactor)
{
    struct __kernel_timespec timeout = {
        .tv_nsec = interactor->cqe_wait_timeout_millis * 1e+6,
        .tv_sec = 0,
    };
    io_uring_submit_and_wait_timeout(&interactor->ring, &interactor->cqes[0], interactor->cqe_wait_count, &timeout, 0);
    return io_uring_peek_batch_cqe(&interactor->ring, &interactor->cqes[0], interactor->cqe_peek_count);
}

void interactor_dart_call_native(struct interactor_dart* interactor, int target_ring_fd, struct interactor_message* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(&interactor->ring);
    message->source = interactor->descriptor;
    message->target = target_ring_fd;
    message->flags |= INTERACTOR_NATIVE_CALL;
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_NATIVE_CALL, (intptr_t)message, 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_dart_callback_to_native(struct interactor_dart* interactor, struct interactor_message* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(&interactor->ring);
    uint64_t target = message->source;
    message->source = interactor->descriptor;
    message->target = target;
    message->flags |= INTERACTOR_NATIVE_CALLBACK;
    io_uring_prep_msg_ring(sqe, target, INTERACTOR_NATIVE_CALLBACK, (intptr_t)message, 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_dart_destroy(struct interactor_dart* interactor)
{
    io_uring_queue_exit(&interactor->ring);
    interactor_static_buffers_destroy(&interactor->static_buffers);
    interactor_io_buffers_destroy(&interactor->io_buffers);
    interactor_data_pool_destroy(&interactor->data_pool);
    interactor_messages_pool_destroy(&interactor->messages_pool);
    interactor_memory_destroy(&interactor->memory);
    free(interactor->cqes);
}

void interactor_dart_cqe_advance(struct interactor_dart* interactor, int count)
{
    io_uring_cq_advance(&interactor->ring, count);
}

void interactor_dart_close_descriptor(int fd)
{
    shutdown(fd, SHUT_RDWR);
    close(fd);
}

const char* interactor_dart_error_to_string(int error)
{
    return strerror(-error);
}

struct interactor_memory* interactor_dart_memory(struct interactor_dart* interactor)
{
    return &interactor->memory;
}

uint64_t interactor_dart_tuple_next(const char* buffer, uint64_t offset)
{
    const char* offset_buffer = buffer + offset;
    mp_next(&offset_buffer);
    return (uint64_t)(offset_buffer - buffer);
}

struct interactor_input_buffer* interactor_dart_io_buffers_allocate_input(struct interactor_dart* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_input(&interactor->io_buffers, initial_capacity);
}

struct interactor_output_buffer* interactor_dart_io_buffers_allocate_output(struct interactor_dart* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_output(&interactor->io_buffers, initial_capacity);
}

void interactor_dart_io_buffers_free_input(struct interactor_dart* interactor, struct interactor_input_buffer* buffer)
{
    interactor_io_buffers_free_input(&interactor->io_buffers, buffer);
}

void interactor_dart_io_buffers_free_output(struct interactor_dart* interactor, struct interactor_output_buffer* buffer)
{
    interactor_io_buffers_free_output(&interactor->io_buffers, buffer);
}

uint8_t* interactor_dart_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_reserve(buffer, size);
}

uint8_t* interactor_dart_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_allocate(buffer, size);
}

uint8_t* interactor_dart_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_reserve(buffer, size);
}

uint8_t* interactor_dart_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_allocate(buffer, size);
}
