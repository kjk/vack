#include "utassert.h"
#include <assert.h>

static int g_utassert_total;
static int g_utassert_failed;

// this only works on 10.5 or higher
// TODO: we probably leak addresses memory, but we don't care
static void dump_backtrace() {
    void* addresses[16]; \
    int frames_count = backtrace(addresses, 16);
    
    char** symbols;
    symbols = backtrace_symbols(addresses, frames_count);
    if (symbols == NULL)
	return;
    int frames = frames_count;
    if (frames_count > 8) frames_count = 8;
    for (int i = 1; i < frames; i++) {
	char *s = symbols[i];
	printf("%s\n", s);
    }

    free(symbols);
}

void utassert_func(BOOL cond, const char *condStr)
{
    puts(".");
    ++g_utassert_total;
    if (!cond) {
	++g_utassert_failed;
	printf("\n%s\n", condStr);
	dump_backtrace();
	assert(cond);
    }
}

int utassert_total_count() {
    return g_utassert_total;
}

int utassert_failed_count() {
    return g_utassert_failed;
}
