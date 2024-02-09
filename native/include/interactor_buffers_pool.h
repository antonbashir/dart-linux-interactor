#ifndef INTERACTOR_BUFFERS_POOL_H
#define INTERACTOR_BUFFERS_POOL_H

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "interactor_constants.h"
#include "interactor_native_common.h"

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

    static inline int interactor_buffers_pool_create(struct interactor_buffers_pool* pool, size_t size)
    {
        pool->size = size;
        pool->count = 0;
        pool->ids = (int32_t*)malloc(size * sizeof(int32_t));
        memset(pool->ids, 0, size * sizeof(int32_t));
        return (pool->ids == NULL ? -1 : 0);
    }

    static inline void interactor_buffers_pool_destroy(struct interactor_buffers_pool* pool)
    {
        free(pool->ids);
        pool->ids = NULL;
    }

    static inline void interactor_buffers_pool_push(struct interactor_buffers_pool* pool, int32_t id)
    {
        pool->ids[pool->count++] = id;
    }

    static inline int32_t interactor_buffers_pool_pop(struct interactor_buffers_pool* pool)
    {
        if (interactor_likely(pool->count == 0))
            return INTERACTOR_BUFFER_USED;
        return pool->ids[--pool->count];
    }

#if defined(__cplusplus)
}
#endif

#endif
