#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Net::SSH::Expect;

use Data::Dumper;

my $ssh = Net::SSH::Expect->new (
	host => 'ugp.genetics.utah.edu',
	password => '***************',
	user => 'srynearson',
	raw_pty => 1
);
croak "Unable to login.\n" unless $ssh->login();


my $ls = $ssh->exec("/Repository/testssh.pl");
print $ls, "\n";
