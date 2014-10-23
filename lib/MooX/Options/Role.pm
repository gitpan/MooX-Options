#
# This file is part of MooX-Options
#
# This software is copyright (c) 2011 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options::Role;

# ABSTRACT: create role with option
use strict;
use warnings;
our $VERSION = '2.3';    # VERSION
use Carp;

my %Options;

sub import {
    my $option_role_meth = sub {
        my ( $name, %options ) = @_;
        $Options{$name} = \%options;
    };

    my $import_meth = sub {
        my $caller = caller;
        ## no critic qw(ProhibitPackageVars)
        my $option_meth_name = $caller::MooX_Options_Option_Name;
        ## use critic
        croak "MooX::Options should be import before using this role"
            unless defined $option_meth_name;
        my $option_meth = $caller->can($option_meth_name);
        for my $name ( keys %Options ) {
            my %option = %{ $Options{$name} };
            $option_meth->( $name, %option );
        }
    };

    my $caller = caller;
    {
        ## no critic qw(ProhibitNoStrict)
        no strict qw/refs/;
        *{"${caller}::option"} = $option_role_meth;
        *{"${caller}::import"} = $import_meth;
        ## use critic
    }
    return;
}

1;

__END__
=pod

=head1 NAME

MooX::Options::Role - create role with option

=head1 VERSION

version 2.3

=head1 SYNOPSIS

    use strict;
    use warnings;
    use v5.16;
    {package myRole;
     use MooX::Options::Role;
     option 'multi' => (is => 'rw', doc => 'multi threaded mode');
     1;
    }
    {package myOpt;
    use Moo;
    use MooX::Options;
    myRole->import;
    1;
    }

    my $opt = myOpt->new_with_options();
    say "Multi : ",$opt->multi;

You take a look at t/role.t for more example.

=head1 METHODS

=head2 import
Import method "option" that will be transmit to L<MooX::Options> when the role is used.

If you decide to change the "option" key in the import of L<MooX::Options>, L<MooX::Options::Role> will know and call the appropriate method.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/MooX-Options/issues

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

