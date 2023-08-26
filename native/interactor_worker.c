#include "interactor_common.h"
#include "interactor_worker.h"
#include "interactor_constants.h"

int interactor_worker_initialize(interactor_worker_t *worker,
                                 interactor_worker_configuration_t *configuration,
                                 uint8_t id)
{
  worker->id = id;
  worker->ring_size = configuration->ring_size;
  worker->delay_randomization_factor = configuration->delay_randomization_factor;
  worker->base_delay_micros = configuration->base_delay_micros;
  worker->max_delay_micros = configuration->max_delay_micros;
  worker->buffer_size = configuration->buffer_size;
  worker->buffers_count = configuration->buffers_count;
  worker->timeout_checker_period_millis = configuration->timeout_checker_period_millis;
  worker->cqes = malloc(sizeof(struct io_uring_cqe) * worker->ring_size);
  worker->buffers = malloc(sizeof(struct iovec) * configuration->buffers_count);
  worker->cqe_wait_timeout_millis = configuration->cqe_wait_timeout_millis;
  worker->cqe_wait_count = configuration->cqe_wait_count;
  worker->cqe_peek_count = configuration->cqe_peek_count;
  worker->trace = configuration->trace;
  if (!worker->buffers)
  {
    return -ENOMEM;
  }

  worker->events = mh_events_new();
  if (!worker->events)
  {
    return -ENOMEM;
  }
  mh_events_reserve(worker->events, worker->buffers_count, 0);

  int result = interactor_buffers_pool_create(&worker->free_buffers, configuration->buffers_count);
  if (result == -1)
  {
    return -ENOMEM;
  }

  for (size_t index = 0; index < configuration->buffers_count; index++)
  {
    if (posix_memalign(&worker->buffers[index].iov_base, getpagesize(), configuration->buffer_size))
    {
      return -ENOMEM;
    }
    memset(worker->buffers[index].iov_base, 0, configuration->buffer_size);
    worker->buffers[index].iov_len = configuration->buffer_size;

    interactor_buffers_pool_push(&worker->free_buffers, index);
  }
  worker->ring = malloc(sizeof(struct io_uring));
  if (!worker->ring)
  {
    return -ENOMEM;
  }
  result = io_uring_queue_init(configuration->ring_size, worker->ring, configuration->ring_flags);
  if (result)
  {
    return result;
  }

  result = io_uring_register_buffers(worker->ring, worker->buffers, worker->buffers_count);
  if (result)
  {
    return result;
  }

  return 0;
}

int32_t interactor_worker_get_buffer(interactor_worker_t *worker)
{
  return interactor_buffers_pool_pop(&worker->free_buffers);
}

int32_t interactor_worker_available_buffers(interactor_worker_t *worker)
{
  return worker->free_buffers.count;
}

int32_t interactor_worker_used_buffers(interactor_worker_t *worker)
{
  return worker->buffers_count - worker->free_buffers.count;
}

void interactor_worker_release_buffer(interactor_worker_t *worker, uint16_t buffer_id)
{
  struct iovec *buffer = &worker->buffers[buffer_id];
  memset(buffer->iov_base, 0, worker->buffer_size);
  buffer->iov_len = worker->buffer_size;
  interactor_buffers_pool_push(&worker->free_buffers, buffer_id);
}

static inline void interactor_worker_add_event(interactor_worker_t *worker, int fd, uint64_t data, int64_t timeout)
{
  struct mh_events_node_t node = {
      .data = data,
      .timeout = timeout,
      .timestamp = time(NULL),
      .fd = fd,
  };
  mh_events_put(worker->events, &node, NULL, 0);
}

void interactor_worker_cancel_by_fd(interactor_worker_t *worker, int fd)
{
  mh_int_t index;
  mh_int_t to_delete[worker->events->size];
  int to_delete_count = 0;
  mh_foreach(worker->events, index)
  {
    struct mh_events_node_t *node = mh_events_node(worker->events, index);
    if (node->fd == fd)
    {
      struct io_uring *ring = worker->ring;
      struct io_uring_sqe *sqe = interactor_provide_sqe(ring);
      io_uring_prep_cancel(sqe, (void *)node->data, IORING_ASYNC_CANCEL_ALL);
      sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
      to_delete[to_delete_count++] = index;
    }
  }
  for (int index = 0; index < to_delete_count; index++)
  {
    mh_events_del(worker->events, to_delete[index], 0);
  }
  io_uring_submit(worker->ring);
}

int interactor_worker_peek(interactor_worker_t *worker)
{
  struct __kernel_timespec timeout = {
      .tv_nsec = worker->cqe_wait_timeout_millis * 1e+6,
      .tv_sec = 0,
  };
  io_uring_submit_and_wait_timeout(worker->ring, &worker->cqes[0], worker->cqe_wait_count, &timeout, 0);
  return io_uring_peek_batch_cqe(worker->ring, &worker->cqes[0], worker->cqe_peek_count);
}

void interactor_worker_check_event_timeouts(interactor_worker_t *worker)
{
  mh_int_t index;
  mh_int_t to_delete[worker->events->size];
  int to_delete_count = 0;
  mh_foreach(worker->events, index)
  {
    struct mh_events_node_t *node = mh_events_node(worker->events, index);
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
      struct io_uring *ring = worker->ring;
      struct io_uring_sqe *sqe = interactor_provide_sqe(ring);
      io_uring_prep_cancel(sqe, (void *)data, IORING_ASYNC_CANCEL_ALL);
      sqe->flags |= IOSQE_CQE_SKIP_SUCCESS;
      to_delete[to_delete_count++] = index;
    }
  }
  for (int index = 0; index < to_delete_count; index++)
  {
    mh_events_del(worker->events, to_delete[index], 0);
  }
  io_uring_submit(worker->ring);
}

void interactor_worker_remove_event(interactor_worker_t *worker, uint64_t data)
{
  mh_int_t event;
  if ((event = mh_events_find(worker->events, data, 0)) != mh_end(worker->events))
  {
    mh_events_del(worker->events, event, 0);
  }
}

void interactor_worker_destroy(interactor_worker_t *worker)
{
  io_uring_queue_exit(worker->ring);
  for (size_t index = 0; index < worker->buffers_count; index++)
  {
    free(worker->buffers[index].iov_base);
  }
  interactor_buffers_pool_destroy(&worker->free_buffers);
  mh_events_delete(worker->events);
  free(worker->cqes);
  free(worker->buffers);
  free(worker->ring);
  free(worker);
}