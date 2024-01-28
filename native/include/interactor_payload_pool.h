#ifndef INTERACTOR_PAYLOADS_POOL_INCLUDED
#define INTERACTOR_PAYLOADS_POOL_INCLUDED

#include <interactor_memory.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_payload_pool
    {
        struct interactor_mempool pool;
        size_t size;
    };

    static inline int interactor_payload_pool_create(struct interactor_payload_pool* pool, struct interactor_memory* memory, size_t payload_size)
    {
        pool->pool.memory = memory;
        pool->size = payload_size;
        return interactor_mempool_create(&pool->pool, payload_size);
    }

    static inline void interactor_payload_pool_destroy(struct interactor_payload_pool* pool)
    {
        interactor_mempool_destroy(&pool->pool);
    }

    static inline intptr_t interactor_payload_pool_allocate(struct interactor_payload_pool* pool)
    {
        return (intptr_t)interactor_mempool_allocate(&pool->pool);
    }

    static inline void interactor_payload_pool_free(struct interactor_payload_pool* pool, intptr_t payload)
    {
        interactor_mempool_free(&pool->pool, (void*)payload);
    }

#if defined(__cplusplus)
}
#endif

#endif
