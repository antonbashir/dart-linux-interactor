#include "test.h"
#include <interactor_native.h>
#include <stdio.h>
#include <stdlib.h>

interactor_native_t* test_initialize(int fd)
{
    interactor_native_t* interactor = malloc(sizeof(interactor_native_t));
    interactor_native_configuration_t configuration;
    configuration.buffers_count = 4096;
    configuration.buffer_size = 4096;
    configuration.ring_size = 4096;
    configuration.ring_flags = 0;
    configuration.cqe_peek_count = 1024;
    configuration.cqe_wait_count = 1;
    configuration.cqe_wait_timeout_millis = 1;
    configuration.quota_size = 1280000;
    configuration.slab_size = 65536;
    configuration.preallocation_size = 65536;
    interactor_native_initialize(interactor, &configuration, 0);
    interactor_message_t* msg = interactor_native_allocate_message(interactor);
    msg->owner_id = 0;
    msg->method_id = 0;
    interactor_native_send(interactor, fd, msg);
    return interactor;
}

void test_method(interactor_message_t* message)
{
    printf("Hello, Dart\n");
}

void test_check(interactor_native_t* interactor)
{
    interactor_native_process(interactor);
}