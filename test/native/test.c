

#include "test.h"
#include <bits/pthreadtypes.h>
#include <stdlib.h>
#include "interactor_native.h"

static pthread_mutex_t mutex;

test_interactor_native* test_interactor_initialize()
{
    struct interactor_native* test_interactor = malloc(sizeof(struct interactor_native));
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

int test_interactor_descriptor(test_interactor_native* interactor)
{
  return ((struct interactor_native*)interactor)->descriptor;
}

void test_interactor_destroy(test_interactor_native* interactor)
{
    interactor_native_destroy(interactor);
    free(interactor);
}