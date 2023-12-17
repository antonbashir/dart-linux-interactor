#ifndef INTERACTOR_DART_IMPLEMENTATION_H
#define INTERACTOR_DART_IMPLEMENTATION_H

#include <interactor_buffers_pool.h>
#include <interactor_data_pool.h>
#include <interactor_memory.h>
#include <interactor_messages_pool.h>
#include <interactor_payload_pool.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef struct interactor_dart_configuration
    {
        uint16_t buffers_count;
        uint32_t buffer_size;
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
    } interactor_dart_configuration_t;

    typedef struct interactor_dart
    {
        uint8_t id;
        int32_t descriptor;
        struct io_uring* ring;
        struct iovec* buffers;
        uint32_t buffer_size;
        uint16_t buffers_count;
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
        struct interactor_buffers_pool buffers_pool;
        struct interactor_data_pool data_pool;
        struct interactor_memory memory;
    } interactor_dart_t;

    int interactor_dart_initialize(interactor_dart_t* interactor, interactor_dart_configuration_t* configuration, uint8_t id);

    int32_t interactor_dart_get_buffer(interactor_dart_t* interactor);
    void interactor_dart_release_buffer(interactor_dart_t* interactor, uint16_t buffer_id);
    int32_t interactor_dart_available_buffers(interactor_dart_t* interactor);
    int32_t interactor_dart_used_buffers(interactor_dart_t* interactor);

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

#if defined(__cplusplus)
}
#endif

#endif