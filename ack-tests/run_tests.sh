#!/bin/sh
#/opt/local/bin/perl -T ack --noenv --help > ack-help.txt || perl -e0
#/opt/local/bin/perl -T ack --noenv --help=types > ack-help-types.txt || perl -e0
cp ack blib/script/ack
/opt/local/bin/perl "-MExtUtils::MY" -e "MY->fixin(shift)" blib/script/ack
PERL_DL_NONLAZY=1 /opt/local/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
