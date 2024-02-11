#ifndef INTERACTOR_MESSAGE_H
#define INTERACTOR_MESSAGE_H

#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    struct interactor_message
    {
        uint64_t id;
        uint64_t source;
        uint64_t target;
        uint64_t owner;
        uint64_t method;
        void* input;
        size_t input_size;
        void* output;
        size_t output_size;
        uint16_t flags;
    };

#if defined(__cplusplus)
}
#endif

#endif
