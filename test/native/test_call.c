#include "test_call.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

static bool run_native_check = false;

bool test_run_native_check(interactor_native_t* interactor)
{
    interactor_native_process(interactor);
    return run_native_check;
}

void test_run_native(interactor_message_t* message)
{
    run_native_check = true;
}