#!perl

use warnings;
use strict;

use Test::More tests => 16;
use File::Next 0.34; # For the reslash() function

use lib 't';
use Util;

prep_environment();

G_NO_PRINT0: {
    my @expected = qw(
        t/text/4th-of-july.txt
        t/text/freedom-of-choice.txt
        t/text/science-of-myth.txt
    );

    my $filename_regex = 'of';
    my @files = qw( t/text/ );
    my @args = ( '-g', $filename_regex, '--text', '--sort-files' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Files found with -g and without --print0' );
    is( (grep { /\0/ } @results), 0, ' ... no null byte in output' );
}

G_PRINT0: {
    my $expected = join( "\0", map { File::Next::reslash($_) } qw(
        t/text/4th-of-july.txt
        t/text/freedom-of-choice.txt
        t/text/science-of-myth.txt
    ) ) . "\0"; # string of filenames separated and concluded with null byte

    my $filename_regex = 'of';
    my @files = qw( t/text );
    my @args = ( '-g', $filename_regex, '--text', '--sort-files', '--print0' );
    my @results = run_ack( @args, @files );

    is( scalar @results, 1, 'Only one line of output with --print0' );
    is( $results[0], $expected, 'Files found with -g and with --print0' );
}

F_PRINT0: {
    my @files = qw( t/text/ );
    my @args = qw( -f --text --print0 );
    my @results = run_ack( @args, @files );

    # checking for exact files is fragile, so just see whether we have \0 in output
    ok( @results == 1, 'Only one line of output with -f and --print0' );
    ok( ( grep { /\0/ } @results ), ' ... and null bytes in output' );
}

L_PRINT0: {
    my $regex = 'of';
    my @files = qw( t/text/ );
    my @args = ( '-l', '--text', '--print0', $regex );
    my @results = run_ack( @args, @files );

    # checking for exact files is fragile, so just see whether we have \0 in output
    ok( @results == 1, 'Only one line of output with -l and --print0' );
    ok( ( grep { /\0/ } @results ), ' ... and null bytes in output' );
}

COUNT_PRINT0: {
    my $regex = 'of';
    my @files = qw( t/text/ );
    my @args = ( '--count', '--text', '--print0', $regex );
    my @results = run_ack( @args, @files );

    # checking for exact files is fragile, so just see whether we have \0 in output
    ok( @results == 1, 'Only one line of output with --count and --print0' );
    ok( ( grep { /\0/ } @results ), ' ... and null bytes in output' );
    ok( ( grep { /:\d+/ } @results ), ' ... and ":\d+" in output, so the counting also works' );
}

