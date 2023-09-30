#ifndef TEST_H_INCLUDED
#define TEST_H_INCLUDED

#include <interactor_message.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    int test_initialize();
    void test_to_dart(int fd);
    void test_method(interactor_message_t* message);
    void test_check();

#if defined(__cplusplus)
}
#endif

#endif
