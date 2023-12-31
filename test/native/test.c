#include "test.h"
#include <bits/pthreadtypes.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include "interactor_constants.h"
#include "interactor_message.h"
#include "interactor_native.h"

static pthread_mutex_t mutex;

interactor_native_t* test_interactor_initialize()
{
    interactor_native_t* test_interactor = malloc(sizeof(interactor_native_t));
    if (!test_interactor)
    {
        return NULL;
    }
    int result = interactor_native_initialize_default(test_interactor, 0);
    if (result < 0)
    {
        return NULL;
    }
    return test_interactor;
}

void test_interactor_destroy(interactor_native_t* interactor)
{
    interactor_native_destroy(interactor);
}