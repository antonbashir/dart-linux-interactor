#ifndef INTERACTOR_IO_BUFFERS_H
#define INTERACTOR_IO_BUFFERS_H

#include <stddef.h>
#include "interactor_memory.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct interactor_io_buffers
    {
        struct interactor_pool input_buffers;
        struct interactor_pool output_buffers;
        struct interactor_memory* memory;
    };

    static inline int interactor_io_buffers_create(struct interactor_io_buffers* pool, struct interactor_memory* memory)
    {
        pool->memory = memory;
        if (interactor_pool_create(&pool->input_buffers, memory, sizeof(struct interactor_input_buffer)))
        {
            return -1;
        }
        if (interactor_pool_create(&pool->output_buffers, memory, sizeof(struct interactor_output_buffer)))
        {
            return -1;
        }
        return 0;
    }

    static inline void interactor_io_buffers_destroy(struct interactor_io_buffers* pool)
    {
        interactor_pool_destroy(&pool->input_buffers);
        interactor_pool_destroy(&pool->output_buffers);
    }

    static inline struct interactor_input_buffer* interactor_io_buffers_allocate_input(struct interactor_io_buffers* buffers, size_t inital_capacity)
    {
        struct interactor_input_buffer* buffer = interactor_pool_allocate(&buffers->input_buffers);
        ibuf_create(&buffer->buffer, &buffers->memory->cache, inital_capacity);
        return buffer;
    }

    static inline void interactor_io_buffers_free_input(struct interactor_io_buffers* buffers, struct interactor_input_buffer* buffer)
    {
        ibuf_destroy(&buffer->buffer);
        interactor_pool_free(&buffers->input_buffers, buffer);
    }

    static inline struct interactor_output_buffer* interactor_io_buffers_allocate_output(struct interactor_io_buffers* buffers, size_t inital_capacity)
    {
        struct interactor_output_buffer* buffer = interactor_pool_allocate(&buffers->output_buffers);
        obuf_create(&buffer->buffer, &buffers->memory->cache, inital_capacity);
        return buffer;
    }

    static inline void interactor_io_buffers_free_output(struct interactor_io_buffers* buffers, struct interactor_output_buffer* buffer)
    {
        obuf_destroy(&buffer->buffer);
        interactor_pool_free(&buffers->output_buffers, buffer);
    }

    static inline uint8_t* interactor_input_buffer_reserve(struct interactor_input_buffer* buffer, size_t size)
    {
        return ibuf_reserve(&buffer->buffer, size ? size : buffer->buffer.start_capacity);
    }

    static inline uint8_t* interactor_input_buffer_allocate(struct interactor_input_buffer* buffer, size_t size)
    {
        uint8_t* allocated = ibuf_alloc(&buffer->buffer, size);
        return allocated;
    }

    static inline uint8_t* interactor_input_buffer_allocate_reserve(struct interactor_input_buffer* buffer, size_t delta, size_t size)
    {
        ibuf_alloc(&buffer->buffer, size);
        uint8_t* reserved = ibuf_reserve(&buffer->buffer, size ? size : buffer->buffer.start_capacity);
        return reserved;
    }

    static inline uint8_t* interactor_output_buffer_reserve(struct interactor_output_buffer* buffer, size_t size)
    {
        return obuf_reserve(&buffer->buffer, size ? size : buffer->buffer.start_capacity);
    }

    static inline uint8_t* interactor_output_buffer_allocate(struct interactor_output_buffer* buffer, size_t size)
    {
        return obuf_alloc(&buffer->buffer, size);
    }

    static inline uint8_t* interactor_output_buffer_allocate_reserve(struct interactor_output_buffer* buffer, size_t delta, size_t size)
    {
        obuf_alloc(&buffer->buffer, size);
        return obuf_reserve(&buffer->buffer, size ? size : buffer->buffer.start_capacity);
    }

#if defined(__cplusplus)
}
#endif

#endif
