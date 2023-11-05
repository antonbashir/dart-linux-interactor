#ifndef TEST_CALL_H
#define TEST_CALL_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    bool test_run_native_check(interactor_native_t* interactor);
    void test_run_native(interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif
