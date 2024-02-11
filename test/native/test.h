#ifndef TEST_H
#define TEST_H

typedef struct interactor_native test_interactor_native;

#if defined(__cplusplus)
extern "C"
{
#endif

    test_interactor_native* test_interactor_initialize();
    int test_interactor_descriptor(test_interactor_native* interactor);
    void test_interactor_destroy(test_interactor_native* interactor);

#if defined(__cplusplus)
}
#endif

#endif
