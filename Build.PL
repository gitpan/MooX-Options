
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "Test::Trap" => 0,
    "Try::Tiny" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "add option keywords to your Moo object",
  "dist_author" => [
    "Geistteufel <geistteufel\@celogeek.fr>"
  ],
  "dist_name" => "MooX-Options",
  "dist_version" => "1.3",
  "license" => "perl",
  "module_name" => "MooX::Options",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Data::Record" => 0,
    "Getopt::Long::Descriptive" => 0,
    "Regexp::Common" => 0,
    "perl" => "v5.8.9",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
