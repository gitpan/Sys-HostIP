
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::TinyMocker' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Try extra hard to get ip address related info',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>',
    'Jonathan Schatz <jon@divisionbyzero.com>'
  ],
  'dist_name' => 'Sys-HostIP',
  'dist_version' => '1.8',
  'license' => 'perl',
  'module_name' => 'Sys::HostIP',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Exporter' => '0',
    'vars' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
