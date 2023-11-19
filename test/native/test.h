#ifndef TEST_H
#define TEST_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    interactor_native_t* test_interactor_initialize();
    void test_interactor_destroy(interactor_native_t* interactor);
    void test_interactor_process_callbacks(interactor_native_t* interactor, void(on_callback)(interactor_message_t*));

#if defined(__cplusplus)
}
#endif

#endif
