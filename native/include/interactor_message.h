#ifndef INTERACTOR_MESSAGE_H
#define INTERACTOR_MESSAGE_H

#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    typedef struct interactor_message
    {
        uint64_t owner;
        uint64_t method;
        uintptr_t* input;
        uintptr_t* output;
        uint16_t flags;
    } interactor_message_t;

#if defined(__cplusplus)
}
#endif

#endif
