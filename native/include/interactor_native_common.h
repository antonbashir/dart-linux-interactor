#ifndef INTERACTOR_NATIVE_COMMON_H
#define INTERACTOR_NATIVE_COMMON_H

#if defined(__cplusplus)
extern "C"
{
#endif

#if __has_builtin(__builtin_expect) || defined(__GNUC__)
#define interactor_likely(x) __builtin_expect(!!(x), 1)
#define interactor_unlikely(x) __builtin_expect(!!(x), 0)
#else
#define interactor_likely(x) (x)
#define interactor_unlikely(x) (x)
#endif

#if defined(__cplusplus)
}
#endif

#endif