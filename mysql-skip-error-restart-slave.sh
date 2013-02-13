#!/usr/bin/perl -w
# Copyright 2006 Matthew Shields matt@mattshields.org

$ENV{PATH} = "/bin:/usr/bin";

$mysql = "/usr/bin/mysql";

$status = "$mysql -e 'SHOW SLAVE STATUS\\G'";
$reset  = "$mysql -e 'SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1\; START SLAVE\;'";

$query = "";

#
# Check the mysql slave status
#

if (checkstatus()) {
  
  # Execute the MySQL command to skip an error and resume the
  # replication process

  my @sysargs = ($reset);
  system(@sysargs) == 0 or die "SKIP failed $!\n";

  # If the script had to reset replication, then recheck the
  # status; if it's still not running, exit and ask for a human

  if (checkstatus()) {
    print "Something went wrong:\n";
    print " executed the skip but Slave_SQL_Running is still No\n";
    print " Query is:\n $query\n";
    exit 1;
    }
  else {
    print "MySQL replication was reset\n";
    print " Query was:\n $query\n";
    }
  }

exit 0;

#-------------------------------------------------------------------------------

sub checkstatus {
  my $line;
  my $flag = 0;

  open(STATUS, "$status |") or die "Can't get status $!\n";

  while ($line = <STATUS>) {
    chomp ($line);
    if ($line =~ /\s*?Slave_SQL_Running: Yes/) {
      last;
      }
    if ($line =~ /\s*?Last_Error: Error 'Duplicate entry/) {
      if ($line =~ /Default database: 'antraf'/) {
        if ($line =~ /Query: 'insert into AuctionDayStats/) {
	  $line =~ /Query:\s+(.*)/;
	  $query = $1;
	  $flag = 1;
	  last;
          }
        print "Duplicate entry but NOT into AuctionDayStats table\n";
        last;
        }
      print "Duplicate entry but NOT into \'antraf\' DB\n";
      last;
      }
    elsif ($line =~ /\s*?Last_Error:(.*)/) {
      print " *** DB Error is:\n$1\n";
      }
    }

  close(STATUS);
  return $flag;
  }

