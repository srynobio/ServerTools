#!/usr/bin/perl
use strict;
use warnings;
use IO::File;
use Storable;

my $mail = $ARGV[0];
my $host = `hostname`;

my $pros = `grep pro /proc/cpuinfo -c`;
$pros =~ s/\n//g;

my $loadavg = `cat /proc/loadavg`;
my @av = split /\s+/, $loadavg;

if ( $pros < $av[0] ) {
    my @list = `ps -eo pid,pcpu,user,args --sort pcpu`;

    if ( -e 'highCPU.store' ) {

        my $highcpu = retrieve('highCPU.store');

        foreach my $over ( keys %{$highcpu} ) {
            chomp $over;
            `kill -9 $over`;
        }
        `rm highCPU.store`;
        exit(0);
    }

    my %overload;
    foreach my $jobs (@list) {
        chomp $jobs;
        $jobs =~ s/^\s+//g;
        next if ( $jobs =~ /PID/ );

        my @groups = split / /, $jobs;
	next if ( $groups[3] eq 'root');

        next unless $groups[1] > 300;

        $overload{ $groups[0] } = $jobs;
    }
    my @pids = keys %overload;

    store \%overload, 'highCPU.store';

    my $OUT = IO::File->new( 'WARNfile', 'a+' ) or die;
    my $comment = "Due to high CPU load the following jobs will be KILLED in one hour if left in current state\n\n";
    print $OUT $comment;

    foreach my $over ( keys %overload ) {
        chomp $over;
        map { print $OUT $_, "\n" } $overload{$over};
    }

    print $OUT "\n\n";
    while (<DATA>) {
        print $OUT $_;
    }

    system("mail -s \"CPU load is critical and above capacity for the following jobs on $host\" $mail < WARNfile");
    `rm WARNfile`;
}

__DATA__
On Her Majesty's Secret Service

Draco: My apologies for the way you were brought here. I wasn't sure you'd accept a formal invitation.
Bond:  There's always something formal about the point of a pistol.
