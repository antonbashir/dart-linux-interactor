#include <interactor_memory.h>
#include <interactor_message.h>
#include <interactor_messages_pool.h>

int interactor_messages_pool_create(struct interactor_messages_pool* pool, struct interactor_memory* memory)
{
    pool->pool.memory = memory;
    return interactor_mempool_create(&pool->pool, sizeof(interactor_message_t));
}

void interactor_messages_pool_destroy(struct interactor_messages_pool* pool)
{
    interactor_mempool_destroy(&pool->pool);
}

interactor_message_t* interactor_messages_pool_allocate(struct interactor_messages_pool* pool)
{
    return (interactor_message_t*)interactor_mempool_allocate(&pool->pool);
}

void interactor_messages_pool_free(struct interactor_messages_pool* pool, interactor_message_t* message)
{
    interactor_mempool_free(&pool->pool, message);
}
