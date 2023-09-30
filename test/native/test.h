#ifndef TEST_H_INCLUDED
#define TEST_H_INCLUDED

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    void test_initialize();
    void test_to_dart(int fd);
    void test_method(interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif
