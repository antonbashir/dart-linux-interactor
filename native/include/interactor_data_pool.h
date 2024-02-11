#ifndef INTERACTOR_DATA_POOL_INCLUDED
#define INTERACTOR_DATA_POOL_INCLUDED

#include <interactor_memory.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_small_data
    {
        struct interactor_small_allocator pool;
    };

    static inline int interactor_small_data_create(struct interactor_small_data* pool, struct interactor_memory* memory)
    {
        return interactor_small_allocator_create(&pool->pool, memory);
    }

    static inline void interactor_small_data_destroy(struct interactor_small_data* pool)
    {
        interactor_small_allocator_destroy(&pool->pool);
    }

    static inline void* interactor_small_data_allocate(struct interactor_small_data* pool, size_t data_size)
    {
        return interactor_small_allocator_allocate(&pool->pool, data_size);
    }

    static inline void interactor_small_data_free(struct interactor_small_data* pool, void* data, size_t data_size)
    {
        interactor_small_allocator_free(&pool->pool, data, data_size);
    }

#if defined(__cplusplus)
}
#endif

#endif
