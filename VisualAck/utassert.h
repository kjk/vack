#ifndef UT_ASSERT_H__
#define UT_ASSERT_H__

#include <execinfo.h>

void utassert_func(BOOL cond, const char *condStr);
int utassert_failed_count();
int utassert_total_count();

#define utassert(cond) utassert_func(cond, #cond)

#endif
