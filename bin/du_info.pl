#!/usr/bin/perl
use warnings;
use strict;
use Parallel::ForkManager;

my $pm = Parallel::ForkManager->new('6');
my $mail = $ARGV[0] or die "Please add email\n";

my $host = `hostname`;
chomp($host);
my @diskSpace = `df -h |column -t`;

my ( @warn, @drive );
foreach my $df (@diskSpace) {
    chomp $df;

    next if $df =~ /^Filesystem|^pathway|^bdarchive|^crosman|^archive/;
    $df =~ s/\s+/:/g;

    my @results = split ":", $df;
    $results[4] =~ s/\%$//g;

    next unless ( int $results[4] );

    if ( $results[4] >= 85 ) {
        push @warn,  $results[0];
        push @drive, $results[-1];
    }
}

if (@warn) {

    my $count;
    my @du_collect;
    foreach my $drive (@drive) {

        if ( $drive =~ /\/$/ ) {
            $drive =~ s/\//\/home/;
        }

        my $du_file = "du_sort_" . ++$count;
        my $cmd     = "du $drive |sort -rn |head -50 > $du_file";
        push @du_collect, $du_file;
        $pm->start and next;
        `$cmd`;
        $pm->finish;
    }
    $pm->wait_all_children;

    foreach my $dirs (@du_collect) {
        chomp $dirs;
        system("mail -s \"du_info from: $host the following drives are > 85% full\" $mail < $dirs");
        sleep(60);
    }
    `rm du_sort_*`;
}

