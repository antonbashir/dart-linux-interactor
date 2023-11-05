#ifndef TEST_H
#define TEST_H

#include <interactor_message.h>
#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    void test_send_to_dart(interactor_native_t* interactor, int dart_ring_fd);
    void test_send_to_native(interactor_message_t* message);
    void test_check(interactor_native_t* interactor);

#if defined(__cplusplus)
}
#endif

#endif
