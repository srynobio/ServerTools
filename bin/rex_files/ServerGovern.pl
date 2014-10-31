user 'srynearson';
password '********';
pass_auth;
sudo_password '*******';

# test status message
my $email = 'lab@yandell-lab.org';

group
  yandbeck => 'colt.genetics.utah.edu',
  'garrucha.genetics.utah.edu',
  'liberator.genetics.utah.edu',
  'remington.genetics.utah.edu',
  'ugp.genetics.utah.edu',
  'winchester.genetics.utah.edu',
  'hematite.genetics.utah.edu',
  'malachite.genetics.utah.edu',
  'browning.genetics.utah.edu',
  'newrepublic.genetics.utah.edu',
  'daisy.genetics.utah.edu',
  'crosman.genetics.utah.edu',
  'ithica.genetics.utah.edu',
  ;

group
  yandbeck_du => 'colt.genetics.utah.edu',
  'garrucha.genetics.utah.edu',
  'liberator.genetics.utah.edu',
  'remington.genetics.utah.edu',
  'winchester.genetics.utah.edu',
  'hematite.genetics.utah.edu',
  'malachite.genetics.utah.edu',
  'browning.genetics.utah.edu',
  'newrepublic.genetics.utah.edu',
  'daisy.genetics.utah.edu',
  'ithica.genetics.utah.edu',
  ;

##------------------------------------------------##
##------------------------------------------------##
##------------------------------------------------##

desc "Yandell/Eilbeck CPU load check.";
task 'cpu_load',
  group => "yandbeck",
  sub {

    my $host     = run 'hostname';
    my $output   = run "uptime";
    my $cpu_info = run "grep pro /proc/cpuinfo -c";
    my $loadavg  = run "cat /proc/loadavg";

    my $result = capacity_test( $cpu_info, $loadavg );

    if ( $result eq '1' ) {
        my @report;
        for my $process ( ps() ) {
            next unless ( $process->{cpu} > '50.0' );
            next if ( $process->{user} eq 'root' );

            push @report, $process;
        }
        load_email( $host, \@report,
            'high CPU load average for the following jobs' )
          if @report;
    }
  };

##------------------------------------------------##

desc "Yandell/Eilbeck Memory check";
task 'mem_load',
  group => "yandbeck",
  sub {
    my $host = run 'hostname';
    my $mem  = memory();

    my @report;
    if ( $mem->{free} eq '0' ) {
        push @report, $mem;
    }
    mem_email( $host, \@report,
        "Critical memory issue on $host please review swap and cached memory:" )
      if @report;
  };

##------------------------------------------------##

desc "Yandell/Eilbeck du check for above 85%.";
task 'du_info',
  group => "yandbeck_du",
  sub {
    my $host = run 'hostname';
    my @du   = run "df -h |column -t";

    my $over = du_test( \@du );

    my @report;
    foreach my $drv ( @{$over} ) {
        my @usage    = run "du -h $drv |sort -rn |head -50";
        my @top_uage = @usage[ 0 .. 20 ];
        foreach my $top (@top_uage) {
            next if ( $top =~ /Permission denied/ );
            push @report, $top;
        }
    }
    du_email( $host, \@report, 'Drive space above 85% for the following:' )
      if @report;
  };

##------------------------------------------------##

desc "Who's on all the servers now, and what are they running?";
task 'whos_on', group => "yandbeck",
sub {
	my $host = run 'sudo hostname';
	my $who_on = run 'w';

	print "HOST: $host\nWHO: $who_on\n\n";
};

##------------------------------------------------##

desc "Get the uptime of all server";
task "uptime",
  group => "yandbeck",
  sub {
    my $host = run 'hostname';
    my $output = run "uptime";
    print "HOST: $host\tUSAGE: $output\n";
  };

##------------------------------------------------##

desc "Preform a yum update on all the machines.";
task "yum_update",
	group => "yandbeck",
	sub {
		my $host = run 'hostname';
		my $update = run 'sudo yum -y update --skip-broken';
		#my $update = run 'sudo yum -y groupinfo';
		print "yum updated on $host: $update\n";
	};


##------------------------------------------------##

desc "Run a yum update on all the servers.";
task "update_system", 
	group => "yandbeck", 
	sub {
  		update_system;
};



##------------------------------------------------##
##------------------  SUBS -----------------------##
##------------------------------------------------##

sub capacity_test {
    my ( $cpu_info, $loadavg ) = @_;
    my @averages = split " ", $loadavg;

    my $over_cpacty = '0';
    foreach my $percent ( @averages[ 0 .. 2 ] ) {
        if ( $percent >= $cpu_info ) {
            $over_cpacty = '1';
        }
    }
    return $over_cpacty;
}

##------------------------------------------------##

sub du_test {
    my ($du) = @_;

    my @over;
    foreach my $rlt ( @{$du} ) {
        next if $rlt =~ /^Filesystem|^crosman/;

        $rlt =~ s/\s+/:/g;
        my @parts = split ":", $rlt;

        # skip some paths.
        next if ( $parts[5] =~ /dev/ );

        #get the value.
        $parts[4] =~ s/\%//g;

        if ( $parts[4] > '85' ) {
            push @over, $parts[5];
        }
    }
    return \@over;
}

##------------------------------------------------##
## Email subs
##------------------------------------------------##

sub load_email {
    my ( $host, $report, $message ) = @_;

    open( $FH, '+>', 'load.tmp' );

    foreach my $high ( @{$report} ) {
        print $FH $message, "\n\n";
        my $comment = sprintf( "USER: %s\tSTARTED: %s\tCOMMAND: %s\n",
            $high->{user}, $high->{start}, $high->{command}, );
        print $FH $comment;
    }
    close $FH;
    system("mail -s \"CPU load usage on $host\" $email < load.tmp");
    `rm load.tmp`;
}

##------------------------------------------------##

sub du_email {
    my ( $host, $report, $message ) = @_;

    open( $FH, '+>', 'du.tmp' );

    print $FH $message, "\n\n";
    foreach my $high ( @{$report} ) {
        print $FH $high, "\n";
    }
    close $FH;
    system("mail -s \"Disk usage on $host\" $email < du.tmp");
    `rm du.tmp`;
}

##------------------------------------------------##

sub mem_email {
    my ( $host, $report, $message ) = @_;

    open( $FH, '+>', 'mem.tmp' );

    print $FH $message, "\n\n";
    foreach my $high ( @{$report} ) {
        my $comment = sprintf( "FREE: %s\tUSED: %s\tCACHED: %s\n",
            $high->{free}, $high->{used}, $high->{cached}, );
        print $FH $comment, "\n";
    }
    close $FH;
    system("mail -s \"Memory usage on $host\" $email < mem.tmp");
    `rm mem.tmp`;
}

##------------------------------------------------##
