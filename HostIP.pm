package Sys::HostIP;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Sys::Hostname;
use vars qw($VERSION);
$VERSION = 1.1;

{
  #cache value, except when a new value is specified
  my $ifconfig;
  
  sub ifconfig {
    my ($class, $new_ifconfig) = @_;
    if (defined $new_ifconfig) {
      $ifconfig = $new_ifconfig;
    } elsif (defined $ifconfig) {
      # do nothing, since we're keeping the cached value
    } elsif ( $^O eq ('linux' || 'openbsd' || 'freebsd' || 'netbsd' || 'solaris' || 'darwin')) {
      $ifconfig =  '/sbin/ifconfig';
    } elsif  ($^O eq 'irix') {
      $ifconfig = '/usr/etc/ifconfig';
    } else {
      carp "Unknown system, guessing ifconfig lives in /sbin/ifconfig";
      $ifconfig = '/sbin/ifconfig';
    }
    return $ifconfig;
  }
}

sub ip {
  my ($class) = @_;
  return $class->_get_interface_info(mode => 'ip');
}

sub ips {
  my ($class) = @_;
  return $class->_get_interface_info(mode => 'ips');
}

sub interfaces {
  my ($class) = @_;
  return $class->_get_interface_info(mode => 'interfaces');
}

sub _get_interface_info {
  my ($class, %params) = @_;
  if ($^O eq 'MSWin32') {
    #this will change once i can get a win32 machine to fix this code. right
    #now, none of the modes work in win32. we just return the (hopefully)
    #main ip address. anyone want to work on this?
    return $class->_get_win32_inferface_info();
  } else {
    my $if_info = $class->_get_unix_interface_info();
    if ($params{mode} eq 'interfaces') {
      return $if_info;
    } elsif ( $params{mode} eq 'ips') {
      return [values %$if_info];
    } elsif ( $params{mode} eq 'ip') {
      foreach my $key (sort keys %$if_info) {
	#we don't want the loopback
	next if ($if_info->{$key} eq '127.0.0.1');
	#now we return the first one that comes up
	return ($if_info->{$key});
      }
      #we get here if loopback is the only active device
      return "127.0.0.1";
    }
  }
}

