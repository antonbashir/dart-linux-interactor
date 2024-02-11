#ifndef INTERACTOR_DATA_POOL_INCLUDED
#define INTERACTOR_DATA_POOL_INCLUDED

#include <interactor_memory.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_data_pool
    {
        struct interactor_small_allocator pool;
    };

    static inline int interactor_data_pool_create(struct interactor_data_pool* pool, struct interactor_memory* memory)
    {
        return interactor_small_allocator_create(&pool->pool, memory);
    }

    static inline void interactor_data_pool_destroy(struct interactor_data_pool* pool)
    {
        interactor_small_allocator_destroy(&pool->pool);
    }

    static inline intptr_t interactor_data_pool_allocate(struct interactor_data_pool* pool, size_t data_size)
    {
        return (intptr_t)interactor_small_allocator_allocate(&pool->pool, data_size);
    }

    static inline void interactor_data_pool_free(struct interactor_data_pool* pool, intptr_t data, size_t data_size)
    {
        interactor_small_allocator_free(&pool->pool, (void*)data, data_size);
    }

#if defined(__cplusplus)
}
#endif

#endif
