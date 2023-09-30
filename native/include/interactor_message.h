#ifndef INTERACTOR_MESSAGE_H
#define INTERACTOR_MESSAGE_H

#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

  typedef struct interactor_message
  {
    uint64_t owner_id;
    uint64_t method_id;
    uintptr_t *input_pointer;
    uintptr_t *output_pointer;
    uint16_t flags;
  } interactor_message_t;

#if defined(__cplusplus)
}
#endif

#endif
