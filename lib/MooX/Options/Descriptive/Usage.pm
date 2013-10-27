#
# This file is part of MooX-Options
#
# This software is copyright (c) 2011 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options::Descriptive::Usage;

# ABSTRACT: Usage class

use strict;
use warnings;
our $VERSION = '3.94';    # VERSION
use feature 'say';
use Text::WrapI18N;
use Term::Size::Any qw/chars/;

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

sub new {
    my ( $class, $args ) = @_;

    my %self;
    @self{qw/options leader_text/} = @$args{qw/options leader_text/};

    return bless \%self => $class;
}

sub leader_text { return shift->{leader_text} }

sub text {
    my ($self) = @_;

    return join( "\n", $self->leader_text, $self->option_text );
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
    my $options = $self->{options};

    my @message;
    _set_column_size;
    for my $opt (@$options) {
        my ( $short, $format ) = $opt->{spec} =~ /(?:\|(\w))?(?:=(.*?))?$/x;
        my $format_doc_str;
        $format_doc_str = $format_doc{$format} if defined $format;
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

sub warn { return CORE::warn shift->text }

sub die { return CORE::die shift->text }

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

version 3.94

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

=head2 text

Return the full text help, leader and option text.

=head2 option_text

Return the help message for your options

=head2 warn

Warn your options help message

=head2 die

Croak your options help message

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
