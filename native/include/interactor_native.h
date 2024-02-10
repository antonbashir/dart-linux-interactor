#ifndef INTERACTOR_NATIVE_H
#define INTERACTOR_NATIVE_H

#include <interactor_data_pool.h>
#include <interactor_message.h>
#include <interactor_messages_pool.h>
#include <interactor_payload_pool.h>
#include <liburing.h>
#include "interactor_io_buffers.h"
#include "interactor_static_buffers.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef struct interactor_native_configuration
    {
        size_t ring_size;
        int ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        uint64_t cqe_wait_timeout_millis;
        size_t quota_size;
        size_t preallocation_size;
        size_t slab_size;
        size_t static_buffers_capacity;
        size_t static_buffer_size;
    } interactor_native_configuration_t;

    typedef struct interactor_native
    {
        uint8_t id;
        int32_t descriptor;
        struct interactor_messages_pool messages_pool;
        struct interactor_static_buffers static_buffers;
        struct interactor_io_buffers io_buffers;
        struct interactor_data_pool data_pool;
        struct interactor_memory memory;
        struct io_uring* ring;
        size_t ring_size;
        int ring_flags;
        struct io_uring_cqe** cqes;
        uint64_t cqe_wait_timeout_millis;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        void* callbacks;
    } interactor_native_t;

    int interactor_native_initialize(interactor_native_t* interactor, interactor_native_configuration_t* configuration, uint8_t id);

    int interactor_native_initialize_default(interactor_native_t* interactor, uint8_t id);

    void interactor_native_register_callback(interactor_native_t* interactor, uint64_t owner, uint64_t method, void (*callback)(interactor_message_t*));

    int32_t interactor_native_get_static_buffer(interactor_native_t* interactor);
    void interactor_native_release_static_buffer(interactor_native_t* interactor, int32_t buffer_id);
    int32_t interactor_native_available_static_buffers(interactor_native_t* interactor);
    int32_t interactor_native_used_static_buffers(interactor_native_t* interactor);

    interactor_input_buffer_t* interactor_native_io_buffers_allocate_input(interactor_native_t* interactor, size_t initial_capacity);
    interactor_output_buffer_t* interactor_native_io_buffers_allocate_output(interactor_native_t* interactor, size_t initial_capacity);
    void interactor_native_io_buffers_free_input(interactor_native_t* interactor, interactor_input_buffer_t* buffer);
    void interactor_native_io_buffers_free_output(interactor_native_t* interactor, interactor_output_buffer_t* buffer);
    void* interactor_native_input_buffer_reserve(interactor_input_buffer_t* buffer, size_t size);
    void* interactor_native_input_buffer_allocate(interactor_input_buffer_t* buffer, size_t size);
    void* interactor_native_output_buffer_reserve(interactor_output_buffer_t* buffer, size_t size);
    void* interactor_native_output_buffer_allocate(interactor_output_buffer_t* buffer, size_t size);

    interactor_message_t* interactor_native_allocate_message(interactor_native_t* interactor);
    void interactor_native_free_message(interactor_native_t* interactor, interactor_message_t* message);

    struct interactor_payload_pool* interactor_native_payload_pool_create(interactor_native_t* interactor, size_t size);
    intptr_t interactor_native_payload_allocate(struct interactor_payload_pool* pool);
    void interactor_native_payload_free(struct interactor_payload_pool* pool, intptr_t pointer);
    void interactor_native_payload_pool_destroy(struct interactor_payload_pool* pool);

    intptr_t interactor_native_data_allocate(interactor_native_t* interactor, size_t size);
    void interactor_native_data_free(interactor_native_t* interactor, intptr_t pointer, size_t size);

    int interactor_native_count_ready(interactor_native_t* interactor);
    int interactor_native_count_ready_submit(interactor_native_t* interactor);

    void interactor_native_process(interactor_native_t* interactor);
    void interactor_native_process_infinity(interactor_native_t* interactor);
    void interactor_native_process_timeout(interactor_native_t* interactor);

    void interactor_native_foreach(interactor_native_t* interactor, void (*call)(interactor_message_t*), void (*callback)(interactor_message_t*));

    int interactor_native_submit(interactor_native_t* interactor);

    void interactor_native_call_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message);
    void interactor_native_callback_to_dart(interactor_native_t* interactor, interactor_message_t* message);

    void interactor_native_destroy(interactor_native_t* interactor);

    void interactor_native_close_descriptor(int fd);

#if defined(__cplusplus)
}
#endif

#endif