#import <Cocoa/Cocoa.h>

int g_argc;
char **g_argv;

int main(int argc, char *argv[])
{
    // remember argc/argv so that I can access them elsewhere
    g_argc = argc;
    g_argv = argv;
    return NSApplicationMain(argc,  (const char **) argv);
}
