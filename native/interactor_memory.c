#include "interactor_memory.h"
#include <stddef.h>
#include "small/include/small/quota.h"
#include "small/include/small/small.h"
#include "small/mempool.h"
#include "small/slab_arena.h"
#include "small/slab_cache.h"

struct interactor_memory_context
{
    struct quota quota;
    struct slab_arena arena;
    struct slab_cache cache;
};

struct interactor_mempool_context
{
    struct mempool pool;
};

int interactor_memory_create(struct interactor_memory* memory, size_t quota_size, size_t preallocation_size, size_t slab_size)
{
    struct interactor_memory_context* context = malloc(sizeof(struct interactor_memory_context));
    int result;
    quota_init(&context->quota, quota_size);
    if ((result = slab_arena_create(&context->arena, &context->quota, preallocation_size, slab_size, MAP_PRIVATE))) return result;
    slab_cache_create(&context->cache, &context->arena);
    memory->context = context;
    return 0;
}

void interactor_memory_destroy(struct interactor_memory* memory)
{
    struct interactor_memory_context* context = memory->context;
    size_t slab_size = context->arena.slab_size;
    slab_cache_destroy(&context->cache);
    slab_arena_destroy(&context->arena);
    quota_release(&context->quota, slab_size);
}

int interactor_mempool_create(struct interactor_mempool* pool, size_t size)
{
    struct interactor_mempool_context* pool_context = malloc(sizeof(struct interactor_mempool_context));
    pool->context = pool_context;
    struct interactor_memory_context* memory_context = (struct interactor_memory_context*)pool->memory->context;
    mempool_create(&pool_context->pool, &memory_context->cache, size);
    return mempool_is_initialized(&pool_context->pool);
}

void interactor_mempool_destroy(struct interactor_mempool* pool)
{
    struct interactor_mempool_context* context = (struct interactor_mempool_context*)pool->context;
    mempool_destroy(&context->pool);
}

void* interactor_mempool_allocate(struct interactor_mempool* pool)
{
    struct interactor_mempool_context* context = (struct interactor_mempool_context*)pool->context;
    return mempool_alloc(&context->pool);
}

void interactor_mempool_free(struct interactor_mempool* pool, void* ptr)
{
    struct interactor_mempool_context* context = (struct interactor_mempool_context*)pool->context;
    mempool_free(&context->pool, ptr);
}
