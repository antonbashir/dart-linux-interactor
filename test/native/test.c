#include "test.h"
#include <liburing.h>
#include <stdio.h>
#include "interactor_dart.h"

void test_void(int fd)
{
    struct io_uring ring;
    io_uring_queue_init(1024, &ring, 0);
    interactor_message_t msg;
    msg.flags = 0;
    msg.owner_id = 0;
    msg.method_id = 0;
    interactor_dart_send(&ring, fd, &msg);
}