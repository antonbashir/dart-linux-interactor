#ifndef INTERACTOR_PAYLOADS_POOL_INCLUDED
#define INTERACTOR_PAYLOADS_POOL_INCLUDED

#include "trivia/util.h"
#include "interactor_constants.h"
#include "interactor_message.h"
#include "small/include/small/mempool.h"

struct interactor_payloads_pool
{
  struct mempool *memory_pool;
};

static inline int interactor_payloads_pool_create(struct interactor_payloads_pool *pool, struct slab_cache *slab_cache, size_t size)
{
  mempool_create(pool->memory_pool, slab_cache, size);
  return (pool->memory_pool == NULL ? -1 : 0);
}

static inline void interactor_payloads_pool_destroy(struct interactor_payloads_pool *pool)
{
  mempool_destroy(pool->memory_pool);
  pool->memory_pool = NULL;
}

static inline intptr_t interactor_payloads_pool_allocate(struct interactor_payloads_pool *pool)
{
  return (intptr_t)mempool_alloc(pool->memory_pool);
}

static inline void interactor_payloads_pool_free(struct interactor_payloads_pool *pool, intptr_t pointer)
{
  mempool_free(pool->memory_pool, (void*)pointer);
}

#endif
