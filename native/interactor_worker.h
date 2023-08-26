#ifndef INTERACTOR_WORKER_H
#define INTERACTOR_WORKER_H

#include <stdint.h>
#include <stdio.h>
#include "interactor_common.h"
#include "interactor_collections.h"
#include "interactor_buffers_pool.h"

#if defined(__cplusplus)
extern "C"
{
#endif
  typedef struct interactor_worker_configuration
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
  } interactor_worker_configuration_t;

  typedef struct interactor_worker
  {
    uint8_t id;
    struct interactor_buffers_pool free_buffers;
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
  } interactor_worker_t;

  int interactor_worker_initialize(interactor_worker_t *worker,
                                  interactor_worker_configuration_t *configuration,
                                  uint8_t id);

  void interactor_worker_cancel_by_fd(interactor_worker_t *worker, int fd);

  void interactor_worker_check_event_timeouts(interactor_worker_t *worker);
  void interactor_worker_remove_event(interactor_worker_t *worker, uint64_t data);

  int32_t interactor_worker_get_buffer(interactor_worker_t *worker);
  void interactor_worker_release_buffer(interactor_worker_t *worker, uint16_t buffer_id);
  int32_t interactor_worker_available_buffers(interactor_worker_t *worker);
  int32_t interactor_worker_used_buffers(interactor_worker_t *worker);

  int interactor_worker_peek(interactor_worker_t *worker);

  void interactor_worker_destroy(interactor_worker_t *worker);

#if defined(__cplusplus)
}
#endif

#endif