#include "test.h"
#include <stdlib.h>

interactor_native_t* test_interactor_initialize()
{
    interactor_native_t* test_interactor = malloc(sizeof(interactor_native_t));
    int result = interactor_native_initialize_default(test_interactor, 0);
    if (result != 0) return NULL;
    return test_interactor;
}