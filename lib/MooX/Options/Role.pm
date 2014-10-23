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

our $VERSION = '3.98';    # VERSION

use MRO::Compat;
use Moo::Role;
use MooX::Options::Descriptive;
use Regexp::Common;
use Data::Record;
use JSON;
use Carp;

requires qw/_options_data _options_config/;

sub new_with_options {
    my ( $class, %params ) = @_;
    my $self;
    my %cmdline_params = $class->parse_options(%params);

    if ( $cmdline_params{help} ) {
        return $class->options_usage( $params{help}, $cmdline_params{help} );
    }

    return $self
        if eval { $self = $class->new(%cmdline_params); 1 };
    if ( $@ =~ /^Attribute\s\((.*?)\)\sis\srequired/x ) {
        print "$1 is missing\n";
    }
    elsif ( $@ =~ /^Missing\srequired\sarguments:\s(.*)\sat\s\(/x ) {
        my @missing_required = split /,\s/x, $1;
        print join( "\n", ( map { $_ . " is missing" } @missing_required ),
            '' );
    }
    elsif ( $@ =~ /^(.*?)\srequired/x ) {
        print "$1 is missing\n";
    }
    else {
        croak $@;
    }
    %cmdline_params = $class->parse_options( help => 1 );
    return $class->options_usage( 1, $cmdline_params{help} );
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
    for my $name (
        sort {
            $options_data{$a}{order}
                <=> $options_data{$b}{order}    # sort by order
                or $a cmp $b                    # sort by attr name
        } keys %options_data
        )
    {
        my %data = %{ $options_data{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;

        push @options, [ $option_name->( $name, %data ), $doc ];
        if ( defined $data{autosplit} ) {
            $has_to_split{"--${name}"} = Data::Record->new(
                { split => $data{autosplit}, unless => $RE{quoted} } );
            if ( my $short = $data{short} ) {
                $has_to_split{"-${short}"} = $has_to_split{"--${name}"};
            }
            for ( my $i = 1; $i < length($name); $i++ ) {
                my $long_short = substr( $name, 0, $i );
                $has_to_split{"--${long_short}"} = $has_to_split{"--${name}"};
            }
        }
    }

    local @ARGV = @ARGV if $options_config{protect_argv};
    if (%has_to_split) {
        my @new_argv;

        #parse all argv
        for my $i ( 0 .. $#ARGV ) {
            my $arg = $ARGV[$i];
            my ( $arg_name, $arg_values ) = split( /=/x, $arg, 2 );
            unless ( defined $arg_values ) {
                $arg_values = $ARGV[ ++$i ];
            }
            if ( my $rec = $has_to_split{$arg_name} ) {
                foreach my $record ( $rec->records($arg_values) ) {

                    #remove the quoted if exist to chain
                    $record =~ s/^['"]|['"]$//gx;
                    push @new_argv, $arg_name, $record;
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

    my $prog_name = Getopt::Long::Descriptive::prog_name;

    # support of MooX::Cmd
    if ( ref $params{command_chain} eq 'ARRAY' ) {
        for my $cmd ( @{ $params{command_chain} } ) {
            next if !ref $cmd;
            next if !UNIVERSAL::can( $cmd, 'isa' );
            next if !$cmd->can('command_name');
            if ( defined( my $cmd_name = $cmd->command_name ) ) {
                $prog_name .= ' ' . $cmd_name;
            }
        }
    }

    # list of all sub command
    my $sub_command;
    if ( ref $params{command_commands} eq 'HASH' ) {
        $sub_command
            = join( ' | ', sort keys %{ $params{command_commands} } );
        if ( length($sub_command) ) {
            $sub_command = "[" . $sub_command . "]";
        }
    }

    # create usage str
    my $usage_str = "USAGE: $prog_name";
    $usage_str .= " " . $sub_command if defined $sub_command;
    $usage_str .= " %o";

    my ( $opt, $usage )
        = describe_options( ($usage_str), @options,
        [ 'help|h', "show this help message" ], @flavour );

    my %cmdline_params = %params;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name}
            || $options_config{prefer_commandline} )
        {
            my $val = $opt->$name();
            if ( defined $val ) {
                if ( $data{json} ) {
                    $cmdline_params{$name} = decode_json($val);
                }
                else {
                    $cmdline_params{$name} = $val;
                }
            }
        }
    }

    if ( $opt->help() || defined $params{help} ) {
        $cmdline_params{help} = $usage;
    }

    return %cmdline_params;
}
## use critic

sub options_usage {
    my ( $class, $code, @messages ) = @_;
    my $usage;
    if ( @messages
        && ref $messages[-1] eq 'MooX::Options::Descriptive::Usage' )
    {
        $usage = shift @messages;
    }
    $code = 0 if !defined $code;
    print join( "\n", @messages, '' ) if @messages;
    if ( !$usage ) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    print $usage . "\n";
    exit($code) if $code >= 0;
    return;
}

1;

__END__

=pod

=head1 NAME

MooX::Options::Role - role that is apply to your object

=head1 VERSION

version 3.98

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
https://tasks.celogeek.com/projects/perl-modules-moox-options

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
