#!/usr/bin/perl

use warnings;
use strict;
use 5.008;
use Data::Dumper;
use POE qw(Component::Server::TCP Component::Client::HTTP);
use HTTP::Request;
use POSIX qw(setuid setgid);

# data is sent to $URL + carbon-ourname, you add slash
my $URL = 'https://someserver/endpoint/';
# put here echo -n username:password | openssl base64 -e
my $authz = 'Basic cGFzczp3b3Jk'; 

# drop privileges, change if necessary
setuid(65534);
setgid(65534);

my $clients = {};

POE::Component::Client::HTTP->spawn(
    Agent     => 'CarbonClient/1.0',   # defaults to something long
    Alias     => 'carbon',                  # defaults to 'weeble'
    Protocol  => 'HTTP/1.1',            # defaults to 'HTTP/1.1'
    Timeout   => 10,                    # defaults to 180 seconds
);

POE::Component::Server::TCP->new(
  Port => 2003,
  Address => '127.0.0.1',

  ClientConnected => sub {
    $clients->{$_[SESSION]->ID} = {};
    print time, ": Starting statistics send\n";
  },

  ClientInput => sub {
    my $input = $_[ARG0];
    chomp $input;
    if ($input=~/^(\S+) (\d+) (\d+)$/) {
      my $server=$1;
      $clients->{$_[SESSION]->ID}->{$1} = $2;
      $clients->{$_[SESSION]->ID}->{'stamp'} = $3;
      ($server) = ($server=~m/pdns\.([a-z0-9-]+)\./);
      $clients->{$_[SESSION]->ID}->{'server'} = $server;
    }
  },

  ClientDisconnected => sub {
    # create HTTP request
    my $par = "";
    my $server = delete $clients->{$_[SESSION]->ID}->{'server'};

    while(my ($key,$val) = each %{$clients->{$_[SESSION]->ID}}) {
      $par .= "$key=$val&";
    }
    chop $par;

    my $request = HTTP::Request->new('POST', "$URL$server");
    $request->authorization($authz);
    $request->accept_decodable;
    $request->content_type('application/x-www-form-urlencoded; charset=utf-8');
    $request->content($par);

    $poe_kernel->post(
        'carbon', 'request', 'response', $request
    );
  },

  InlineStates => {
    response => sub {
      my ($request_packet, $response_packet) = @_[ARG0, ARG1];
      if ($response_packet->[0]->code != 200) {
        print time,": Carbon gateway failed ",$request_packet->[0]->uri,": ", $response_packet->[0]->decoded_content,"\n";
      } else {
        print time,": Carbon data forwarded to ",$request_packet->[0]->uri,"\n";
      }
    }
  }
);

print time, ": Starting carbon gateway on port 127.0.0.1:2003\n";

POE::Kernel->run;
exit;
