#include "SearchOptions.h"
#include <assert.h>

/*
 TODO: this should really be a *.c file, but it doesn't play with
 precompiled headers.
*/

static search_options g_default_search_options = {
    0, /* use_gui */
    0, /* noenv */
    0, /* help */
    0, /* version */
    0, /* thppt */
    0, /* ignore_case */
    NULL, /* ignore_dirs */
    NULL, /* no_ignore_dirs */
    NULL, /* search_term */
    0, /* search_loc_count */
    NULL, /* search_loc */
};

static inline int streq(const char *s1, const char *s2) {
    return 0 == strcmp(s1, s2);
}

/* return 1 if s1 starts with s2, case sensitive. 0 otherwise */
static inline int strstartswith(const char *s1, const char *s2) {
    if (!s1 || !s2)
        return 0;
    size_t s1len = strlen(s1);
    size_t s2len = strlen(s2);
    if (s2len > s1len)
        return 0;
    int res = strncmp(s1, s2, s2len);
    return 0 == res;
}

static char **char_array_dup(char **arr, int count) {
    char **res = (char**)malloc(sizeof(char*) * (count+1));
    for (int i=0; i < count; i++) {
        char *s = arr[i];
        assert(s);
        res[i] = strdup(s);
    }
    res[count] = 0;
    return res;
}

void init_search_options(search_options *opts)
{
    *opts = g_default_search_options;
}

#define MAX_DIRS 32

void add_search_location(search_options *opts, const char *search_loc)
{
    if (opts->search_loc_count >= MAX_SEARCH_LOCS)
        return;
    assert(search_loc);
    opts->search_loc[opts->search_loc_count++] = strdup(search_loc);
}

void cmd_line_to_search_options(search_options *opts, int argc, char *argv[]) 
{
    char *ignore_dirs[MAX_DIRS];
    int ignore_dirs_count = 0;
    char *no_ignore_dirs[MAX_DIRS];
    int no_ignore_dirs_count = 0;

    if (argc < 2)
        return;

    int curr_arg = 1;

    /* special case: if '-' is the first arg it launches VisualAck with the same arguments */
    if (streq("-", argv[curr_arg])) {
        opts->use_gui = 1;
        ++curr_arg;
    }

    char *val;
    for(;;) 
    {
        int args_left = argc - curr_arg;
        if (args_left <= 0)
            break;

        char *arg = argv[curr_arg];
        if (streq(arg, "--noenv")) {
            opts->noenv = 1;
            ++curr_arg;
        } else if (streq(arg, "--help")) {
            opts->help = 1;
            ++curr_arg;
        } else if (streq(arg, "--version")) {
            opts->version = 1;
            ++curr_arg;
        } else if (streq(arg, "--thppt")) {
            opts->thpppt = 1;
            ++curr_arg;
        } else if (streq(arg, "-i") || (streq(arg, "--ignore-case"))) {
            opts->ignore_case = 1;
            ++curr_arg;
        } else if (strstartswith(arg, "--ignore-dir=")) {
            val = arg + strlen("--ignore-dir=");
            if (ignore_dirs_count < MAX_DIRS) {
                ignore_dirs[ignore_dirs_count++] = val;
            }
        } else if (strstartswith(arg, "--noignore-dir=")) {
            val = arg + strlen("--noignore-dir=");
            if (no_ignore_dirs_count < MAX_DIRS) {
                no_ignore_dirs[no_ignore_dirs_count++] = val;
            }
        } else {
            if (!opts->search_term) {
                opts->search_term = strdup(arg);
            } else {
                add_search_location(opts, arg);
            }
            ++curr_arg;
        }
    }

    if (ignore_dirs_count > 0) {
        opts->ignore_dirs = char_array_dup(ignore_dirs, ignore_dirs_count);
    }

    if (no_ignore_dirs_count > 0) {
        opts->no_ignore_dirs = char_array_dup(no_ignore_dirs, no_ignore_dirs_count);
    }
}

void free_search_options(search_options *options) {
    int i;
    if (options->ignore_dirs) {
        for (i=0; options->ignore_dirs[i]; i++) {
            free(options->ignore_dirs[i]);
        }
        free(options->ignore_dirs);
    }
    
    if (options->no_ignore_dirs) {
        for (i=0; options->no_ignore_dirs[i]; i++) {
            free(options->no_ignore_dirs[i]);
        }
        free(options->no_ignore_dirs);
    }

    free(options->search_term);
    for (i = 0; i < options->search_loc_count; i++) {
        free(options->search_loc[i]);
    }
    *options = g_default_search_options;
}
