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

BEGIN {
    use Module::Load::Conditional qw/check_install/;
    plan skip_all => 'Need Moo for this test'
        unless check_install( module => 'Moo' );
}

for my $meth (
    qw/creation_chain_method creation_method_name option_chain_method option_method_name/
    )
{
    eval <<EOF
    package FailureUndefOption;
    use Moo;
    use MooX::Options $meth => undef;
    1;
EOF
        ;
    like $@, qr/^missing\soption\s$meth,\scheck\sdoc\sto\sdefine\sone/x,
        "$meth parameters should be defined";
}

for my $meth (qw/creation_chain_method option_chain_method/) {
    eval <<EOF
    package FailureChainMethod;
    use Moo;
    use MooX::Options $meth => 'missing_method';
EOF
        ;
    like $@,
        qr/^method\smissing_method\sis\snot\sdefined,\scheck\sdoc\sto\suse\sanother\sname/x,
        "$meth point to a missing method";
}

for my $meth (qw/creation_method_name option_method_name/) {
    eval <<EOF
    package FailureChainMethod;
    use Moo;
    use MooX::Options $meth => 'has';
EOF
        ;
    like $@,
        qr/^method\shas\salready\sdefined,\scheck\sdoc\sto\suse\sanother\sname/x,
        "$meth point to a defined method";
}

eval <<EOF
    package FailureNegativableWithFormat;
    use Moo;
    use MooX::Options;

    option fail => (
        is => 'rw',
        negativable => 1,
        format => 'i',
    );

    1;
EOF
    ;
like $@,
    qr/^Negativable\sparams\sis\snot\susable\swith\snon\sboolean\svalue,\sdon't\spass\sformat\sto\suse\sit\s\!/x,
    "negativable and format are incompatible";

eval <<EOF
    package FailureHelp;
    use Moo;
    use MooX::Options;

    option help => (
        is => 'rw',
    );
EOF
    ;
like $@,
    qr/^Can't\suse\soption\swith\shelp,\sit\sis\simplied\sby\sMooX::Options/x,
    "help method can't be defined";

eval <<EOF
    package FailureUsage;
    use Moo;
    use MooX::Options;

    option option_usage => (
        is => 'rw',
    );
EOF
    ;
like $@,
    qr/^Can't\suse\soption\swith\soption_usage,\sit\sis\simplied\sby\sMooX::Options/x,
    "usage is already autogenerated";

eval <<EOF
    package FailureOptionChainMethod;
    use Moo;

    sub failure {
        #do nothing to create attribute with the right name
    }

    use MooX::Options option_chain_method => 'failure';

    option t => (
        is => 'rw',
    );
    1;
    package main;
    FailureOptionChainMethod->new_with_options;
EOF
    ;
like $@,
    qr/^attribute\st\sisn't\sdefined\.\sYou\shave\ssomething\swrong\sin\syour\soption_chain_method\s'failure'\./x,
    "option_chain_method do nothing to create attribute with the same name";

eval <<EOF
{package myRole;
    use MooX::Options::Role;
    option t => (is => 'rw');
    1;
}

{package FailureMissMooXOptionWithRole;
    myRole->import;
    1;
}
EOF
    ;
like $@,
    qr/^MooX::Options\sshould\sbe\simport\sbefore\susing\sthis\srole\./x, "";

done_testing;
