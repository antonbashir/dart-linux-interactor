#include <interactor_memory.h>
#include <interactor_payload_pool.h>
#include "interactor_constants.h"
#include "small/include/small/small.h"
#include "trivia/util.h"

int interactor_payload_pool_create(struct interactor_payload_pool* pool, struct interactor_memory* memory, size_t payload_size)
{
    pool->pool.memory = memory;
    return interactor_mempool_create(&pool->pool, payload_size);
}

void interactor_payload_pool_destroy(struct interactor_payload_pool* pool)
{
    interactor_mempool_destroy(&pool->pool);
}

intptr_t interactor_payload_pool_allocate(struct interactor_payload_pool* pool)
{
    return (intptr_t)interactor_mempool_allocate(&pool->pool);
}

void interactor_payload_pool_free(struct interactor_payload_pool* pool, intptr_t payload)
{
    interactor_mempool_free(&pool->pool, (void*)payload);
}
