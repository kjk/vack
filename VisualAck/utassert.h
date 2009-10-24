#ifndef UT_ASSERT_H__
#define UT_ASSERT_H__

#include <execinfo.h>

extern int g_utassert_total;
extern int g_utassert_failed;

void dump_backtrace();

#define utassert(cond) \
    fprintf(stderr, "."); \
    ++g_utassert_total; \
    if (!cond) { \
        ++g_utassert_failed; \
	printf("\n%s\n", #cond); \
	dump_backtrace(STDERR_FILENO); \
    }

#endif
