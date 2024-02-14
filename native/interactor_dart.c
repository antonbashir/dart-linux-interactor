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
#include "interactor_message.h"
#include "interactor_messages_pool.h"
#include "interactor_payload_pool.h"
#include "interactor_static_buffers.h"
#include "msgpuck.h"

int interactor_dart_initialize(struct interactor_dart* interactor, struct interactor_dart_configuration* configuration, uint8_t id)
{
    interactor->id = id;
    interactor->ring_size = configuration->ring_size;
    interactor->delay_randomization_factor = configuration->delay_randomization_factor;
    interactor->base_delay_micros = configuration->base_delay_micros;
    interactor->max_delay_micros = configuration->max_delay_micros;
    interactor->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
    interactor->cqe_wait_count = configuration->cqe_wait_count;
    interactor->cqe_peek_count = configuration->cqe_peek_count;

    interactor->completions = malloc(sizeof(struct io_uring_cqe*) * interactor->ring_size);
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

int32_t interactor_dart_static_buffers_get(struct interactor_dart* interactor)
{
    return interactor_static_buffers_pop(interactor->static_buffers);
}

int32_t interactor_dart_static_buffers_available(struct interactor_dart* interactor)
{
    return interactor->static_buffers->available;
}

int32_t interactor_dart_static_buffers_used(struct interactor_dart* interactor)
{
    return interactor->static_buffers->capacity - interactor->static_buffers->available;
}

void interactor_dart_static_buffers_release(struct interactor_dart* interactor, int32_t buffer_id)
{
    interactor_static_buffers_push(interactor->static_buffers, buffer_id);
}

struct iovec* interactor_dart_static_buffers_inner(struct interactor_dart* interactor)
{
    return interactor->static_buffers->buffers;
}

struct interactor_message* interactor_dart_allocate_message(struct interactor_dart* interactor)
{
    struct interactor_message* message = interactor_messages_pool_allocate(interactor->messages_pool);
    memset(message, 0, sizeof(struct interactor_message));
    return message;
}

void interactor_dart_free_message(struct interactor_dart* interactor, struct interactor_message* message)
{
    interactor_messages_pool_free(interactor->messages_pool, message);
}

struct interactor_payload_pool* interactor_dart_payload_pool_create(struct interactor_dart* interactor, size_t size)
{
    struct interactor_payload_pool* pool = malloc(sizeof(struct interactor_payload_pool));
    pool->size = size;
    interactor_payload_pool_create(pool, interactor->memory, size);
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

size_t interactor_dart_payload_pool_size(struct interactor_payload_pool* pool)
{
    return pool->size;
}

void* interactor_dart_data_allocate(struct interactor_dart* interactor, size_t size)
{
    void* data = interactor_small_data_allocate(interactor->small_data, size);
    memset(data, 0, size);
    return data;
}

void interactor_dart_data_free(struct interactor_dart* interactor, void* pointer, size_t size)
{
    interactor_small_data_free(interactor->small_data, pointer, size);
}

int interactor_dart_peek(struct interactor_dart* interactor)
{
    struct __kernel_timespec timeout = {
        .tv_nsec = interactor->cqe_wait_timeout_millis * 1e+6,
        .tv_sec = 0,
    };
    io_uring_submit_and_wait_timeout(interactor->ring, &interactor->completions[0], interactor->cqe_wait_count, &timeout, 0);
    return io_uring_peek_batch_cqe(interactor->ring, &interactor->completions[0], interactor->cqe_peek_count);
}

void interactor_dart_call_native(struct interactor_dart* interactor, int target_ring_fd, struct interactor_message* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    message->source = interactor->descriptor;
    message->target = target_ring_fd;
    message->flags |= INTERACTOR_NATIVE_CALL;
    io_uring_prep_msg_ring(sqe, target_ring_fd, INTERACTOR_NATIVE_CALL, (intptr_t)message, 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_dart_callback_to_native(struct interactor_dart* interactor, struct interactor_message* message)
{
    struct io_uring_sqe* sqe = interactor_provide_sqe(interactor->ring);
    uint64_t target = message->source;
    message->source = interactor->descriptor;
    message->target = target;
    message->flags |= INTERACTOR_NATIVE_CALLBACK;
    io_uring_prep_msg_ring(sqe, target, INTERACTOR_NATIVE_CALLBACK, (intptr_t)message, 0);
    sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
}

void interactor_dart_destroy(struct interactor_dart* interactor)
{
    io_uring_queue_exit(interactor->ring);
    interactor_static_buffers_destroy(interactor->static_buffers);
    interactor_io_buffers_destroy(interactor->io_buffers);
    interactor_small_data_destroy(interactor->small_data);
    interactor_messages_pool_destroy(interactor->messages_pool);
    interactor_memory_destroy(interactor->memory);
    free(interactor->static_buffers);
    free(interactor->io_buffers);
    free(interactor->small_data);
    free(interactor->messages_pool);
    free(interactor->memory);
    free(interactor->ring);
    free(interactor->completions);
}

void interactor_dart_cqe_advance(struct interactor_dart* interactor, int count)
{
    io_uring_cq_advance(interactor->ring, count);
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

uint64_t interactor_dart_tuple_next(const char* buffer, uint64_t offset)
{
    const char* offset_buffer = buffer + offset;
    mp_next(&offset_buffer);
    return (uint64_t)(offset_buffer - buffer);
}

struct interactor_input_buffer* interactor_dart_io_buffers_allocate_input(struct interactor_dart* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_input(interactor->io_buffers, initial_capacity);
}

struct interactor_output_buffer* interactor_dart_io_buffers_allocate_output(struct interactor_dart* interactor, size_t initial_capacity)
{
    return interactor_io_buffers_allocate_output(interactor->io_buffers, initial_capacity);
}

void interactor_dart_io_buffers_free_input(struct interactor_dart* interactor, struct interactor_input_buffer* buffer)
{
    interactor_io_buffers_free_input(interactor->io_buffers, buffer);
}

void interactor_dart_io_buffers_free_output(struct interactor_dart* interactor, struct interactor_output_buffer* buffer)
{
    interactor_io_buffers_free_output(interactor->io_buffers, buffer);
}

uint8_t* interactor_dart_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_reserve(buffer, size);
}

uint8_t* interactor_dart_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size)
{
    return interactor_input_buffer_allocate(buffer, size);
}

uint8_t* interactor_dart_input_buffer_allocate_reserve(struct interactor_input_buffer* buffer, size_t delta, size_t size)
{
    return interactor_input_buffer_allocate_reserve(buffer, delta, size);
}

uint8_t* interactor_dart_input_buffer_read_position(struct interactor_input_buffer* buffer)
{
    return (uint8_t*)buffer->buffer.rpos;
}

uint8_t* interactor_dart_input_buffer_write_position(struct interactor_input_buffer* buffer)
{
    return (uint8_t*)buffer->buffer.wpos;
}

uint8_t* interactor_dart_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_reserve(buffer, size);
}

uint8_t* interactor_dart_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size)
{
    return interactor_output_buffer_allocate(buffer, size);
}

struct iovec* interactor_dart_output_buffer_content(struct interactor_output_buffer* buffer)
{
    return buffer->buffer.iov;
}

uint8_t* interactor_dart_output_buffer_allocate_reserve(struct interactor_output_buffer* buffer, size_t delta, size_t size)
{
    return interactor_output_buffer_allocate_reserve(buffer, delta, size);
}