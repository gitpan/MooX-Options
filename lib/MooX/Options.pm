#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options;

# ABSTRACT: Explicit Options eXtension for Object Class

use strict;
use warnings;
our $VERSION = '4.005';    # VERSION
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
        = qw/help man usage option new_with_options parse_options options_usage _options_data _options_config/;
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

MooX::Options - Explicit Options eXtension for Object Class

=head1 VERSION

version 4.005

=head1 SYNOPSIS

In myOptions.pm :

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

In myTool.pl :

  use feature 'say';
  use myOptions;
  use Path::Class;
  
  my $opt = myOptions->new_with_options;
  
  say "Content of the file : ",
       file($opt->show_this_file)->slurp;

To use it :

  perl myTool.pl --show_this_file=myFile.txt
  Content of the file: myFile content

The help message :

  perl myTool.pl --help
  USAGE: myTool.pl [-h] [long options...]
  
      --show_this_file: String
          the file to display
      
      -h --help:
          show this help message
      
      --man:
          show the manual

The usage message :

  perl myTool.pl --usage
  USAGE: myTool.pl [ --show_this_file=String ] [ --usage ] [ --help ] [ --man ]

The manual :

  perl myTool.pl --man

=head1 DESCRIPTION

Create a command line tool with your L<Mo>, L<Moo>, L<Moose> objects.

Everything is explicit. You have an 'option' keyword to replace the usual 'has' to explicitly use your attribute into the command line.

The 'option' keyword takes additional parameters and use L<Getopt::Long::Descriptive>
to generate a command line tool.

=head1 IMPORTED METHODS

The list of the methods automatically imported into your class.

=head2 new_with_options

It will parse your command line params and your inline params, validate and call the 'new' method.

  myTool --str=ko

  t->new_with_options()->str # ko
  t->new_with_options(str => 'ok')->str #ok

=head2 option

The option keyword replace the 'has' method, and add support specials options for the command line only.

See L</OPTION PARAMETERS> for the documentation.

=head2 options_usage | --help

It display the usage message and return the exit code

  my $t = t->new_with_options();
  my $exit_code = 1;
  my $pre_message = "str is not valid";
  $t->options_usage($exit_code, $pre_message);

This method is also automatically fire if the command option "--help" is passed.

  myTool --help

=head2 options_man | --man

It display the manual.

  my $t = t->new_with_options();
  $t->options_man();

This is automatically fire if the command option "--man" is passed.

  myTool --man

=head2 options_short_usage | --usage

It display a short version of the help message.

  my $t = t->new_with_options();
  $t->options_short_usage($exit_code);

This is automatically fire if the command option "--usage" is passed.

  myTool --usage

=head1 IMPORT PARAMETERS

The list of parameters support by L<MooX::Options>.

=head2 flavour

Pass extra arguments for L<Getopt::Long::Descriptive>. It is usefull if you
want to configure Getopt::Long.

  use MooX::Options flavour => [qw( pass_through )];

Any flavour is pass to L<Getopt::Long> as a configuration, check the doc to see what is possible.

=head2 protect_argv

By default, @ARGV is protected. if you want to do something else on it, use this option and it will change the real @ARGV.

  use MooX::Options protect_argv => 0;

=head2 skip_options

If you have Role with options and your want to disactivate some of them, you can use this parameter.
In that case, the 'option' keyword will just works like an 'has'.

  use MooX::Options skip_options => [qw/multi/];

=head2 prefer_commandline

By default, arguments to B<new_with_options> have a higher priority than the commandline options.

This parameter give to the commandline an higher priority.

  use MooX::Options prefer_commandline => 1;

=head2 with_config_from_file

This parameter will load L<MooX::ConfigFromFile> in your module. 
The config option will be used between the commandline and the parameters.

myTool :

  use MooX::Options with_config_from_file => 1;

In /etc/myTool.json

  {"test" : 1}

=head1 OPTION PARAMETERS

The keyword B<option> extend the keyword B<has> with specific parameters for the commandline.

=head2 doc | documentation

Documentation for the command line option.

=head2 long_doc

Documentation for the man page. By default the B<doc> parameter will be used.

See also L<Man parameters|MooX::Options::Manual::Man> to get more examples to build a nice man page.

=head2 required

This attribute indicate that the parameter is mandatory.
This attribute is not really used by L<MooX::Options> but the error message will be handle by it to
display a consistant error message.

=head2 format

Format of the params. It is the same as L<Getopt::Long::Descriptive>.

=over

=item * i : integer

=item * i@: array of integer

=item * s : string

=item * s@: array of string

=item * f : float value

=back

By default, it's a boolean value.

Take a look of available formats with L<Getopt::Long::Descriptive>.

You need to understand that everything is explicit here. 
If you use L<Moose> and you attribute has B<isa => 'Array[Int]'>, that will not implied the format 'i@'.

=head2 format json : special format support

The parameter will be treat like a json string.

  option 'hash' => (is => 'ro', json => 1);

  myTool --hash='{"a":1,"b":2}' # hash = { a => 1, b => 2 }

=head2 negativable

It add the negative version for the option.

  option 'verbose' => (is => 'ro', negativable => 1);

  myTool --verbose    # verbose = 1
  myTool --no-verbose # verbose = 0

=head2 repeatable

It append to the L</format> the array attribute B<@>.

I advice to add a default value to your attribute to always have an array.
Otherwise the default value will be an undefined value.

  option foo => (is => 'rw', format => 's@', default => sub { [] });

  myTool --foo="abc" --foo="def" # foo = ["abc", "def"]

=head2 autosplit

For repeatable option, you can add the autosplit feature with your specific parameters.

  option test => (is => 'ro', format => 'i@', default => sub {[]}, autosplit => ',');
  
  myTool --test=1 --test=2 # test = (1, 2)
  myTool --test=1,2,3      # test = (1, 2, 3)

It will also handle quoted params with the autosplit

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autosplit => ',');

  myTool --testStr='a,b,"c,d",e,f' # testStr ("a", "b", "c,d", "e", "f")

=head2 short

Long option can also have short version or aliased.

  option 'verbose' => (is => 'ro', short => 'v');

  myTool --verbose # verbose = 1
  myTool -v        # verbose = 1

  option 'account_id' => (is => 'ro', format => 'i', short => 'a|id');

  myTool --account_id=1
  myTool -a=1
  myTool --id=1

You can also use a shorter option without attribute :

  option 'account_id' => (is => 'ro', format => 'i');

  myTool --acc=1
  myTool --account=1

=head2 order

Specified the order of the attribute. If you want to push some attribute at the end of the list.
By default all option has an order set to B<0>, and the option is sorted by their name.

  option 'at_the_end' => (is => 'ro', order => 999);

=head1 ADDITIONAL MANUALS

=over

=item * L<Man parameters|MooX::Options::Manual::Man>

=item * L<Using namespace::clean|MooX::Options::Manual::NamespaceClean>

=item * L<Manage your tools with MooX::Cmd|MooX::Options::Manual::MooXCmd>

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
