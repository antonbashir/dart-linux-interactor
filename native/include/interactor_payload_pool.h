#ifndef INTERACTOR_PAYLOADS_POOL_INCLUDED
#define INTERACTOR_PAYLOADS_POOL_INCLUDED

#include <interactor_memory.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_payload_pool
    {
        struct interactor_pool pool;
        size_t size;
    };

    static inline int interactor_payload_pool_create(struct interactor_payload_pool* pool, struct interactor_memory* memory, size_t payload_size)
    {
        return interactor_pool_create(&pool->pool, memory, payload_size);
    }

    static inline void interactor_payload_pool_destroy(struct interactor_payload_pool* pool)
    {
        interactor_pool_destroy(&pool->pool);
    }

    static inline void* interactor_payload_pool_allocate(struct interactor_payload_pool* pool)
    {
        return interactor_pool_allocate(&pool->pool);
    }

    static inline void interactor_payload_pool_free(struct interactor_payload_pool* pool, void* payload)
    {
        interactor_pool_free(&pool->pool, payload);
    }

#if defined(__cplusplus)
}
#endif

#endif
