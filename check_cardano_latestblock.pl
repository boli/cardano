#!/usr/bin/perl
use strict;
use warnings;
use LWP;
use LWP::Simple;

my $DEBUG;

#curl -s https://blockchair.com/cardano|grep "Latest block" -m1|sed 's/.*Latest/Latest/'|sed 's/<\/a>.*//'|sed 's/.*<.*>//'

my $url_blockchair='https://blockchair.com/cardano';
my $browser = LWP::UserAgent->new;
my $response_blockchair=$browser->get($url_blockchair);

die "Error at $url_blockchair\n ", $response_blockchair->status_line, "\n Aborting" unless $response_blockchair->is_success;

my $data_blockchair=$response_blockchair->content;
#$DEBUG && print $data_blockchair."\n";

#my $latest_blockchair=`curl -s https://blockchair.com/cardano|grep "Latest block" -m1|sed 's/.*Latest/Latest/'|sed 's/<\/a>.*//'|sed 's/.*<.*>//'`;
#print "Latest = $latest_blockchair\n";
$data_blockchair =~ /Latest block.*?(\d+)/s;

my $latest_blockchair =$1;
$DEBUG && print $latest_blockchair."\n";

my $metricsurl="http://127.0.0.1:12798/metrics";
my $warn = 30;
my $crit = 50;

my $metricsdata = get($metricsurl);

my %metric;

#Read all those metrics into a hash

my @lines = split /\n/,$metricsdata;

foreach my $line (@lines) {
	my ($key, $value)  = split(' ', $line);
	$metric{$key}=$value;
}

my $localblock=$metric{'cardano_node_metrics_blockNum_int'} || 0;

my $blockdiff = abs($latest_blockchair - $localblock);
my $message = "UNKNOWN : NFI $localblock $latest_blockchair";
my $exitcode = 2;

if ( $DEBUG ) {
#	print $metricsdata;
	print "blockdiff = $blockdiff\n";
  print "latest_blockchair = $latest_blockchair\n";
  print "localblock = $localblock\n";
};

if ( $blockdiff > $crit ) {
	$message="CRITICAL - HERE $localblock THERE $latest_blockchair ( $blockdiff > $crit )";
	$exitcode=2;
} elsif ( $blockdiff > $warn ) {
        $message = "WARNING - HERE $localblock THERE $latest_blockchair ( $crit > $blockdiff > $warn )";
        $exitcode = 1;
} elsif ( $blockdiff < $warn ) {
	$message="OK - HERE $localblock THERE $latest_blockchair ( $blockdiff < $warn )";
	$exitcode=0;
} else {
	$message = "UNKNOWN - NFI";
	$exitcode = 3;
}

print $message;
exit $exitcode;

