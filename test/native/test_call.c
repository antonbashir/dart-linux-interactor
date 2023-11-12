#include "test_call.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

static bool run_native_check = false;

bool test_call_native_check(interactor_native_t* interactor)
{
    test_interactor_process(interactor);
    return run_native_check;
}

void test_call_native(interactor_message_t* message)
{
    message->output = (uintptr_t*)true;
    run_native_check = (bool)message->input;
}