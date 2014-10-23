#
# This file is part of MooX-Options
#
# This software is copyright (c) 2011 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options::Role;

# ABSTRACT: role that is apply to your object
use strict;
use warnings;

our $VERSION = '3.78';    # VERSION

use MRO::Compat;
use Moo::Role;
use Getopt::Long 2.38;
use Getopt::Long::Descriptive 0.091;
use Regexp::Common;
use Data::Record;

requires qw/_options_data _options_config/;

sub new_with_options {
    my ( $class, @params ) = @_;
    return $class->new( $class->parse_options(@params) );
}

## no critic qw/Modules::ProhibitExcessMainComplexity/
sub parse_options {
    my ( $class, %params ) = @_;
    my %options_data   = $class->_options_data;
    my %options_config = $class->_options_config;
    my @skip_options;
    @skip_options = @{ $options_config{skip_options} }
        if defined $options_config{skip_options};
    if (@skip_options) {
        delete @options_data{@skip_options};
    }
    my @options;

    my $option_name = sub {
        my ( $name, %data ) = @_;
        my $cmdline_name = $name;
        $cmdline_name .= '|' . $data{short} if defined $data{short};

        #dash name support
        my $dash_name = $name;
        $dash_name =~ tr/_/-/;
        if ( $dash_name ne $name ) {
            $cmdline_name .= '|' . $dash_name;
        }

        $cmdline_name .= '+' if $data{repeatable} && !defined $data{format};
        $cmdline_name .= '!' if $data{negativable};
        $cmdline_name .= '=' . $data{format} if defined $data{format};
        return $cmdline_name;
    };

    my %has_to_split;
    my @sorted_keys = sort {
        $options_data{$a}{order} <=> $options_data{$b}{order}  # sort by order
            or $a cmp $b    # sort by attr name
    } keys %options_data;
    for my $name (@sorted_keys) {
        my %data = %{ $options_data{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;
        push @options, [ $option_name->( $name, %data ), $doc ];
        $has_to_split{$name}
            = Data::Record->new(
            { split => $data{autosplit}, unless => $RE{quoted} } )
            if defined $data{autosplit};
    }

    local @ARGV = @ARGV if $options_config{protect_argv};
    if (%has_to_split) {
        my @new_argv;

        #parse all argv
        for my $i ( 0 .. $#ARGV ) {
            my $arg = $ARGV[$i];
            my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
            $arg_name =~ s/^--?//x;
            unless ( defined $arg_values ) {
                $arg_values = $ARGV[ ++$i ];
            }
            if ( my $rec = $has_to_split{$arg_name} ) {
                foreach my $record ( $rec->records($arg_values) ) {

                    #remove the quoted if exist to chain
                    $record =~ s/^['"]|['"]$//gx;
                    push @new_argv, "--$arg_name", $record;
                }
            }
            else {
                push @new_argv, $arg;
            }
        }
        @ARGV = @new_argv;
    }

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
    }
    my ( $opt, $usage )
        = describe_options( ("USAGE: %c %o"), @options,
        [ 'help|h', "show this help message" ], @flavour );
    if ( $opt->help() || defined $params{help} ) {
        print $usage, "\n";
        my $exit_code = 0;
        $exit_code = 0 + $params{help} if defined $params{help};
        exit($exit_code);
    }

    my @missing_required;
    my %cmdline_params = %params;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name}
            || $options_config{prefer_commandline} )
        {
            my $val = $opt->$name();
            if ( defined $val ) {
                $cmdline_params{$name} = $val;
            }
        }
        push @missing_required, $name
            if $data{required} && !defined $cmdline_params{$name};
    }

    if (@missing_required) {
        print join( "\n", ( map { $_ . " is missing" } @missing_required ),
            '' );
        print $usage, "\n";
        exit(1);
    }

    return %cmdline_params;
}
## use critic

sub options_usage {
    my ( $self, $code, @messages ) = @_;
    $code = 0 if !defined $code;
    print join( "\n", @messages, '' ) if @messages;
    local @ARGV = ();
    return $self->parse_options( help => $code );
}

1;

__END__

=pod

=head1 NAME

MooX::Options::Role - role that is apply to your object

=head1 VERSION

version 3.78

=head1 METHODS

=head2 new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=head2 parse_options

Parse your options, call L<Getopt::Long::Descriptve> and convert the result for the "new" method.

It is use by "new_with_options".

=head2 options_usage

Display help message.

Check full doc L<MooX::Options> for more details.

=head1 USAGE

Don't use MooX::Options::Role directly. It is used by L<MooX::Options> to upgrade your module. But it is useless alone.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://tasks.celogeek.com/projects/perl-modules-moox-options

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
