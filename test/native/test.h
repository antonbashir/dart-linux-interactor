#ifndef TEST_H_INCLUDED
#define TEST_H_INCLUDED

#include <interactor_message.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    void test_void(int fd);
    void test_method(interactor_message_t* message);

#if defined(__cplusplus)
}
#endif

#endif
