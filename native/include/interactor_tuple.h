#ifndef INTERACTOR_TUPLE_H
#define INTERACTOR_TUPLE_H

#include <stddef.h>

#if defined(__cplusplus)
extern "C"
{
#endif

    typedef struct interactor_data_tuple
    {
        char* buffer;
        size_t size;
    } interactor_data_tuple_t;

#if defined(__cplusplus)
}
#endif

#endif
