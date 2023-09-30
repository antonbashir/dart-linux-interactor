#include "test.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>

void test_send_to_dart(interactor_native_t* interactor, int dart_ring_fd)
{
    interactor_message_t* msg = interactor_native_allocate_message(interactor);
    msg->owner_id = 0;
    msg->method_id = 0;
    interactor_native_send(interactor, dart_ring_fd, msg);
}

void test_native_method(interactor_message_t* message)
{
    printf("Hello, Dart\n");
}

void test_check(interactor_native_t* interactor)
{
    interactor_native_process(interactor);
}