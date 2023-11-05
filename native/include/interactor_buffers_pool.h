#ifndef INTERACTOR_BUFFERS_POOL_H
#define INTERACTOR_BUFFERS_POOL_H

#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_buffers_pool
    {
        int32_t* ids;
        size_t count;
        size_t size;
    };

    int interactor_buffers_pool_create(struct interactor_buffers_pool* pool, size_t size);
    void interactor_buffers_pool_destroy(struct interactor_buffers_pool* pool);
    void interactor_buffers_pool_push(struct interactor_buffers_pool* pool, int32_t id);
    int32_t interactor_buffers_pool_pop(struct interactor_buffers_pool* pool);

#if defined(__cplusplus)
}
#endif

#endif
