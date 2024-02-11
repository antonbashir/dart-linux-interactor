#ifndef INTERACTOR_STATIC_BUFFERS_H
#define INTERACTOR_STATIC_BUFFERS_H

#include <bits/types/struct_iovec.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "interactor_constants.h"
#include "interactor_native_common.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct interactor_static_buffers
    {
        size_t available;
        size_t size;
        size_t capacity;
        int32_t* ids;
        struct iovec* buffers;
    };

    static inline int interactor_static_buffers_create(struct interactor_static_buffers* pool, size_t capacity, size_t size)
    {
        pool->size = size;
        pool->capacity = capacity;
        pool->available = 0;

        pool->ids = malloc(capacity * sizeof(int32_t));
        if (pool->ids == NULL)
        {
            return -1;
        }

        pool->buffers = malloc(capacity * sizeof(struct iovec));
        if (pool->buffers == NULL)
        {
            return -1;
        }

        int page_size = getpagesize();
        for (size_t index = 0; index < capacity; index++)
        {
            struct iovec* buffer = &pool->buffers[index];
            if (posix_memalign(&buffer->iov_base, page_size, size))
            {
                return -1;
            }
            memset(buffer->iov_base, 0, size);
            buffer->iov_len = size;
            pool->ids[pool->available++] = index;
        }

        return 0;
    }

    static inline void interactor_static_buffers_destroy(struct interactor_static_buffers* pool)
    {
        for (size_t index = 0; index < pool->capacity; index++)
        {
            struct iovec* buffer = &pool->buffers[index];
            free(buffer->iov_base);
        }
        free(pool->ids);
        free(pool->buffers);
    }

    static inline void interactor_static_buffers_push(struct interactor_static_buffers* pool, int32_t id)
    {
        struct iovec* buffer = &pool->buffers[id];
        memset(buffer->iov_base, 0, pool->size);
        buffer->iov_len = pool->size;
        pool->ids[pool->available++] = id;
    }

    static inline int32_t interactor_static_buffers_pop(struct interactor_static_buffers* pool)
    {
        if (interactor_unlikely(pool->available == 0))
            return INTERACTOR_BUFFER_USED;
        return pool->ids[--pool->available];
    }

#if defined(__cplusplus)
}
#endif

#endif
