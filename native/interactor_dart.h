#ifndef INTERACTOR_DART_IMPLEMENTATION_H
#define INTERACTOR_DART_IMPLEMENTATION_H

#include <interactor_data_pool.h>
#include <interactor_memory.h>
#include <interactor_messages_pool.h>
#include <interactor_payload_pool.h>
#include <stdint.h>
#include "interactor_io_buffers.h"
#include "interactor_static_buffers.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef struct interactor_dart_configuration
    {
        size_t ring_size;
        int ring_flags;
        uint32_t base_delay_micros;
        double delay_randomization_factor;
        uint64_t max_delay_micros;
        uint64_t cqe_wait_timeout_millis;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        size_t quota_size;
        size_t preallocation_size;
        size_t slab_size;
        size_t static_buffers_capacity;
        size_t static_buffer_size;
    } interactor_dart_configuration_t;

    typedef struct interactor_dart
    {
        uint8_t id;
        int32_t descriptor;
        struct io_uring* ring;
        uint32_t base_delay_micros;
        double delay_randomization_factor;
        uint64_t max_delay_micros;
        size_t ring_size;
        int ring_flags;
        struct io_uring_cqe** cqes;
        uint64_t cqe_wait_timeout_millis;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        struct interactor_messages_pool messages_pool;
        struct interactor_static_buffers static_buffers;
        struct interactor_io_buffers io_buffers;
        struct interactor_data_pool data_pool;
        struct interactor_memory memory;
    } interactor_dart_t;

    int interactor_dart_initialize(interactor_dart_t* interactor, interactor_dart_configuration_t* configuration, uint8_t id);

    int32_t interactor_dart_get_static_buffer(interactor_dart_t* interactor);
    void interactor_dart_release_static_buffer(interactor_dart_t* interactor, int32_t buffer_id);
    int32_t interactor_dart_available_static_buffers(interactor_dart_t* interactor);
    int32_t interactor_dart_used_static_buffers(interactor_dart_t* interactor);

    interactor_input_buffer_t* interactor_dart_io_buffers_allocate_input(interactor_dart_t* interactor, size_t initial_capacity);
    interactor_output_buffer_t* interactor_dart_io_buffers_allocate_ouput(interactor_dart_t* interactor, size_t initial_capacity);
    void interactor_dart_io_buffers_free_input(interactor_dart_t* interactor, interactor_input_buffer_t* buffer);
    void interactor_dart_io_buffers_free_ouput(interactor_dart_t* interactor, interactor_output_buffer_t* buffer);
    void* interactor_dart_input_buffer_reserve(interactor_input_buffer_t* buffer, size_t size);
    void* interactor_dart_input_buffer_allocate(interactor_input_buffer_t* buffer, size_t size);
    void* interactor_dart_output_buffer_reserve(interactor_output_buffer_t* buffer, size_t size);
    void* interactor_dart_output_buffer_allocate(interactor_output_buffer_t* buffer, size_t size);

    interactor_message_t* interactor_dart_allocate_message(interactor_dart_t* interactor);
    void interactor_dart_free_message(interactor_dart_t* interactor, interactor_message_t* message);

    struct interactor_payload_pool* interactor_dart_payload_pool_create(interactor_dart_t* interactor, size_t size);
    intptr_t interactor_dart_payload_allocate(struct interactor_payload_pool* pool);
    void interactor_dart_payload_free(struct interactor_payload_pool* pool, intptr_t pointer);
    void interactor_dart_payload_pool_destroy(struct interactor_payload_pool* pool);

    intptr_t interactor_dart_data_allocate(interactor_dart_t* interactor, size_t size);
    void interactor_dart_data_free(interactor_dart_t* interactor, intptr_t pointer, size_t size);

    int interactor_dart_peek(interactor_dart_t* interactor);

    void interactor_dart_call_native(interactor_dart_t* interactor, int target_ring_fd, interactor_message_t* message);
    void interactor_dart_callback_to_native(interactor_dart_t* interactor, interactor_message_t* message);

    void interactor_dart_cqe_advance(struct io_uring* ring, int count);

    void interactor_dart_destroy(interactor_dart_t* interactor);

    void interactor_dart_close_descriptor(int fd);
    const char* interactor_dart_error_to_string(int error);

    interactor_memory_t* interactor_dart_memory(interactor_dart_t* interactor);

    uint64_t interactor_dart_tuple_next(const char* buffer, uint64_t offset);
#if defined(__cplusplus)
}
#endif

#endif