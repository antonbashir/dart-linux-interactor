#include "interactor_payloads_pool.h"

#include "interactor_constants.h"
#include "interactor_memory.h"
#include "small/include/small/small.h"
#include "trivia/util.h"

int interactor_payloads_pool_create(struct interactor_payloads_pool* pool, struct interactor_memory* memory, size_t payload_size)
{
    pool->pool.memory = memory;
    return interactor_mempool_create(&pool->pool, payload_size);
}

void interactor_payloads_pool_destroy(struct interactor_payloads_pool* pool)
{
    interactor_mempool_destroy(&pool->pool);
}

intptr_t interactor_payloads_pool_allocate(struct interactor_payloads_pool* pool)
{
    return (intptr_t)interactor_payloads_pool_allocate(pool);
}

void interactor_payloads_pool_free(struct interactor_payloads_pool* pool, intptr_t payload)
{
    interactor_payloads_pool_free(pool, payload);
}
