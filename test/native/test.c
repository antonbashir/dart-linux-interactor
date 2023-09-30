#include "test.h"
#include <stdio.h>
#include <stdlib.h>

interactor_native_t interactor;

void test_initialize()
{
}

void test_to_dart(int fd)
{
    interactor_message_t* msg = malloc(sizeof(interactor_message_t));
    msg->owner_id = 0;
    msg->method_id = 0;
    interactor_native_send(&interactor, fd, msg);
}

void test_method(interactor_message_t* message)
{
    printf("Hello, Dart\n");
}

void test_check()
{
  
}