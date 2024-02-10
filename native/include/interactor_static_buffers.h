#ifndef INTERACTOR_STATIC_BUFFERS_H
#define INTERACTOR_STATIC_BUFFERS_H

#include <asm-generic/errno-base.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
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
        size_t count;
        size_t size;
        size_t capacity;
        int32_t* ids;
        struct iovec* buffers;
    };

    static inline int interactor_static_buffers_create(struct interactor_static_buffers* pool, size_t capacity, size_t size)
    {
        pool->size = size;
        pool->capacity = capacity;
        pool->count = 0;

        pool->ids = malloc(capacity * sizeof(int32_t));
        if (pool->ids == NULL)
        {
            return -1;
        }
        memset(pool->ids, 0, capacity * sizeof(int32_t));

        pool->buffers = malloc(capacity * sizeof(struct iovec));
        if (pool->buffers == NULL)
        {
            return -1;
        }

        size_t page_size = getpagesize();
        for (size_t index = 0; index < capacity; index++)
        {
            if (posix_memalign(&pool->buffers[index].iov_base, page_size, size))
            {
                return -1;
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
        if (interactor_unlikely(pool->count == 0))
            return INTERACTOR_BUFFER_USED;
        return pool->ids[--pool->count];
    }

#if defined(__cplusplus)
}
#endif

#endif
