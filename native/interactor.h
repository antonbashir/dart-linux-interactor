#ifndef INTERACTOR_H_INCLUDED
#define INTERACTOR_H_INCLUDED

#include <stdbool.h>
#include <stdint.h>
#include <liburing.h>
#include "dart/dart_api.h"

#if defined(__cplusplus)
extern "C"
{
#endif
  void interactor_cqe_advance(struct io_uring *ring, int count);

  void interactor_close_descritor(int fd);
#if defined(__cplusplus)
}
#endif

#endif
