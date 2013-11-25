
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Options eXtension for Object Class",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "MooX-Options",
  "dist_version" => "4.000",
  "license" => "perl",
  "module_name" => "MooX::Options",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Record" => 0,
    "Getopt::Long" => "2.38",
    "Getopt::Long::Descriptive" => "0.091",
    "JSON" => 0,
    "MRO::Compat" => 0,
    "Module::Metadata" => "1.000019",
    "Moo" => "1.003001",
    "MooX::ConfigFromFile" => 0,
    "Path::Class" => "0.32",
    "Pod::Usage" => 0,
    "Regexp::Common" => 0,
    "Scalar::Util" => 0,
    "Term::Size::Any" => 0,
    "Text::WrapI18N" => 0,
    "feature" => 0,
    "overload" => 0,
    "parent" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "English" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Moo" => "1.003001",
    "Role::Tiny::With" => 0,
    "Test::More" => "0.94",
    "Test::Requires" => 0,
    "Test::Trap" => 0,
    "Try::Tiny" => 0,
    "lib" => 0,
    "namespace::clean" => 0,
    "perl" => "5.010"
  }
);


my %fallback_build_requires = (
  "Capture::Tiny" => 0,
  "English" => 0,
  "File::Spec" => 0,
  "FindBin" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Moo" => "1.003001",
  "Role::Tiny::With" => 0,
  "Test::More" => "0.94",
  "Test::Requires" => 0,
  "Test::Trap" => 0,
  "Try::Tiny" => 0,
  "lib" => 0,
  "namespace::clean" => 0,
  "perl" => "5.010"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
