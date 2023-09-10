#ifndef INTERACTOR_MESSAGES_POOL_INCLUDED
#define INTERACTOR_MESSAGES_POOL_INCLUDED

#include "trivia/util.h"
#include "interactor_constants.h"
#include "interactor_message.h"
#include "small/include/small/small.h"

struct interactor_messages_pool
{
  struct mempool *memory_pool;
};

static inline int interactor_messages_pool_create(struct interactor_messages_pool *pool, struct slab_cache *slab_cache)
{
  mempool_create(pool->memory_pool, slab_cache, sizeof(interactor_message_t));
  return (pool->memory_pool == NULL ? -1 : 0);
}

static inline void interactor_messages_pool_destroy(struct interactor_messages_pool *pool)
{
  mempool_destroy(pool->memory_pool);
  pool->memory_pool = NULL;
}

static inline interactor_message_t* interactor_messages_pool_allocate(struct interactor_messages_pool *pool)
{
  return (interactor_message_t*)mempool_alloc(pool->memory_pool);
}

static inline void interactor_messages_pool_free(struct interactor_messages_pool *pool, interactor_message_t* message)
{
  mempool_free(pool->memory_pool, message);
}

#endif
