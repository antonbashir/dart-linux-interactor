#include <interactor_data_pool.h>
#include <interactor_memory.h>

int interactor_data_pool_create(struct interactor_data_pool* pool, struct interactor_memory* memory)
{
    pool->pool.memory = memory;
    return interactor_small_create(&pool->pool);
}

void interactor_data_pool_destroy(struct interactor_data_pool* pool)
{
    interactor_small_destroy(&pool->pool);
}

intptr_t interactor_data_pool_allocate(struct interactor_data_pool* pool, size_t data_size)
{
    return (intptr_t)interactor_small_allocate(&pool->pool, data_size);
}

void interactor_data_pool_free(struct interactor_data_pool* pool, intptr_t data, size_t data_size)
{
    interactor_small_free(&pool->pool, (void*)data, data_size);
}
