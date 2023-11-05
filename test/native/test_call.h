#ifndef TEST_CALL_H
#define TEST_CALL_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    void test_call_dart(interactor_native_t* interactor, int dart_ring_fd);
    void test_call_native(interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif
