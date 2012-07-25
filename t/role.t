#!perl
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

{

    package myRole;
    use strict;
    use warnings;
    use MooX::Options::Role;

    option 'multi' => ( is => 'rw', doc => 'multi threading mode' );
    1;
}

{

    package testRole;
    use Moo;
    use MooX::Options;
    myRole->import;
    1;
}

{
    local @ARGV;
    @ARGV = ();
    my $opt = testRole->new_with_options;
    ok( !$opt->multi, 'multi not set' );
}
{
    local @ARGV;
    @ARGV = ('--multi');
    my $opt = testRole->new_with_options;
    ok( $opt->multi, 'multi set' );
    trap {
        $opt->option_usage;
    };
    ok( $trap->stdout =~ /\-\-multi\s+multi\sthreading\smode/x,
        "usage method is properly set" );
}

done_testing;
1;
