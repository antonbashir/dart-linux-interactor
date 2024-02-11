#ifndef INTERACTOR_DART_IMPLEMENTATION_H
#define INTERACTOR_DART_IMPLEMENTATION_H

#include <interactor_data_pool.h>
#include <interactor_memory.h>
#include <interactor_messages_pool.h>
#include <interactor_payload_pool.h>
#include <liburing.h>
#include <stdint.h>
#include "interactor_io_buffers.h"
#include "interactor_static_buffers.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct interactor_dart_configuration
    {
        size_t quota_size;
        size_t preallocation_size;
        size_t slab_size;
        size_t static_buffers_capacity;
        size_t static_buffer_size;
        size_t ring_size;
        double delay_randomization_factor;
        uint64_t max_delay_micros;
        uint64_t cqe_wait_timeout_millis;
        uint32_t ring_flags;
        uint32_t base_delay_micros;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
    };

    struct interactor_dart
    {
        struct interactor_messages_pool messages_pool;
        struct interactor_static_buffers static_buffers;
        struct interactor_io_buffers io_buffers;
        struct interactor_data_pool data_pool;
        struct interactor_memory memory;
        struct io_uring ring;
        size_t ring_size;
        uint64_t cqe_wait_timeout_millis;
        uint64_t max_delay_micros;
        struct io_uring_cqe** cqes;
        int32_t descriptor;
        uint32_t ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        uint32_t base_delay_micros;
        double delay_randomization_factor;
        uint8_t id;
    };

    int interactor_dart_initialize(struct interactor_dart* interactor, struct interactor_dart_configuration* configuration, uint8_t id);

    int32_t interactor_dart_get_static_buffer(struct interactor_dart* interactor);
    void interactor_dart_release_static_buffer(struct interactor_dart* interactor, int32_t buffer_id);
    int32_t interactor_dart_available_static_buffers(struct interactor_dart* interactor);
    int32_t interactor_dart_used_static_buffers(struct interactor_dart* interactor);

    struct interactor_input_buffer* interactor_dart_io_buffers_allocate_input(struct interactor_dart* interactor, size_t initial_capacity);
    struct interactor_output_buffer* interactor_dart_io_buffers_allocate_output(struct interactor_dart* interactor, size_t initial_capacity);
    void interactor_dart_io_buffers_free_input(struct interactor_dart* interactor, struct interactor_input_buffer* buffer);
    void interactor_dart_io_buffers_free_output(struct interactor_dart* interactor, struct interactor_output_buffer* buffer);
    void* interactor_dart_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size);
    void* interactor_dart_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size);
    void* interactor_dart_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size);
    void* interactor_dart_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size);

    struct interactor_message* interactor_dart_allocate_message(struct interactor_dart* interactor);
    void interactor_dart_free_message(struct interactor_dart* interactor, struct interactor_message* message);

    struct interactor_payload_pool* interactor_dart_payload_pool_create(struct interactor_dart* interactor, size_t size);
    intptr_t interactor_dart_payload_allocate(struct interactor_payload_pool* pool);
    void interactor_dart_payload_free(struct interactor_payload_pool* pool, intptr_t pointer);
    void interactor_dart_payload_pool_destroy(struct interactor_payload_pool* pool);

    intptr_t interactor_dart_data_allocate(struct interactor_dart* interactor, size_t size);
    void interactor_dart_data_free(struct interactor_dart* interactor, intptr_t pointer, size_t size);

    int interactor_dart_peek(struct interactor_dart* interactor);

    void interactor_dart_call_native(struct interactor_dart* interactor, int target_ring_fd, struct interactor_message* message);
    void interactor_dart_callback_to_native(struct interactor_dart* interactor, struct interactor_message* message);

    void interactor_dart_cqe_advance(struct io_uring* ring, int count);

    void interactor_dart_destroy(struct interactor_dart* interactor);

    void interactor_dart_close_descriptor(int fd);
    const char* interactor_dart_error_to_string(int error);

    struct interactor_memory* interactor_dart_memory(struct interactor_dart* interactor);

    uint64_t interactor_dart_tuple_next(const char* buffer, uint64_t offset);
#if defined(__cplusplus)
}
#endif

#endif