#ifndef INTERACTOR_COLLECTIONS_H
#define INTERACTOR_COLLECTIONS_H

#include <stdint.h>
#include "interactor_message.h"

#if defined(__cplusplus)
extern "C"
{
#endif

#define mh_name _native_callbacks
    struct mh_native_callbacks_key_t
    {
        uint64_t owner;
        uint64_t method;
    };
#define mh_key_t struct mh_native_callbacks_key_t
    struct mh_native_callbacks_node_t
    {
        mh_key_t key;
        void (*callback)(struct interactor_message*);
    };

#define mh_node_t struct mh_native_callbacks_node_t
#define mh_arg_t uint64_t
#define mh_hash(a, arg) (a->key.owner * 31 + a->key.method)
#define mh_hash_key(a, arg) (a.owner * 31 + a.method)
#define mh_cmp(a, b, arg) ((a->key.owner != b->key.owner) && (a->key.method != b->key.method))
#define mh_cmp_key(a, b, arg) ((a.owner != b->key.owner) && (a.method != b->key.method))
#define MH_SOURCE

#include "collections/mhash.h"

#undef mh_node_t
#undef mh_arg_t
#undef mh_hash
#undef mh_hash_key
#undef mh_cmp
#undef mh_cmp_key

#if defined(__cplusplus)
}
#endif

#endif
