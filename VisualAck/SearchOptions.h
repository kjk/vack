#ifndef SEARCH_OPTIONS_H__
#define SEARCH_OPTIONS_H__

typedef struct {
    int use_gui;
    int noenv;              /* --noenv */
    int help;               /* --help  */
    int version;            /* --version */
    int thpppt;             /* --thppt */
    int ignore_case;        /* -i, --ignore-case */
    char **ignore_dirs;     /* --ignore-dir=$dir */
    char **no_ignore_dirs;  /* --noignore-dir=$dir */
} search_options;

extern search_options g_default_search_options;

void free_search_options(search_options *options);
void cmd_line_to_search_options(search_options *opts, int argc, char *argv[]);

#endif
