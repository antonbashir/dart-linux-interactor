#include "test_call.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

static interactor_message_t* called_message = NULL;

bool test_call_native_check(interactor_native_t* interactor)
{
    test_interactor_process(interactor);
    if (called_message)
    {
        interactor_native_callback_to_dart(interactor, called_message);
        interactor_native_submit(interactor);
        return true;
    }
    return false;
}

void test_call_native_echo(interactor_message_t* message)
{
    message->output = message->input;
    called_message = message;
}