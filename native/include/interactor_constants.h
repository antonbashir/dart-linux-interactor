#ifndef INTERACTOR_CONSTANTS_H
#define INTERACTOR_CONSTANTS_H

#if defined(__cplusplus)
extern "C"
{
#endif

#define INTERACTOR_BUFFER_USED -1

#define INTERACTOR_DART_CALLBACK 1 << 0
#define INTERACTOR_NATIVE_CALLBACK 1 << 1
#define INTERACTOR_DART_CALL 1 << 2
#define INTERACTOR_NATIVE_CALL 1 << 3

#if defined(__cplusplus)
}
#endif

#endif