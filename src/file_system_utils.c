#ifdef PLATFORM_WINDOWS
#include "file_system_utils_win32.c"
#endif

#if defined(PLATFORM_OS_X) || defined(PLATFORM_LINUX)
#include "file_system_utils_posix.c"
#endif
