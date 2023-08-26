#include "interactor_common.h"
#include "interactor_dart.h"
#include "interactor_constants.h"

int interactor_dart_initialize(interactor_dart_t *dart,
                                 interactor_dart_configuration_t *configuration,
                                 uint8_t id)
{
  dart->id = id;
  dart->ring_size = configuration->ring_size;
  dart->delay_randomization_factor = configuration->delay_randomization_factor;
  dart->base_delay_micros = configuration->base_delay_micros;
  dart->max_delay_micros = configuration->max_delay_micros;
  dart->buffer_size = configuration->buffer_size;
  dart->buffers_count = configuration->buffers_count;
  dart->timeout_checker_period_millis = configuration->timeout_checker_period_millis;
  dart->cqes = malloc(sizeof(struct io_uring_cqe) * dart->ring_size);
  dart->buffers = malloc(sizeof(struct iovec) * configuration->buffers_count);
  dart->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
  dart->cqe_wait_count = configuration->cqe_wait_count;
  dart->cqe_peek_count = configuration->cqe_peek_count;
  dart->trace = configuration->trace;
  if (!dart->buffers)
  {
    return -ENOMEM;
  }

  dart->events = mh_events_new();
  if (!dart->events)
  {
    return -ENOMEM;
  }
  mh_events_reserve(dart->events, dart->buffers_count, 0);

  int result = interactor_buffers_pool_create(&dart->buffers_pool, configuration->buffers_count);
  if (result == -1)
  {
    return -ENOMEM;
  }

  for (size_t index = 0; index < configuration->buffers_count; index++)
  {
    if (posix_memalign(&dart->buffers[index].iov_base, getpagesize(), configuration->buffer_size))
    {
      return -ENOMEM;
    }
    memset(dart->buffers[index].iov_base, 0, configuration->buffer_size);
    dart->buffers[index].iov_len = configuration->buffer_size;

    interactor_buffers_pool_push(&dart->buffers_pool, index);
  }

  dart->ring = malloc(sizeof(struct io_uring));
  if (!dart->ring)
  {
    return -ENOMEM;
  }
  
  result = io_uring_queue_init(configuration->ring_size, dart->ring, configuration->ring_flags);
  if (result)
  {
    return result;
  }

  result = io_uring_register_buffers(dart->ring, dart->buffers, dart->buffers_count);
  if (result)
  {
    return result;
  }

  return 0;
}

int32_t interactor_dart_get_buffer(interactor_dart_t *dart)
{
  return interactor_buffers_pool_pop(&dart->buffers_pool);
}

int32_t interactor_dart_available_buffers(interactor_dart_t *dart)
{
  return dart->buffers_pool.count;
}

int32_t interactor_dart_used_buffers(interactor_dart_t *dart)
{
  return dart->buffers_count - dart->buffers_pool.count;
}

void interactor_dart_release_buffer(interactor_dart_t *dart, uint16_t buffer_id)
{
  struct iovec *buffer = &dart->buffers[buffer_id];
  memset(buffer->iov_base, 0, dart->buffer_size);
  buffer->iov_len = dart->buffer_size;
  interactor_buffers_pool_push(&dart->buffers_pool, buffer_id);
}

static inline void interactor_dart_add_event(interactor_dart_t *dart, int fd, uint64_t data, int64_t timeout)
{
  struct mh_events_node_t node = {
      .data = data,
      .timeout = timeout,
      .timestamp = time(NULL),
      .fd = fd,
  };
  mh_events_put(dart->events, &node, NULL, 0);
}

void interactor_dart_cancel_by_fd(interactor_dart_t *dart, int fd)
{
  mh_int_t index;
  mh_int_t to_delete[dart->events->size];
  int to_delete_count = 0;
  mh_foreach(dart->events, index)
  {
    struct mh_events_node_t *node = mh_events_node(dart->events, index);
    if (node->fd == fd)
    {
      struct io_uring *ring = dart->ring;
      struct io_uring_sqe *sqe = interactor_provide_sqe(ring);
      io_uring_prep_cancel(sqe, (void *)node->data, IORING_ASYNC_CANCEL_ALL);
      sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
      to_delete[to_delete_count++] = index;
    }
  }
  for (int index = 0; index < to_delete_count; index++)
  {
    mh_events_del(dart->events, to_delete[index], 0);
  }
  io_uring_submit(dart->ring);
}

int interactor_dart_peek(interactor_dart_t *dart)
{
  struct __kernel_timespec timeout = {
      .tv_nsec = dart->cqe_wait_timeout_millis * 1e+6,
      .tv_sec = 0,
  };
  io_uring_submit_and_wait_timeout(dart->ring, &dart->cqes[0], dart->cqe_wait_count, &timeout, 0);
  return io_uring_peek_batch_cqe(dart->ring, &dart->cqes[0], dart->cqe_peek_count);
}

void interactor_dart_check_event_timeouts(interactor_dart_t *dart)
{
  mh_int_t index;
  mh_int_t to_delete[dart->events->size];
  int to_delete_count = 0;
  mh_foreach(dart->events, index)
  {
    struct mh_events_node_t *node = mh_events_node(dart->events, index);
    int64_t timeout = node->timeout;
    if (timeout == INTERACTOR_TIMEOUT_INFINITY)
    {
      continue;
    }
    uint64_t timestamp = node->timestamp;
    uint64_t data = node->data;
    time_t current_time = time(NULL);
    if (current_time - timestamp > timeout)
    {
      struct io_uring *ring = dart->ring;
      struct io_uring_sqe *sqe = interactor_provide_sqe(ring);
      io_uring_prep_cancel(sqe, (void *)data, IORING_ASYNC_CANCEL_ALL);
      sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
      to_delete[to_delete_count++] = index;
    }
  }
  for (int index = 0; index < to_delete_count; index++)
  {
    mh_events_del(dart->events, to_delete[index], 0);
  }
  io_uring_submit(dart->ring);
}

void interactor_dart_remove_event(interactor_dart_t *dart, uint64_t data)
{
  mh_int_t event;
  if ((event = mh_events_find(dart->events, data, 0)) != mh_end(dart->events))
  {
    mh_events_del(dart->events, event, 0);
  }
}

void interactor_dart_destroy(interactor_dart_t *dart)
{
  io_uring_queue_exit(dart->ring);
  for (size_t index = 0; index < dart->buffers_count; index++)
  {
    free(dart->buffers[index].iov_base);
  }
  interactor_buffers_pool_destroy(&dart->buffers_pool);
  mh_events_delete(dart->events);
  free(dart->cqes);
  free(dart->buffers);
  free(dart->ring);
  free(dart);
}