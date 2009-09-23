#!perl

use warnings;
use strict;

use Test::More tests => 6;

use lib 't';
use Util;

prep_environment();

TRAILING_PUNC: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
        'Bill or George! Anything but Sue! I still hate that name!',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -w -h --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for Sue!' );
}

TRAILING_METACHAR_BACKSLASH_W: {
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = qw( mu\w -w -h --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for mu\\w' );
}


TRAILING_METACHAR_DOT: {
    local $TODO = q{I can't figure why the -w works from the command line, but not inside this test};
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = ( 'mu.', qw( -w -h --text ) );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for mu.' );
}


