#ifndef UT_ASSERT_H__
#define UT_ASSERT_H__

extern int g_utassert_total;
extern int g_utassert_failed;

#define utassert(cond) \
    printf(stderr, "."); \
    ++g_utassert_total; \
    if (!cond) \
        ++g_utassert_failed;

#endif
