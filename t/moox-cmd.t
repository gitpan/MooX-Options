#!/usr/bin/env perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2011 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

BEGIN {
    eval 'use MooX::Cmd';
    if ($@) {
        plan skip_all => 'Need MooX::Cmd for this test';
        exit 0;
    }
}

use t::lib::MooXCmdTest;

trap {
    local @ARGV = ('-h');
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t [-h]\E}, 'base command help ok';

trap {
    local @ARGV = ( 'test1', '-h' );
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 [-h]\E}, 'subcommand 1 ok';

trap {
    local @ARGV = ( 'test1', 'test2', '-h' );
    t::lib::MooXCmdTest->new_with_cmd;
};

like $trap->stdout, qr{\QUSAGE: moox-cmd.t test1 test2 [-h]\E},
    'subcommand 2 ok';

done_testing;
