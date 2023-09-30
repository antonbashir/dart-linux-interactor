#ifndef TEST_H_INCLUDED
#define TEST_H_INCLUDED

#include <interactor_message.h>
#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    interactor_native_t* test_initialize(int fd);
    void test_method(interactor_message_t* message);
    void test_check(interactor_native_t* interactor);

#if defined(__cplusplus)
}
#endif

#endif
