#include "utassert.h"

int g_utassert_total = 0;
int g_utassert_failed = 0;

// this only works on 10.5 or higher
void dump_backtrace() {
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
    // TODO: free addresses
}

