#ifndef INTERACTOR_BUFFERS_POOL_H
#define INTERACTOR_BUFFERS_POOL_H

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "interactor_constants.h"

#if __has_builtin(__builtin_expect) || defined(__GNUC__)
#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)
#else
#define likely(x) (x)
#define unlikely(x) (x)
#endif

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

    inline int interactor_buffers_pool_create(struct interactor_buffers_pool* pool, size_t size)
    {
        pool->size = size;
        pool->count = 0;
        pool->ids = (int32_t*)malloc(size * sizeof(int32_t));
        memset(pool->ids, 0, size * sizeof(int32_t));
        return (pool->ids == NULL ? -1 : 0);
    }

    inline void interactor_buffers_pool_destroy(struct interactor_buffers_pool* pool)
    {
        free(pool->ids);
        pool->ids = NULL;
    }

    inline void interactor_buffers_pool_push(struct interactor_buffers_pool* pool, int32_t id)
    {
        pool->ids[pool->count++] = id;
    }

    inline int32_t interactor_buffers_pool_pop(struct interactor_buffers_pool* pool)
    {
        if (unlikely(pool->count == 0))
            return INTERACTOR_BUFFER_USED;
        return pool->ids[--pool->count];
    }

#if defined(__cplusplus)
}
#endif

#endif
