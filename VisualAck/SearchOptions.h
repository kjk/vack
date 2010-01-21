#ifndef SEARCH_OPTIONS_H__
#define SEARCH_OPTIONS_H__

#define MAX_SEARCH_LOCS 32

typedef struct {
    int use_gui;
    int noenv;              /* --noenv */
    int help;               /* --help  */
    int version;            /* --version */
    int thpppt;             /* --thppt */
    int ignore_case;        /* -i, --ignore-case */
    int color;              /* --[no]color, --[no]colour */
    char **ignore_dirs;     /* --ignore-dir=$dir */
    char **no_ignore_dirs;  /* --noignore-dir=$dir */
    char *search_term;      /* first unrecognized argument */
    int search_loc_count;
    char *search_loc[MAX_SEARCH_LOCS];       /* the rest of unrecognized arguments */
} search_options;

void init_search_options(search_options *opts);
void free_search_options(search_options *opts);
void add_search_location(search_options *opts, const char *search_loc);
void cmd_line_to_search_options(search_options *opts, int argc, char *argv[]);

#endif