sub _get_unix_interface_info {
  my ($class) = @_;
  my %if_info;
  my ($ip, $interface) = undef;
  #this is an attempt to fix tainting problems
  local %ENV;
  # $BASH_ENV must be unset to pass tainting problems if your system uses
  # bash as /bin/sh
  if ($ENV{'BASH_ENV'}) {
    $ENV{'BASH_ENV'} = undef;
  }
  #now we set the local $ENV{'PATH'} to be only the path to ifconfig
  #  my $newpath = $ifconfigLocation{$^O};
  my ($newpath)  = ( $class->ifconfig =~/(\/\w+)$/) ;
  $ENV{'PATH'} = $newpath;
  my $ifconfig = $class->ifconfig;
  my @ifconfig = `$ifconfig`;
  foreach my $line (@ifconfig) {
    #output from 'ifconfig -a' looks something like this on every *nix i
    #could get my hand on except linux (this one's actually from OpenBSD):
    #
    #gershiwin:~# /sbin/ifconfig -a
    #lo0: flags=8009<UP,LOOPBACK,MULTICAST>
    #        inet 127.0.0.1 netmask 0xff000000 
    #lo1: flags=8008<LOOPBACK,MULTICAST>
    #xl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
    #        media: Ethernet autoselect (100baseTX full-duplex)
    #        status: active
    #        inet 10.0.0.2 netmask 0xfffffff0 broadcast 10.0.0.255
    #sl0: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #sl1: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #
    #in linux it's a little bit different:
    #
    #[jschatz@nooky Sys-IP]$ /sbin/ifconfig 
    # eth0      Link encap:Ethernet  HWaddr 00:C0:4F:60:6F:C2  
    #          inet addr:10.0.3.82  Bcast:10.0.255.255  Mask:255.255.0.0
    #          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
    #          Interrupt:19 Base address:0xec00 
    # lo        Link encap:Local Loopback  
    #          inet addr:127.0.0.1  Mask:255.0.0.0
    #          UP LOOPBACK RUNNING  MTU:3924  Metric:1
    #
    # so the regexen involved here have to deal with the following: 1)
    # there's no ':' after an interface's name in linux 2) in linux, it's
    # "inet addr:127.0.0.1" instead of "inet 127.0.0.1" hence the somewhat
    # hairy regexen /(^\w+(?:\d)?(?:\:\d)?)/ (which also handles aliased ip
    # addresses , ie eth0:1) and /inet(?:addr\:)?(\d+\.\d+\.\d+\.\d+)/
    #
    #so we parse through the list returned. if the line starts with some
    #letters followed (possibly) by an number and a colon, then we've got an
    #interface. if the line starts with a space, then it's the info from the
    #interface that we just found, and we stick the contents into %if_info
    if ( ($line =~/^\s+/) && ($interface) ) {
      $if_info{$interface} .= $line;
    }
    elsif (($interface) = ($line =~/(^\w+(?:\d)?(?:\:\d)?)/)) {
      $line =~s/\w+\d(\:)?\s+//;
      $if_info{$interface} = $line;
    }
  }
    foreach my $key (keys %if_info) {
      #now we want to get rid of all the other crap in the ifconfig
      #output. we just want the ip address. perhaps a future version can
      #return even more useful results (netmask, etc).....
      if (my ($ip) = ($if_info{$key} =~/inet (?:addr\:)?(\d+\.\d+\.\d+\.\d+)/)) {
	$if_info{$key} = $ip;
      }
      else {
	#ok, no ip address here, which means this interface isn't
	#active. some os's (openbsd for instance) spit out ifconfig info for
	#inactive devices. this is pretty much worthless for us, so we
	#delete it from the hash
	delete $if_info{$key};
      }
    }
  #now we do some cleanup by deleting keys that have no associated info
  #(some os's like openbsd list inactive interfaces when 'ifconfig -a' is
  #used, and we don't care about those
  return \%if_info;
} 
sub _get_win32_interface_info {
  #this is shamefully stolen from the original Sys::HostIP. I've got to find
  # a win32 machine to test and clean this up on, but for the time being
  # we'll just use it (since i assume it works already).
  #
  #begin code that i didn't write:
  #
  #check ipconfig.exe (Whichdoes all the work of checking the registry,
  #probably more efficiently than I could.)
  my $nocannon= (split /\./, (my $cannon = hostname))[0];
  my $ip;
  return $ip= $1 if `ipconfig`=~ /(\d+\.\d+\.\d+\.\d+)/;
  
  # check nbtstat.exe 
  # (Which does all the work of checking WINS,
  # more easily than Win32::AdminMisc::GetHostAddress().)
  return $ip= $1 if `nbtstat -a $nocannon`=~ /(\d+\.\d+\.\d+\.\d+)/;
  
  # check /etc/hosts entries 
  if(open HOST, "<$ENV{SystemRoot}\\System32\\drivers\\etc\\hosts")
    {
      while(<HOST>)
	{
	  last if /\b$cannon\b/i and /(\d+\.\d+\.\d+\.\d+)/ and $ip= $1;
	}
      close HOST;
      return $ip if $ip;
    }
  
  # check /etc/lmhosts entries 
  # (It will only be here if the file has been modified since the
  # last WINS refresh, which is unlikely, but might as well try.)
  if(open HOST, "<$ENV{SystemRoot}\\System32\\drivers\\etc\\lmhosts")
    {
      while(<HOST>)
	{
	  last if /\b$nocannon\b/i and /(\d+\.\d+\.\d+\.\d+)/ and $ip= $1;
	}
      close HOST;
      return $ip if $ip;
    }
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Sys::HostIP - Try extra hard to get ip address related info

=head1 SYNOPSIS

  use Sys::HostIP; 
  
  my $ip_address = Sys::HostIP->ip; 
  # $ip_address is a scalar containing a best guess of your host machines ip
  # address. It will return loopback (127.0.0.1) if it can't find anything else.

  my $ip_addresses = Sys::HostIP->ips; 
  # $ip_addresses is an array ref containing all the ip addresses of your
  # machine 

  my $interfaces = Sys::HostIP->interfaces;
  # $interfaces is a hash ref containg all pairs of interfaces/ip addresses
  # Sys::HostIP could find on your machine.

=head1 DESCRIPTION

Sys::HostIP does what it can to determine the ip address of your
machine. All 3 methods work fine on every *nix that I've been able to
test on. (Irix, OpenBSD, FreeBSD, NetBSD, Solaris, Linux, OSX)
Unfortunately, I have no access to a Win32 machine, so this code is leftover
from the old (1.0) version of this code (which i did not write) and thus,
only the ip() method is trully implemented (*hint* patches are welcome).

=head2 EXPORT

Nothing, because I wrote this as a class. Classes are so much easier on the
eyes when reading other's code, don't you think?

=head1 AUTHOR

Jonathan Schatz <bluelines@divisionbyzero.com>

=head1 TODO

Rewrite this via XS and ifaddrlist from Net::RawIP (although this will ruin
portability to non-*nix systems).

=head1 SEE ALSO

ifconfig(8)

L<perl>.

=cut
