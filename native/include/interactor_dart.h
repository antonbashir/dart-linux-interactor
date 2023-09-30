#ifndef INTERACTOR_H_INCLUDED
#define INTERACTOR_H_INCLUDED

#include <interactor_message.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif
    void interactor_dart_send(void* source_ring, int target_ring_fd, interactor_message_t* message);
#if defined(__cplusplus)
}
#endif

#endif
