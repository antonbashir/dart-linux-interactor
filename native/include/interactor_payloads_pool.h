#ifndef INTERACTOR_PAYLOADS_POOL_INCLUDED
#define INTERACTOR_PAYLOADS_POOL_INCLUDED

#include <interactor_memory.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_payloads_pool
    {
        struct interactor_mempool pool;
        size_t size;
    };

    int interactor_payloads_pool_create(struct interactor_payloads_pool* pool, struct interactor_memory* memory, size_t payload_size);
    void interactor_payloads_pool_destroy(struct interactor_payloads_pool* pool);
    intptr_t interactor_payloads_pool_allocate(struct interactor_payloads_pool* pool);
    void interactor_payloads_pool_free(struct interactor_payloads_pool* pool, intptr_t payload);

#if defined(__cplusplus)
}
#endif

#endif
