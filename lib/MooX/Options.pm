#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options;

# ABSTRACT: Options eXtension for Object Class

use strict;
use warnings;
our $VERSION = '4.001';    # VERSION
use Carp;

my @OPTIONS_ATTRIBUTES
    = qw/format short repeatable negativable autosplit doc long_doc order json/;

sub import {
    my ( undef, @import ) = @_;
    my $options_config = {
        protect_argv          => 1,
        flavour               => [],
        skip_options          => [],
        prefer_commandline    => 0,
        with_config_from_file => 0,

        #long description (manual)
        description => undef,
        authors     => [],
        synopsis    => undef,
        @import
    };

    my $target = caller;
    for my $needed_methods (qw/with around has/) {
        next if $target->can($needed_methods);
        croak
            "Can't find the method <$needed_methods> in <$target> ! Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.";
    }

    my $with   = $target->can('with');
    my $around = $target->can('around');
    my $has    = $target->can('has');

    my @target_isa;
    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    if (@target_isa) {    #only in the main class, not a role

        use warnings FATAL => 'redefine';
        ## no critic (ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval, ValuesAndExpressions::ProhibitImplicitNewlines)
        eval '{
        package ' . $target . ';

            sub _options_data {
                my ( $class, @meta ) = @_;
                return $class->maybe::next::method(@meta);
            }

            sub _options_config {
                my ( $class, @params ) = @_;
                return $class->maybe::next::method(@params);
            }

        1;
        }';
        use warnings FATAL => qw/void/;

        croak $@ if $@;

        $around->(
            _options_config => sub {
                my ( $orig, $self ) = ( shift, shift );
                return $self->$orig(@_), %$options_config;
            }
        );

        ## use critic
    }
    else {
        if ( $options_config->{with_config_from_file} ) {
            croak
                'Please, don\'t use the option <with_config_from_file> into a role.';
        }
    }

    my $options_data = {};
    if ( $options_config->{with_config_from_file} ) {
        $options_data->{config_prefix} = {
            format => 's',
            doc    => 'config prefix',
            order  => 0,
        };
        $options_data->{config_files} = {
            format => 's@',
            doc    => 'config files',
            order  => 0,
        };
    }

    my $apply_modifiers = sub {
        return if $target->can('new_with_options');
        $with->('MooX::Options::Role');
        if ( $options_config->{with_config_from_file} ) {
            $with->('MooX::ConfigFromFile::Role');
        }

        $around->(
            _options_data => sub {
                my ( $orig, $self ) = ( shift, shift );
                return ( $self->$orig(@_), %$options_data );
            }
        );
    };

    my @banish_keywords
        = qw/help man option new_with_options parse_options options_usage _options_data _options_config/;
    if ( $options_config->{with_config_from_file} ) {
        push @banish_keywords, qw/config_files config_prefix config_dirs/;
    }

    my $option = sub {
        my ( $name, %attributes ) = @_;
        for my $ban (@banish_keywords) {
            croak
                "You cannot use an option with the name '$ban', it is implied by MooX::Options"
                if $name eq $ban;
        }

        $has->( $name => _filter_attributes(%attributes) );

        $options_data->{$name}
            = { _validate_and_filter_options(%attributes) };

        $apply_modifiers->();
        return;
    };

    if ( my $info = $Role::Tiny::INFO{$target} ) {
        $info->{not_methods}{$option} = $option;
    }

    { no strict 'refs'; *{"${target}::option"} = $option; }

    $apply_modifiers->();

    return;
}

sub _filter_attributes {
    my %attributes = @_;
    my %filter_key = map { $_ => 1 } @OPTIONS_ATTRIBUTES;
    return map { ( $_ => $attributes{$_} ) }
        grep { !exists $filter_key{$_} } keys %attributes;
}

sub _validate_and_filter_options {
    my (%options) = @_;
    $options{doc} = $options{documentation} if !defined $options{doc};
    $options{order} = 0 if !defined $options{order};

    if ( $options{json} ) {
        delete $options{repeatable};
        delete $options{autosplit};
        delete $options{negativable};
        $options{format} = 's';
    }

    my %cmdline_options = map { ( $_ => $options{$_} ) }
        grep { exists $options{$_} } @OPTIONS_ATTRIBUTES, 'required';

    $cmdline_options{repeatable} = 1 if $cmdline_options{autosplit};
    $cmdline_options{format} .= "@"
        if $cmdline_options{repeatable}
        && defined $cmdline_options{format}
        && substr( $cmdline_options{format}, -1 ) ne '@';

    croak
        "Negativable params is not usable with non boolean value, don't pass format to use it !"
        if $cmdline_options{negativable} && defined $cmdline_options{format};

    return %cmdline_options;
}

1;

__END__

=pod

=head1 NAME

MooX::Options - Options eXtension for Object Class

=head1 VERSION

version 4.001

=head1 SYNOPSIS

    package myOptions;
    use Moo;
    use MooX::Options;
    
    option 'show_this_file' => (
        is => 'ro',
        format => 's',
        required => 1,
        doc => 'the file to display'
    );
    1;
    
    package main;
    use feature 'say';
    use Path::Class;
    
    my $opt = myOptions->new_with_options;
    
    say "Content of the file : ",
         file($opt->show_this_file)->slurp;

=head1 DESCRIPTION

Create a command line tools with your L<Mo>, L<Moo>, L<Moose> objects.

MooX::Options pass specific parameters to L<Getopt::Long::Descriptive>
to generate from your attribute the command line options.

=head1 DOCUMENTATIONS

=over

=item * L<QuickStart|MooX::Options::Docs::QuickStart>

=item * L<Philosophy|MooX::Options::Docs::Philosophy>

=item * L<Imported methods|MooX::Options::Docs::ImportedMethods>

=item * L<Import parameters|MooX::Options::Docs::ImportParameters>

=item * L<Option parameters|MooX::Options::Docs::Option>

=item * L<Man parameters|MooX::Options::Docs::Man>

=item * L<Using namespace::clean|MooX::Options::Docs::NamespaceClean>

=item * L<Manage your tools with MooX::Cmd|MooX::Options::Docs::MooXCmd>

=back

=head1 EXTERNAL EXAMPLES

=over

=item * L<Slide3D about MooX::Options|http://perltalks.celogeek.com/slides/2012/08/moox-options-slide3d.html>

=back

=head1 THANKS

=over

=item Matt S. Trout (mst) <mst@shadowcat.co.uk> : For his patience and advice.

=item Tomas Doran (t0m) <bobtfish@bobtfish.net> : To help me release the new version, and using it :)

=item Torsten Raudssus (Getty) : to use it a lot in L<DuckDuckGo|http://duckduckgo.com> (go to see L<MooX> module also)

=item Jens Rehsack (REHSACK) : Use with L<PkgSrc|http://www.pkgsrc.org/>, and many really good idea (L<MooX::Cmd>, L<MooX::ConfigFromFile>, and more to come I'm sure)

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/MooX-Options/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
