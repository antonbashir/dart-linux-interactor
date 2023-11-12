#ifndef TEST_H
#define TEST_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    interactor_native_t* test_interactor_initialize();
    void test_interactor_process(interactor_native_t* interactor);

#if defined(__cplusplus)
}
#endif

#endif
