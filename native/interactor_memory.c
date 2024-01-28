#include <interactor_memory.h>
#include <stddef.h>

int interactor_memory_create(struct interactor_memory* memory, size_t quota_size, size_t preallocation_size, size_t slab_size)
{
    int result;
    quota_init(&memory->quota, quota_size);
    if ((result = slab_arena_create(&memory->arena, &memory->quota, preallocation_size, slab_size, MAP_PRIVATE))) return result;
    slab_cache_create(&memory->cache, &memory->arena);
    return 0;
}

void interactor_memory_destroy(struct interactor_memory* memory)
{
    slab_cache_destroy(&memory->cache);
    slab_arena_destroy(&memory->arena);
    if (quota_used(&memory->quota))
    {
        quota_release(&memory->quota, quota_used(&memory->quota));
    }
}

int interactor_mempool_create(struct interactor_mempool* pool, size_t size)
{
    mempool_create(&pool->pool, &pool->memory->cache, size);
    return mempool_is_initialized(&pool->pool) ? 0 : -1;
}

void interactor_mempool_destroy(struct interactor_mempool* pool)
{
    mempool_destroy(&pool->pool);
}

void* interactor_mempool_allocate(struct interactor_mempool* pool)
{
    return mempool_alloc(&pool->pool);
}

void interactor_mempool_free(struct interactor_mempool* pool, void* ptr)
{
    mempool_free(&pool->pool, ptr);
}

int interactor_small_create(struct interactor_small* pool)
{
    float actual_alloc_factor;
    small_alloc_create(&pool->allocator, &pool->memory->cache, 3 * sizeof(int), sizeof(intptr_t), 1.05, &actual_alloc_factor);
    return pool->allocator.cache == NULL ? -1 : 0;
}

void* interactor_small_allocate(struct interactor_small* pool, size_t size)
{
    return (void*)smalloc(&pool->allocator, size);
}

void interactor_small_free(struct interactor_small* pool, void* ptr, size_t size)
{
    smfree(&pool->allocator, ptr, size);
}

void interactor_small_destroy(struct interactor_small* pool)
{
    small_alloc_destroy(&pool->allocator);
}
