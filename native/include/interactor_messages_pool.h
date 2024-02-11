#ifndef INTERACTOR_MESSAGES_POOL_H
#define INTERACTOR_MESSAGES_POOL_H

#include <interactor_memory.h>
#include <interactor_message.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_messages_pool
    {
        struct interactor_pool pool;
    };

    static inline int interactor_messages_pool_create(struct interactor_messages_pool* pool, struct interactor_memory* memory)
    {
        return interactor_pool_create(&pool->pool, memory, sizeof(struct interactor_message));
    }

    static inline void interactor_messages_pool_destroy(struct interactor_messages_pool* pool)
    {
        interactor_pool_destroy(&pool->pool);
    }

    static inline struct interactor_message* interactor_messages_pool_allocate(struct interactor_messages_pool* pool)
    {
        return (struct interactor_message*)interactor_pool_allocate(&pool->pool);
    }

    static inline void interactor_messages_pool_free(struct interactor_messages_pool* pool, struct interactor_message* message)
    {
        interactor_pool_free(&pool->pool, message);
    }

#if defined(__cplusplus)
}
#endif

#endif