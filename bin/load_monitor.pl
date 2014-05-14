#!/usr/bin/env perl
use strict;
use warnings;
use IO::File;
use Carp;

my $mail = $ARGV[0];
my $host = `hostname`;

my $pros = `grep pro /proc/cpuinfo -c`;
$pros =~ s/\n//g;

my $loadavg = `cat /proc/loadavg`;
my @av = split /\s+/, $loadavg;

# This is for record keeping
record_average($loadavg);

if ( $pros < $av[0] ) {
    my @list = `ps -eo pid,pcpu,user,args --sort pcpu`;

    my @overload;
    foreach my $job (@list) {
        chomp $job;
        $job =~ s/^\s+//g;
        next if ( $job =~ /PID/ );

        my @groups = split / /, $job;
        next if ( $groups[3] eq 'root' );
        next if ( !$groups[1] or $groups[1] < 90 );

        push @overload, $job;
    }

    my $OUT = IO::File->new( 'WARNfile', 'a+' ) or die;
    my $comment =
      "Due to high CPU load average this WARNING email has been sent out.  Please review your server usage, "
      . "as it can affect job completion.\n\n\n";
    print $OUT $comment;
    map { print $OUT $_, "\n" } @overload;

    system(
      "mail -s \"CPU load is critical and above capacity on $host\" $mail < WARNfile"
    );
}

sub record_average {
    my $la = shift;
    chomp($la);
    $la =~ s/\s+/:/g;

    my @list = `ps -eo user`;
    chomp(@list);

    my %who;
    map { $who{$_}++ } @list;

    my $timestamp = localtime;
    $timestamp =~ s/\s+/-/g;

    my $FH = IO::File->new( 'average_recorder.txt', 'a+' )
      or croak "Can't open record_file\n";

    my $record = sprintf( "%s\t%s\t%s\n", $la, join( ":", keys %who ), $timestamp );
    print $FH $record;

    $FH->close;
    return;
}

