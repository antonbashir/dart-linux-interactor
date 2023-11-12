#ifndef INTERACTOR_MEMORY_H
#define INTERACTOR_MEMORY_H

#include <stddef.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_memory
    {
        void* context;
    };

    struct interactor_mempool
    {
        struct interactor_memory* memory;
        void* context;
    };

    struct interactor_small
    {
        struct interactor_memory* memory;
        void* context;
    };

    int interactor_memory_create(struct interactor_memory* memory, size_t quota_size, size_t preallocation_size, size_t slab_size);
    void interactor_memory_destroy(struct interactor_memory* memory);

    int interactor_mempool_create(struct interactor_mempool* pool, size_t size);
    void interactor_mempool_destroy(struct interactor_mempool* pool);
    void* interactor_mempool_allocate(struct interactor_mempool* pool);
    void interactor_mempool_free(struct interactor_mempool* pool, void* ptr);

    int interactor_small_create(struct interactor_small* pool);
    void* interactor_small_allocate(struct interactor_small* pool, size_t size);
    void interactor_small_free(struct interactor_small* pool, void* ptr, size_t size);
    void interactor_small_destroy(struct interactor_small* pool);

#if defined(__cplusplus)
}
#endif

#endif
