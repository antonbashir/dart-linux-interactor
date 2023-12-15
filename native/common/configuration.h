#ifndef INTERACTOR_CONFIG_H_INCLUDED
#define INTERACTOR_CONFIG_H_INCLUDED
/*
 * This file is generated by CMake. The original file is called
 * config.h.cmake. Please do not modify.
 */
/** \cond public */

/**
 * Package major version - 1 for 1.6.7
 */
#define PACKAGE_VERSION_MAJOR 
/**
 * Package minor version - 6 for 1.6.7
 */
#define PACKAGE_VERSION_MINOR 
/**
 * Package patch version - 7 for 1.6.7
 */
#define PACKAGE_VERSION_PATCH 
/**
 * A string with major-minor-patch-commit-id identifier of the
 * release, e.g. 1.6.6-113-g8399d0e.
 */
#define PACKAGE_VERSION ""

/** \endcond public */

#define PACKAGE ""
/*  Defined if building for Linux */
/* #undef TARGET_OS_LINUX */
/*  Defined if building for FreeBSD */
/* #undef TARGET_OS_FREEBSD */
/*  Defined if building for NetBSD */
/* #undef TARGET_OS_NETBSD */
/*  Defined if building for Darwin */
/* #undef TARGET_OS_DARWIN */

#ifdef TARGET_OS_DARWIN
#define INTERACTOR_LIBEXT "dylib"
#else
#define INTERACTOR_LIBEXT "so"
#endif

/**
 * Defined if cpuid() instruction is available.
 */
/* #undef HAVE_CPUID */

/**
 * Defined if strlcpy() string extension helper present.
 */
/* #undef HAVE_STRLCPY */

/**
 * Defined if strlcat() string extension helper present.
 */
/* #undef HAVE_STRLCAT */

/**
 * Defined if this platform has GNU specific strerror_r().
 */
/* #undef HAVE_STRERROR_R_GNU */

/*
 * Defined if gcov instrumentation should be enabled.
 */
/* #undef ENABLE_GCOV */
/*
 * Defined if configured with ENABLE_BACKTRACE ('show fiber'
 * showing fiber call stack.
 */
/* #undef ENABLE_BACKTRACE */

/*
 * Defined if configured with ENABLE_BACKTRACE on AARCH64 and
 * '-mbranch-protection' compile flag is passed.
 */
/* #undef WITH_BRANCH_PROTECTION */

/*
 * Set if the system has bfd.h header and GNU bfd library.
 */
/* #undef HAVE_BFD */
/* #undef HAVE_MAP_ANON */
/* #undef HAVE_MAP_ANONYMOUS */
#if !defined(HAVE_MAP_ANONYMOUS) && defined(HAVE_MAP_ANON)
/*
 * MAP_ANON is deprecated, MAP_ANONYMOUS should be used instead.
 * Unfortunately, it's not universally present (e.g. not present
 * on FreeBSD.
 */
#define MAP_ANONYMOUS MAP_ANON
#endif
/* #undef HAVE_MADV_DONTNEED */
/*
 * Defined if O_DSYNC mode exists for open(2).
 */
/* #undef HAVE_O_DSYNC */
#if defined(HAVE_O_DSYNC)
    #define WAL_SYNC_FLAG O_DSYNC
#else
    #define WAL_SYNC_FLAG O_SYNC
#endif
/*
 * Defined if fdatasync(2) call is present.
 */
/* #undef HAVE_FDATASYNC */

#ifndef HAVE_FDATASYNC
#if defined(__APPLE__)
#include <fcntl.h>
#define fdatasync(fd) fcntl(fd, F_FULLFSYNC)
#else
#define fdatasync fsync
#endif
#endif

/*
 * Defined if this platform has GNU specific memmem().
 */
/* #undef HAVE_MEMMEM */
/*
 * Defined if this platform has GNU specific memrchr().
 */
/* #undef HAVE_MEMRCHR */
/*
 * Defined if this platform has sendfile(..).
 */
/* #undef HAVE_SENDFILE */
/*
 * Defined if this platform has Linux specific sendfile(..).
 */
/* #undef HAVE_SENDFILE_LINUX */
/*
 * Defined if this platform has BSD specific sendfile(..).
 */
/* #undef HAVE_SENDFILE_BSD */
/*
 * Set if this is a GNU system and libc has __libc_stack_end.
 */
/* #undef HAVE_LIBC_STACK_END */
/*
 * Defined if this is a big-endian system.
 */
/* #undef HAVE_BYTE_ORDER_BIG_ENDIAN */
/*
 * Defined if this platform supports openmp and it is enabled
 */
/* #undef HAVE_OPENMP */
/*
*  Defined if compatible with GNU readline installed.
*/
/* #undef HAVE_GNU_READLINE */

/*
 * Defined if `st_mtim' is a member of `struct stat'.
 */
/* #undef HAVE_STRUCT_STAT_ST_MTIM */

/*
 * Defined if `st_mtimensec' is a member of `struct stat'.
 */
/* #undef HAVE_STRUCT_STAT_ST_MTIMENSEC */

