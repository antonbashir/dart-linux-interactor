#ifndef TEST_H
#define TEST_H

#include <interactor_native.h>

#if defined(__cplusplus)
extern "C"
{
#endif

   struct  interactor_native* test_interactor_initialize();
    void test_interactor_destroy(struct interactor_native* interactor);

#if defined(__cplusplus)
}
#endif

#endif
