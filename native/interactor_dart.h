#ifndef INTERACTOR_DART_IMPLEMENTATION_H
#define INTERACTOR_DART_IMPLEMENTATION_H

#include <bits/types/struct_iovec.h>
#include <interactor_message.h>
#include <stddef.h>
#include <stdint.h>

typedef struct io_uring interactor_dart_io_uring;
typedef struct io_uring_cqe interactor_dart_completion_event;
typedef struct interactor_messages_pool interactor_dart_messages_pool;
typedef struct interactor_static_buffers interactor_dart_static_buffers;
typedef struct interactor_io_buffers interactor_dart_io_buffers;
typedef struct interactor_small_data interactor_dart_small_data;
typedef struct interactor_memory interactor_dart_memory;

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
        interactor_dart_messages_pool* messages_pool;
        interactor_dart_static_buffers* static_buffers;
        interactor_dart_io_buffers* io_buffers;
        interactor_dart_small_data* small_data;
        interactor_dart_memory* memory;
        interactor_dart_io_uring* ring;
        size_t ring_size;
        uint64_t cqe_wait_timeout_millis;
        uint64_t max_delay_micros;
        double delay_randomization_factor;
        interactor_dart_completion_event** completions;
        int32_t descriptor;
        uint32_t ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        uint32_t base_delay_micros;
        uint8_t id;
    };

    int interactor_dart_initialize(struct interactor_dart* interactor, struct interactor_dart_configuration* configuration, uint8_t id);

    int32_t interactor_dart_static_buffers_get(struct interactor_dart* interactor);
    void interactor_dart_static_buffers_release(struct interactor_dart* interactor, int32_t buffer_id);
    int32_t interactor_dart_static_buffers_available(struct interactor_dart* interactor);
    int32_t interactor_dart_static_buffers_used(struct interactor_dart* interactor);
    struct iovec* interactor_dart_static_buffers_inner(struct interactor_dart* interactor);

    struct interactor_input_buffer* interactor_dart_io_buffers_allocate_input(struct interactor_dart* interactor, size_t initial_capacity);
    struct interactor_output_buffer* interactor_dart_io_buffers_allocate_output(struct interactor_dart* interactor, size_t initial_capacity);
    void interactor_dart_io_buffers_free_input(struct interactor_dart* interactor, struct interactor_input_buffer* buffer);
    void interactor_dart_io_buffers_free_output(struct interactor_dart* interactor, struct interactor_output_buffer* buffer);
    uint8_t* interactor_dart_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size);
    uint8_t* interactor_dart_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size);
    uint8_t* interactor_dart_input_buffer_allocate_reserve(struct interactor_input_buffer* buffer, size_t delta, size_t size);
    uint8_t* interactor_dart_input_buffer_read_position(struct interactor_input_buffer* buffer);
    uint8_t* interactor_dart_input_buffer_write_position(struct interactor_input_buffer* buffer);
    uint8_t* interactor_dart_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size);
    uint8_t* interactor_dart_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size);
    uint8_t* interactor_dart_output_buffer_allocate_reserve(struct interactor_output_buffer* buffer, size_t delta, size_t size);
    struct iovec* interactor_dart_output_buffer_content(struct interactor_output_buffer* buffer);

    struct interactor_message* interactor_dart_allocate_message(struct interactor_dart* interactor);
    void interactor_dart_free_message(struct interactor_dart* interactor, struct interactor_message* message);

    struct interactor_payload_pool* interactor_dart_payload_pool_create(struct interactor_dart* interactor, size_t size);
    void* interactor_dart_payload_allocate(struct interactor_payload_pool* pool);
    void interactor_dart_payload_free(struct interactor_payload_pool* pool, void* pointer);
    void interactor_dart_payload_pool_destroy(struct interactor_payload_pool* pool);
    size_t interactor_dart_payload_pool_size(struct interactor_payload_pool* pool);

    void* interactor_dart_data_allocate(struct interactor_dart* interactor, size_t size);
    void interactor_dart_data_free(struct interactor_dart* interactor, void* pointer, size_t size);

    int interactor_dart_peek(struct interactor_dart* interactor);

    void interactor_dart_call_native(struct interactor_dart* interactor, int target_ring_fd, struct interactor_message* message);
    void interactor_dart_callback_to_native(struct interactor_dart* interactor, struct interactor_message* message);

    void interactor_dart_cqe_advance(struct interactor_dart* interactor, int count);

    void interactor_dart_destroy(struct interactor_dart* interactor);

    void interactor_dart_close_descriptor(int fd);
    const char* interactor_dart_error_to_string(int error);

    uint64_t interactor_dart_tuple_next(const char* buffer, uint64_t offset);
#if defined(__cplusplus)
}
#endif

#endif