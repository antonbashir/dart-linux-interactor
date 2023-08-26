#ifndef INTERACTOR_dart_H
#define INTERACTOR_dart_H

#include <stdint.h>
#include <stdio.h>
#include "interactor_common.h"
#include "interactor_collections.h"
#include "interactor_buffers_pool.h"
#include "interactor_messages_pool.h"
#include "interactor_payloads_pool.h"

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
    uint64_t timeout_checker_period_millis;
    uint32_t base_delay_micros;
    double delay_randomization_factor;
    uint64_t max_delay_micros;
    uint64_t cqe_wait_timeout_millis;
    uint32_t cqe_wait_count;
    uint32_t cqe_peek_count;
    bool trace;
  } interactor_dart_configuration_t;

  typedef struct interactor_dart
  {
    uint8_t id;
    struct interactor_messages_pool messages_pool;
    struct interactor_buffers_pool buffers_pool;
    struct io_uring *ring;
    struct iovec *buffers;
    uint32_t buffer_size;
    uint16_t buffers_count;
    uint64_t timeout_checker_period_millis;
    uint32_t base_delay_micros;
    double delay_randomization_factor;
    uint64_t max_delay_micros;
    struct mh_events_t *events;
    size_t ring_size;
    int ring_flags;
    struct io_uring_cqe **cqes;
    uint64_t cqe_wait_timeout_millis;
    uint32_t cqe_wait_count;
    uint32_t cqe_peek_count;
    bool trace;
    struct quota quota;
    struct slab_arena arena;
    struct slab_cache cache;
  } interactor_dart_t;

  int interactor_dart_initialize(interactor_dart_t *interactor,
                                 interactor_dart_configuration_t *configuration,
                                 uint8_t id);

  void interactor_dart_cancel_by_fd(interactor_dart_t *interactor, int fd);

  void interactor_dart_check_event_timeouts(interactor_dart_t *interactor);
  void interactor_dart_remove_event(interactor_dart_t *interactor, uint64_t data);

  int32_t interactor_dart_get_buffer(interactor_dart_t *interactor);
  void interactor_dart_release_buffer(interactor_dart_t *interactor, uint16_t buffer_id);
  int32_t interactor_dart_available_buffers(interactor_dart_t *interactor);
  int32_t interactor_dart_used_buffers(interactor_dart_t *interactor);

  interactor_message_t *interactor_dart_allocate_message(interactor_dart_t *interactor);
  void interactor_dart_free_message(interactor_dart_t *interactor, interactor_message_t *message);

  struct interactor_payloads_pool *interactor_dart_payload_pool_create(interactor_dart_t *interactor, size_t size);
  intptr_t interactor_dart_payload_allocate(struct interactor_payloads_pool *pool);
  void interactor_dart_payload_free(struct interactor_payloads_pool *pool, intptr_t pointer);
  void interactor_dart_payload_pool_destroy(struct interactor_payloads_pool *pool);

  int interactor_dart_peek(interactor_dart_t *interactor);

  void interactor_dart_destroy(interactor_dart_t *interactor);

#if defined(__cplusplus)
}
#endif

#endif