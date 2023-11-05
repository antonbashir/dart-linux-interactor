#include "test_call.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

static bool call_native_check = false;

bool test_call_dart_check(interactor_native_t* interactor)
{
    interactor_native_process(interactor);
    return call_native_check;
}

void test_call_native(interactor_message_t* message)
{
    call_native_check = true;
}