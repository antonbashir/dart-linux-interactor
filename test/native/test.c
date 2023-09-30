#include "test.h"
#include <interactor_dart.h>
#include <inttypes.h>
#include <liburing.h>
#include <liburing/io_uring.h>
#include <stdio.h>
#include <stdlib.h>
#include "interactor_message.h"

struct io_uring ring;

int test_void(int fd)
{
    io_uring_queue_init(1024, &ring, 0);
    interactor_message_t* msg = malloc(sizeof(interactor_message_t));
    msg->owner_id = 0;
    msg->method_id = 0;
    interactor_dart_send(&ring, fd, msg);
    return ring.ring_fd;
}

void test_method(interactor_message_t* message)
{
    printf("Hello, Dart\n");
}

void test_check()
{
    struct io_uring_cqe* cqe;
    while (true)
    {
        if (io_uring_wait_cqe(&ring, &cqe) == 0)
        {
            test_method((interactor_message_t*)cqe->user_data);
            io_uring_cqe_seen(&ring, cqe);
            break;
        }
    }
}