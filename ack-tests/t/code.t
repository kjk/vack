#!perl -Tw

use warnings;
use strict;

use Test::More;

my @files = ( qw( ack ack-base Ack.pm ), glob( 't/*.t' ) );

plan tests => scalar @files;

for my $file ( @files ) {
    local $/ = undef;
    open( my $fh, '<', $file ) or die "Can't read $file: \n";
    my $text = <$fh>;
    close $fh or die;

    is( index($text, "\t"), -1, "$file should have no embedded tabs" );
}
