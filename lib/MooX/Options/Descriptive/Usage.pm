#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options::Descriptive::Usage;

# ABSTRACT: Usage class

use strict;
use warnings;
our $VERSION = '4.002';    # VERSION
use feature 'say';
use Text::WrapI18N;
use Term::Size::Any qw/chars/;
use Getopt::Long::Descriptive;
use Scalar::Util qw/blessed/;

my %format_doc = (
    's'  => 'String',
    's@' => '[Strings]',
    'i'  => 'Int',
    'i@' => '[Ints]',
    'o'  => 'Ext. Int',
    'o@' => '[Ext. Ints]',
    'f'  => 'Real',
    'f@' => '[Reals]',
);

my %format_long_doc = (
    's'  => 'String',
    's@' => 'Array of Strings',
    'i'  => 'Integer',
    'i@' => 'Array of Integers',
    'o'  => 'Extended Integer',
    'o@' => 'Array of extended integers',
    'f'  => 'Real number',
    'f@' => 'Array of real numbers',
);

sub new {
    my ( $class, $args ) = @_;

    my %self;
    @self{qw/options leader_text/} = @$args{qw/options leader_text/};

    return bless \%self => $class;
}

sub leader_text { return shift->{leader_text} }

sub sub_commands_text {
    my ($self) = @_;
    my $sub_commands
        = defined $self->{target}
        ? $self->{target}->_options_sub_commands() // []
        : [];
    return if !@$sub_commands;
    return "", 'SUB COMMANDS AVAILABLE: ' . join( ', ', @$sub_commands ), "";
}

sub text {
    my ($self) = @_;

    return join( "\n",
        $self->leader_text, $self->option_text, $self->sub_commands_text );
}

# set the column size of your terminal into the wrapper
sub _set_column_size {
    my ($columns) = chars();
    $columns //= 78;
    $columns = $ENV{TEST_FORCE_COLUMN_SIZE}
        if defined $ENV{TEST_FORCE_COLUMN_SIZE};
    $Text::WrapI18N::columns = $columns - 4;
    return;
}

sub option_text {
    my ($self) = @_;
    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my $getopt_options = $self->{options};
    my @message;
    _set_column_size;
    for my $opt (@$getopt_options) {
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};
        push @message,
              ( defined $short ? "-" . $short . " " : "" ) . "-"
            . ( length( $opt->{name} ) > 1 ? "-" : "" )
            . $opt->{name} . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );
        push @message, wrap( "    ", "        ", $opt->{desc} );
        push @message, "";
    }

    return join( "\n    ", "", @message );
}

sub option_pod {
    my ($self) = @_;

    my %options_data
        = defined $self->{target} ? $self->{target}->_options_data : ();
    my %options_config
        = defined $self->{target} ? $self->{target}->_options_config : ();

    my $prog_name = $self->{prog_name}
        // Getopt::Long::Descriptive::prog_name;

    my $sub_commands
        = defined $self->{target}
        ? $self->{target}->_options_sub_commands() // []
        : [];

    my @man = ( "=head1 NAME", $prog_name, );

    if ( defined( my $description = $options_config{description} ) ) {
        push @man, "=head1 DESCRIPTION", $description;
    }

    push @man,
        ( "=head1 SYNOPSIS", $prog_name . " [-h] [long options ...]", );

    if ( defined( my $synopsis = $options_config{synopsis} ) ) {
        push @man, $synopsis;
    }

    push @man, ( "=head1 OPTIONS", "=over" );

    for my $opt ( @{ $self->{options} } ) {

        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_long_doc{$format} if defined $format;
        $format_doc_str = 'JSON'
            if defined $options_data{ $opt->{name} }{json};

        my $opt_long_name
            = "-" . ( length( $opt->{name} ) > 1 ? "-" : "" ) . $opt->{name};
        my $opt_name
            = ( defined $short ? "-" . $short . " " : "" )
            . $opt_long_name . ":"
            . ( defined $format_doc_str ? " " . $format_doc_str : "" );

        push @man, "=item B<" . $opt_name . ">";

        my $opt_data = $options_data{ $opt->{name} } // {};
        push @man, $opt_data->{long_doc} // $opt->{desc};

    }
    push @man, "=back";

    if (@$sub_commands) {
        push @man, "=head1 AVAILABLE SUB COMMANDS";
        push @man, "=over";
        for my $sub_command (@$sub_commands) {
            push @man,
                (
                "=item B<" . $sub_command . "> :",
                $prog_name . " " . $sub_command . " [-h] [long options ...]",
                );
        }
        push @man, "=back";
    }

    if ( defined( my $authors = $options_config{authors} ) ) {
        if ( !ref $authors && length($authors) ) {
            $authors = [$authors];
        }
        if (@$authors) {
            push @man, ( "=head1 AUTHORS", "=over" );
            push @man, map { "=item B<" . $_ . ">" } @$authors;
            push @man, "=back";
        }
    }

    return join( "\n\n", @man );
}

sub warn { return CORE::warn shift->text }

sub die {
    my ($self) = @_;
    $self->{should_die} = 1;
    return;
}

use overload (
    q{""} => "text",
    '&{}' => sub {
        my ($self) = @_;
        return
            sub { my ($self) = @_; return $self ? $self->text : $self->warn; };
    }
);

1;

__END__

=pod

=head1 NAME

MooX::Options::Descriptive::Usage - Usage class

=head1 VERSION

version 4.002

=head1 DESCRIPTION

Usage class to display the error message.

This class use the full size of your terminal

=head1 METHODS

=head2 new

The object is create with L<MooX::Options::Descriptive>.

Valid option is :

=over

=item leader_text

Text that appear on top of your message

=item options

The options spec of your message

=back

=head2 leader_text

Return the leader_text.

=head2 sub_commands_text

Return the list of sub commands if available.

=head2 text

Return the full text help, leader and option text.

=head2 option_text

Return the help message for your options

=head2 option_pod

Return the usage message in pod format

=head2 warn

Warn your options help message

=head2 die

Croak your options help message

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
