=head1 NAME

Sys::HostIP - Try really hard to get IP addr.

=head1 SYNOPSIS

  use Sys::HostIP;
  $ipaddr= hostip; # get (text) dotted-decimal ip 

=head1 AUTHOR

v, E<lt>v@rant.scriptmania.comE<gt>

=head1 SEE ALSO

perl(1), IO::Socket, Sys::Hostname, ping, ipconfig, nbtstat, /etc/hosts

=cut

package Sys::HostIP;
use IO::Socket;
use Sys::Hostname;
use vars qw($VERSION);
require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(hostip);

$VERSION= '1.0';

sub hostip()
{
  return $ip if $ip; # previously cached result 

  # Have to try non-cannonical name first, since there
  # is a better chance the computer knows itself than
  # of DNS knowing it.
  my $nocannon= (split /\./, (my $cannon= hostname))[0];
  $ip= (inet_aton($nocannon) or inet_aton($cannon));

  # successful Socket lookup! 
  return $ip= inet_ntoa($ip) if $ip;

  if($^O eq 'MSWin32')
  {
    # check ipconfig.exe 
    # (Which does all the work of checking the registry,
    # probably more efficiently than I could.)
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
  elsif($^O=~ /IX|ux/i)
  {
    # check /etc/hosts entries 
    if(open HOST, "</etc/hosts")
    {
      while(<HOST>)
      {
        last if /\b$nocannon\b/i and /(\d+\.\d+\.\d+\.\d+)/ and $ip= $1;
      }
      close HOST;
      return $ip if $ip;
    }
  }

  # last resort: ping (which can be very slow) 
  return $ip= $1 if `ping $nocannon`=~ /(\d+\.\d+\.\d+\.\d+)/;
  return $ip= $1 if `ping $cannon`=~ /(\d+\.\d+\.\d+\.\d+)/;

  return undef; # give up 
}

1