/*
 * Set if compiler has __builtin_XXX methods.
 */
/* #undef HAVE_BUILTIN_CTZ */
/* #undef HAVE_BUILTIN_CTZLL */
/* #undef HAVE_BUILTIN_CLZ */
/* #undef HAVE_BUILTIN_CLZLL */
/* #undef HAVE_BUILTIN_POPCOUNT */
/* #undef HAVE_BUILTIN_POPCOUNTLL */
/* #undef HAVE_BUILTIN_BSWAP32 */
/* #undef HAVE_BUILTIN_BSWAP64 */
/* #undef HAVE_FFSL */
/* #undef HAVE_FFSLL */

/*
 * pthread have problems with -std=c99
 */
/* #undef HAVE_NON_C99_PTHREAD_H */

/* #undef ENABLE_BUNDLED_LIBEV */
/* #undef ENABLE_BUNDLED_LIBEIO */
/* #undef ENABLE_BUNDLED_LIBCORO */

/* #undef HAVE_PTHREAD_YIELD */
/* #undef HAVE_SCHED_YIELD */
/* #undef HAVE_POSIX_FADVISE */
/* #undef HAVE_FALLOCATE */
/* #undef HAVE_MREMAP */
/* #undef HAVE_SYNC_FILE_RANGE */

/* #undef HAVE_MSG_NOSIGNAL */
/* #undef HAVE_SO_NOSIGPIPE */

/* #undef HAVE_PRCTL_H */

/* #undef HAVE_UUIDGEN */
/* #undef HAVE_CLOCK_GETTIME */
#define HAVE_CLOCK_GETTIME_DECL 1

/** pthread_np.h - non-portable stuff */
/* #undef HAVE_PTHREAD_NP_H */
/** pthread_setname_np(pthread_self(), "") - Linux */
/* #undef HAVE_PTHREAD_SETNAME_NP */
/** pthread_setname_np("") - OSX */
/* #undef HAVE_PTHREAD_SETNAME_NP_1 */
/** pthread_set_name_np(pthread_self(), "") - *BSD */
/* #undef HAVE_PTHREAD_SET_NAME_NP */

/* #undef HAVE_PTHREAD_GETATTR_NP */
/* #undef HAVE_PTHREAD_ATTR_GET_NP */

/* #undef HAVE_PTHREAD_GET_STACKSIZE_NP */
/* #undef HAVE_PTHREAD_GET_STACKADDR_NP */

/* #undef HAVE_SETPROCTITLE */
/* #undef HAVE_SETPROGNAME */
/* #undef HAVE_GETPROGNAME */

/*
 * Defined if ICU library has ucol_strcollUTF8 method.
 */
/* #undef HAVE_ICU_STRCOLLUTF8 */

/*
* Defined if notifications on NOTIFY_SOCKET are enabled
 */
/* #undef WITH_NOTIFY_SOCKET */

/** \cond public */

/** System configuration dir (e.g /etc) */
#define SYSCONF_DIR ""
/** Install prefix (e.g. /usr) */
#define INSTALL_PREFIX "/usr/local"
/** Build type, e.g. Debug or Release */
#define BUILD_TYPE ""
/** CMake build type signature, e.g. Linux-x86_64-Debug */
#define BUILD_INFO ""
/** Command line used to run CMake */
#define BUILD_OPTIONS "cmake . "
/** Compiler ID and version, assuming the C and C++ compiler IDs are equal. */
#define COMPILER_INFO "GNU-13.2.1"
/** C compile flags used to build */
#define INTERACTOR_C_FLAGS ""
/** CXX compile flags used to build */
#define INTERACTOR_CXX_FLAGS ""

/** A path to install *.lua module files */
#define MODULE_LIBDIR ""
/** A path to install *.so / *.dylib module files */
#define MODULE_LUADIR ""
/** A path to Lua includes (the same directory where this file is contained) */
#define MODULE_INCLUDEDIR ""
/** A constant added to package.path in Lua to find *.lua module files */
#define MODULE_LUAPATH ""
/** A constant added to package.cpath in Lua to find *.so module files */
#define MODULE_LIBPATH ""
/** Shared library suffix - ".so" on Linux, ".dylib" on Mac */
#define MODULE_LIBSUFFIX ""

/** \endcond public */

/* #undef ENABLE_ASAN */

/* Cacheline size to calculate alignments */
#define CACHELINE_SIZE 64

/* #undef ENABLE_FLIGHT_RECORDER */
/* #undef ENABLE_TUPLE_COMPRESSION */
/* #undef ENABLE_SPACE_UPGRADE */
/* #undef ENABLE_SSL */
/* #undef ENABLE_AUDIT_LOG */
/* #undef ENABLE_FEEDBACK_DAEMON */

/* #undef EXPORT_LIBCURL_SYMBOLS */

/* #undef BUILD_STATIC */
/* #undef EMBED_LUAZLIB */
/* #undef EMBED_LUAZIP */
/* #undef EMBED_LUAROCKS */

/*
 * vim: syntax=c
 */
#endif /* INTERACTOR_CONFIG_H_INCLUDED */
