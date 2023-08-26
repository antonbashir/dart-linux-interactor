#include "dart/dart_api.h"
#include <stdio.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <liburing.h>
#include <string.h>
#include <errno.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#include <sys/time.h>
#include "interactor.h"
#include "interactor_constants.h"
#include "interactor_server.h"
#include "small/include/small/rlist.h"

void interactor_cqe_advance(struct io_uring *ring, int count)
{
  io_uring_cq_advance(ring, count);
}

void interactor_close_descritor(int fd)
{
  shutdown(fd, SHUT_RDWR);
  close(fd);
}
