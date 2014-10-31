#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Net::SSH::Expect;

use Data::Dumper;

my $ssh = Net::SSH::Expect->new (
	host => 'ugp.genetics.utah.edu',
	password => '*Gq~O$+F6\h3f)//uYnNz8gs(%8oc~#(Vi4do,6NIhHKQxlFUC@j{ER~.jU@MS1n8em:_T5$LGWRGX7}1<]ys,Oj>WYKqWan_zP_',
	user => 'srynearson',
	raw_pty => 1
);
croak "Unable to login.\n" unless $ssh->login();


my $ls = $ssh->exec("/Repository/testssh.pl");
print $ls, "\n";
