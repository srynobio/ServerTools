#!/usr/bin/perl
use strict;
use warnings;

my $mail = $ARGV[0];
my $host = `hostname`;

my $pros = `grep pro /proc/cpuinfo -c`;
$pros =~ s/\n//g;

my $loadavg = `cat /proc/loadavg`;
my @av = split /\s+/, $loadavg;

if ( $pros < $av[0] ) {
	system("ps -eo pcpu,args | sort -k 1 -r | head -15 > highCPU");
	system("mail -s \"CPU load is critical and above capacity for the following jobs on $host\" $mail < highCPU");
}


