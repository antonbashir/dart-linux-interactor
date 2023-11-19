#include "test.h"
#include <stdlib.h>
#include "interactor_constants.h"
#include "interactor_message.h"
#include "interactor_native.h"

interactor_native_t* test_interactor_initialize()
{
    interactor_native_t* test_interactor = malloc(sizeof(interactor_native_t));
    int result = interactor_native_initialize_default(test_interactor, 0);
    if (result != 0) return NULL;
    return test_interactor;
}

void test_interactor_process_callbacks(interactor_native_t* interactor, void(on_callback)(interactor_message_t*))
{
    if (interactor_native_peek_timeout(interactor) > 0)
    {
        interactor_native_foreach_callback(interactor, on_callback);
    }
}

void test_interactor_destroy(interactor_native_t* interactor)
{
    interactor_native_destroy(interactor);
}