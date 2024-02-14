#ifndef INTERACTOR_NATIVE_H
#define INTERACTOR_NATIVE_H

#include <interactor_message.h>
#include <stddef.h>
#include <stdint.h>

typedef struct mh_native_callbacks_t interactor_native_callbacks_t;
typedef struct io_uring interactor_native_io_uring;
typedef struct io_uring_cqe interactor_native_completion_event;
typedef struct interactor_messages_pool interactor_native_messages_pool;
typedef struct interactor_static_buffers interactor_native_static_buffers;
typedef struct interactor_io_buffers interactor_native_io_buffers;
typedef struct interactor_small_data interactor_native_small_data;
typedef struct interactor_memory interactor_native_memory;

#if defined(__cplusplus)
extern "C"
{
#endif
    struct interactor_native_configuration
    {
        uint64_t cqe_wait_timeout_millis;
        size_t quota_size;
        size_t preallocation_size;
        size_t slab_size;
        size_t static_buffers_capacity;
        size_t static_buffer_size;
        size_t ring_size;
        int32_t ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
    };

    struct interactor_native
    {
        interactor_native_messages_pool* messages_pool;
        interactor_native_static_buffers* static_buffers;
        interactor_native_io_buffers* io_buffers;
        interactor_native_small_data* small_data;
        interactor_native_memory* memory;
        interactor_native_io_uring* ring;
        uint64_t cqe_wait_timeout_millis;
        size_t ring_size;
        interactor_native_completion_event** completions;
        interactor_native_callbacks_t* callbacks;
        int32_t descriptor;
        int32_t ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        uint8_t id;
    };

    int interactor_native_initialize(struct interactor_native* interactor, struct interactor_native_configuration* configuration, uint8_t id);

    int interactor_native_initialize_default(struct interactor_native* interactor, uint8_t id);

    void interactor_native_register_callback(struct interactor_native* interactor, uint64_t owner, uint64_t method, void (*callback)(struct interactor_message*));

    int32_t interactor_native_get_static_buffer(struct interactor_native* interactor);
    void interactor_native_release_static_buffer(struct interactor_native* interactor, int32_t buffer_id);
    int32_t interactor_native_available_static_buffers(struct interactor_native* interactor);
    int32_t interactor_native_used_static_buffers(struct interactor_native* interactor);

    struct interactor_input_buffer* interactor_native_io_buffers_allocate_input(struct interactor_native* interactor, size_t initial_capacity);
    struct interactor_output_buffer* interactor_native_io_buffers_allocate_output(struct interactor_native* interactor, size_t initial_capacity);
    void interactor_native_io_buffers_free_input(struct interactor_native* interactor, struct interactor_input_buffer* buffer);
    void interactor_native_io_buffers_free_output(struct interactor_native* interactor, struct interactor_output_buffer* buffer);
    uint8_t* interactor_native_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size);
    uint8_t* interactor_native_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size);
    uint8_t* interactor_native_input_buffer_allocate_reserve(struct interactor_input_buffer* buffer, size_t delta, size_t size);
    uint8_t* interactor_native_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size);
    uint8_t* interactor_native_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size);
    uint8_t* interactor_native_output_buffer_allocate_reserve(struct interactor_output_buffer* buffer, size_t delta, size_t size);

    struct interactor_message* interactor_native_allocate_message(struct interactor_native* interactor);
    void interactor_native_free_message(struct interactor_native* interactor, struct interactor_message* message);

    struct interactor_payload_pool* interactor_native_payload_pool_create(struct interactor_native* interactor, size_t size);
    void* interactor_native_payload_allocate(struct interactor_payload_pool* pool);
    void interactor_native_payload_free(struct interactor_payload_pool* pool, void* pointer);
    void interactor_native_payload_pool_destroy(struct interactor_payload_pool* pool);

    void* interactor_native_data_allocate(struct interactor_native* interactor, size_t size);
    void interactor_native_data_free(struct interactor_native* interactor, void* pointer, size_t size);

    int interactor_native_count_ready(struct interactor_native* interactor);
    int interactor_native_count_ready_submit(struct interactor_native* interactor);

    void interactor_native_process(struct interactor_native* interactor);
    void interactor_native_process_infinity(struct interactor_native* interactor);
    void interactor_native_process_timeout(struct interactor_native* interactor);

    void interactor_native_foreach(struct interactor_native* interactor, void (*call)(struct interactor_message*), void (*callback)(struct interactor_message*));

    int interactor_native_submit(struct interactor_native* interactor);

    void interactor_native_call_dart(struct interactor_native* interactor, int target_ring_fd, struct interactor_message* message);
    void interactor_native_callback_to_dart(struct interactor_native* interactor, struct interactor_message* message);

    void interactor_native_destroy(struct interactor_native* interactor);

    void interactor_native_close_descriptor(int fd);

#if defined(__cplusplus)
}
#endif

#endif