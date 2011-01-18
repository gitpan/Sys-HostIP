
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Try extra hard to get ip address related info',
  'AUTHOR' => 'Sawyer X <xsawyerx@cpan.org>, Jonathan Schatz <jon@divisionbyzero.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::TinyMocker' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Sys-HostIP',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Sys::HostIP',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'vars' => '0'
  },
  'VERSION' => '1.8',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



