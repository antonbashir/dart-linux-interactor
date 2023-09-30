#include "interactor_buffers_pool.h"
#include "interactor_constants.h"
#include "trivia/util.h"

int interactor_buffers_pool_create(struct interactor_buffers_pool *pool,
                                   size_t size) {
  pool->size = size;
  pool->count = 0;
  pool->ids = (int32_t *)malloc(size * sizeof(int32_t));
  memset(pool->ids, 0, size * sizeof(int32_t));
  return (pool->ids == NULL ? -1 : 0);
}

void interactor_buffers_pool_destroy(struct interactor_buffers_pool *pool) {
  free(pool->ids);
  pool->ids = NULL;
}

void interactor_buffers_pool_push(struct interactor_buffers_pool *pool,
                                  int32_t id) {
  pool->ids[pool->count++] = id;
}

int32_t interactor_buffers_pool_pop(struct interactor_buffers_pool *pool) {
  if (unlikely(pool->count == 0))
    return INTERACTOR_BUFFER_USED;
  return pool->ids[--pool->count];
}
