#ifndef INTERACTOR_MESSAGE_H
#define INTERACTOR_MESSAGE_H

#include <asm-generic/int-ll64.h>
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

    struct interactor_completion_event
    {
        __u64 user_data;
        __s32 res;
        __u32 flags;
        __u64 big_cqe[2];
    };
#if defined(__cplusplus)
}
#endif

#endif
