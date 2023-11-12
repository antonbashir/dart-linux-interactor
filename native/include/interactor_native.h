#ifndef INTERACTOR_NATIVE_H
#define INTERACTOR_NATIVE_H

#include <interactor_buffers_pool.h>
#include <interactor_message.h>
#include <interactor_messages_pool.h>
#include <interactor_payloads_pool.h>
#include <liburing.h>

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef struct interactor_native_configuration
    {
        uint16_t buffers_count;
        uint32_t buffer_size;
        size_t ring_size;
        int ring_flags;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
        uint64_t cqe_wait_timeout_millis;
        size_t quota_size;
        size_t preallocation_size;
        size_t slab_size;
    } interactor_native_configuration_t;

    typedef struct interactor_native
    {
        uint8_t id;
        struct interactor_messages_pool messages_pool;
        struct interactor_buffers_pool buffers_pool;
        struct interactor_memory memory;
        struct io_uring* ring;
        struct iovec* buffers;
        uint32_t buffer_size;
        uint16_t buffers_count;
        void* events;
        size_t ring_size;
        int ring_flags;
        struct io_uring_cqe** cqes;
        uint64_t cqe_wait_timeout_millis;
        uint32_t cqe_wait_count;
        uint32_t cqe_peek_count;
    } interactor_native_t;

    int interactor_native_initialize(interactor_native_t* interactor, interactor_native_configuration_t* configuration, uint8_t id);

    int interactor_native_initialize_default(interactor_native_t* interactor, uint8_t id);

    void interactor_native_cancel_by_fd(interactor_native_t* interactor, int fd);

    void interactor_native_check_event_timeouts(interactor_native_t* interactor);
    void interactor_native_remove_event(interactor_native_t* interactor, uint64_t data);

    int32_t interactor_native_get_buffer(interactor_native_t* interactor);
    void interactor_native_release_buffer(interactor_native_t* interactor, uint16_t buffer_id);
    int32_t interactor_native_available_buffers(interactor_native_t* interactor);
    int32_t interactor_native_used_buffers(interactor_native_t* interactor);

    interactor_message_t* interactor_native_allocate_message(interactor_native_t* interactor);
    void interactor_native_free_message(interactor_native_t* interactor, interactor_message_t* message);

    struct interactor_payloads_pool* interactor_native_payload_pool_create(interactor_native_t* interactor, size_t size);
    intptr_t interactor_native_payload_allocate(struct interactor_payloads_pool* pool);
    void interactor_native_payload_free(struct interactor_payloads_pool* pool, intptr_t pointer);
    void interactor_native_payload_pool_destroy(struct interactor_payloads_pool* pool);

    int interactor_native_peek_infinity(interactor_native_t* interactor);
    int interactor_native_peek_timeout(interactor_native_t* interactor);

    int interactor_native_submit(interactor_native_t* interactor);

    void interactor_native_destroy(interactor_native_t* interactor);

    void interactor_native_cqe_advance(struct io_uring* ring, int count);

    void interactor_native_close_descriptor(int fd);

    void interactor_native_call_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message);
    void interactor_native_callback_to_dart(interactor_native_t* interactor, int target_ring_fd, interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif