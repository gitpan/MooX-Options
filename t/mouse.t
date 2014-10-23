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
    use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Mouse for this test'
        unless check_install( module => 'Mouse' );
}

{

    package t;
    use Mouse;
    use MooX::Options filter => 'Mouse';

    option 'bool'    => ( is => 'ro' );
    option 'counter' => ( is => 'ro', repeatable => 1 );
    option 'empty'   => ( is => 'ro', negativable => 1 );
    option 'split'   => ( is => 'ro', format => 'i@', autosplit => ',' );

    1;
}

{

    package r;
    use Mouse;
    use MooX::Options filter => 'Mouse';

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}
{

    package sp_str;
    use Mouse;
    use MooX::Options filter => 'Mouse';

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );

    1;
}

{

    package d;
    use Mouse;
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', trigger => sub { die "this will die ok" } );
    1;
}

{

    package multi_req;
    use Mouse;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}

{

    package t_doc;
    use Mouse;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}

subtest "Mouse" => sub {
    note "Test Mouse";
    require $RealBin . '/base.st';
};

done_testing;
