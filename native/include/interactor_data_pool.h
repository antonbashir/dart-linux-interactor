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
        struct interactor_small pool;
    };

    int interactor_data_pool_create(struct interactor_data_pool* pool, struct interactor_memory* memory);
    void interactor_data_pool_destroy(struct interactor_data_pool* pool);
    intptr_t interactor_data_pool_allocate(struct interactor_data_pool* pool, size_t size);
    void interactor_data_pool_free(struct interactor_data_pool* pool, intptr_t payload, size_t size);

#if defined(__cplusplus)
}
#endif

#endif
