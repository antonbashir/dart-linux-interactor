#include "test.h"
#include <stdlib.h>

int test_interactor_initialize()
{
    interactor_native_t* interactor = malloc(sizeof(interactor_native_t));
    return interactor_native_initialize_default(interactor, 0);
}