# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Sys::HostIP;
ok(1); # If we made it this far, we're ok.

#########################

{
  my $class = 'Sys::HostIP';
  my $ip = $class->ip; #the preferred way
  my $sub_ip = ip(); #the old way
  ok ($ip =~/^\d+\.\d+\.\d+\.\d+$/);
  ok ($ip eq $sub_ip);
  my $ips = $class->ips;
  ok (ref($ips) eq 'ARRAY');
  ok (1 == grep /^$ip$/, @$ips);
  ok (1 == grep /^127\.0\.0\.1$/, @$ips);
  my $interfaces = $class->interfaces;
  ok (ref($interfaces) eq 'HASH');
  ok (scalar (keys %$interfaces) == scalar (@$ips));
  ok (grep /^127\.0\.0\.1$/, values %$interfaces);
}
  
