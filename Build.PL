
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Try extra hard to get IP address related info",
  "dist_author" => [
    "Sawyer X <xsawyerx\@cpan.org>",
    "Jonathan Schatz <jon\@divisionbyzero.com>"
  ],
  "dist_name" => "Sys-HostIP",
  "dist_version" => "1.95",
  "license" => "perl",
  "module_name" => "Sys::HostIP",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
