#ifndef INTERACTOR_BUFFERS_POOL_H
#define INTERACTOR_BUFFERS_POOL_H

#include <asm-generic/errno-base.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/uio.h>
#include <unistd.h>
#include "interactor_constants.h"
#include "interactor_native_common.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct interactor_static_buffers
    {
        int32_t* ids;
        struct iovec* buffers;
        size_t count;
        size_t size;
        size_t capacity;
    };

    static inline int interactor_static_buffers_create(struct interactor_static_buffers* pool, size_t capacity, size_t size)
    {
        pool->size = size;
        pool->capacity = capacity;
        pool->count = 0;
        pool->ids = (int32_t*)malloc(size * sizeof(int32_t));
        if (pool->ids == NULL)
        {
            return -ENOMEM;
        }
        memset(pool->ids, 0, size * sizeof(int32_t));
        pool->buffers = (struct iovec*)malloc(size * sizeof(struct iovec));
        if (pool->ids == NULL)
        {
            return -ENOMEM;
        }
        memset(pool->ids, 0, size * sizeof(int32_t));

        for (size_t index = 0; index < capacity; index++)
        {
            if (posix_memalign(&pool->buffers[index].iov_base, getpagesize(), size))
            {
                return -ENOMEM;
            }
            memset(pool->buffers[index].iov_base, 0, size);
            pool->buffers[index].iov_len = size;
            pool->ids[pool->count++] = index;
        }

        return 0;
    }

    static inline void interactor_static_buffers_destroy(struct interactor_static_buffers* pool)
    {
        for (size_t index = 0; index < pool->count; index++)
        {
            free(pool->buffers[index].iov_base);
        }
        free(pool->ids);
        free(pool->buffers);
    }

    static inline void interactor_static_buffers_push(struct interactor_static_buffers* pool, int32_t id)
    {
        struct iovec* buffer = &pool->buffers[id];
        memset(buffer->iov_base, 0, pool->size);
        buffer->iov_len = pool->size;
        pool->ids[pool->count++] = id;
    }

    static inline int32_t interactor_static_buffers_pop(struct interactor_static_buffers* pool)
    {
        if (interactor_likely(pool->count == 0))
            return INTERACTOR_BUFFER_USED;
        return pool->ids[--pool->count];
    }

#if defined(__cplusplus)
}
#endif

#endif