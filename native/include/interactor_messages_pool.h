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
        struct interactor_mempool pool;
    };

    int interactor_messages_pool_create(struct interactor_messages_pool* pool, struct interactor_memory* memory);
    void interactor_messages_pool_destroy(struct interactor_messages_pool* pool);
    interactor_message_t* interactor_messages_pool_allocate(struct interactor_messages_pool* pool);
    void interactor_messages_pool_free(struct interactor_messages_pool* pool, interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif