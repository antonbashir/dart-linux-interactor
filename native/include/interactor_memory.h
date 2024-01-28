#ifndef INTERACTOR_MEMORY_H
#define INTERACTOR_MEMORY_H

#include <stddef.h>
#include "small/mempool.h"
#include "small/quota.h"
#include "small/slab_arena.h"
#include "small/slab_cache.h"
#include "small/small.h"
#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_memory
    {
        struct quota quota;
        struct slab_arena arena;
        struct slab_cache cache;
    };

    struct interactor_mempool
    {
        struct interactor_memory* memory;
        struct mempool pool;
    };

    struct interactor_small
    {
        struct interactor_memory* memory;
        struct small_alloc allocator;
    };

    int interactor_memory_create(struct interactor_memory* memory, size_t quota_size, size_t preallocation_size, size_t slab_size);
    void interactor_memory_destroy(struct interactor_memory* memory);

    int interactor_mempool_create(struct interactor_mempool* pool, size_t size);
    void interactor_mempool_destroy(struct interactor_mempool* pool);
    void* interactor_mempool_allocate(struct interactor_mempool* pool);
    void interactor_mempool_free(struct interactor_mempool* pool, void* ptr);

    int interactor_small_create(struct interactor_small* pool);
    void* interactor_small_allocate(struct interactor_small* pool, size_t size);
    void interactor_small_free(struct interactor_small* pool, void* ptr, size_t size);
    void interactor_small_destroy(struct interactor_small* pool);

#if defined(__cplusplus)
}
#endif

#endif
