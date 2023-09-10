#include <sys/socket.h>
#include "interactor.h"
#include "interactor_constants.h"

void interactor_cqe_advance(struct io_uring *ring, int count)
{
  io_uring_cq_advance(ring, count);
}

void interactor_close_descriptor(int fd)
{
  shutdown(fd, SHUT_RDWR);
  close(fd);
}
