#ifndef INTERACTOR_MESSAGES_POOL_INCLUDED
#define INTERACTOR_MESSAGES_POOL_INCLUDED

#include <interactor_message.h>
#include "interactor_constants.h"
#include <interactor_memory.h>
#include "trivia/util.h"

struct interactor_messages_pool
{
    struct interactor_mempool pool;
};

int interactor_messages_pool_create(struct interactor_messages_pool* pool, struct interactor_memory* memory);
void interactor_messages_pool_destroy(struct interactor_messages_pool* pool);
interactor_message_t* interactor_messages_pool_allocate(struct interactor_messages_pool* pool);
void interactor_messages_pool_free(struct interactor_messages_pool* pool, interactor_message_t* message);
#endif
