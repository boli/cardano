#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;

my $DEBUG;

my $metricsurl="http://127.0.0.1:12798/metrics";
my $warn = 7;
my $crit = 2;

my $metricsdata = get($metricsurl);

my %metric;

#Read all those metrics into a hash

my @lines = split /\n/,$metricsdata;

foreach my $line (@lines) {
	my ($key, $value)  = split(' ', $line);
	$metric{$key}=$value;
}

my $ocskp=$metric{'cardano_node_metrics_operationalCertificateStartKESPeriod_int'} || 0;
my $ocekp=$metric{'cardano_node_metrics_operationalCertificateExpiryKESPeriod_int'} || 0;
my $ckp=$metric{'cardano_node_metrics_currentKESPeriod_int'} || 0;

if ( $DEBUG ) {
	print $metricsdata;
	print "start = $ocskp\n";
	print "end = $ocekp\n";
	print "now = $ckp\n";
};

my $message = "UNKNOWN : NFI $ocskp $ocekp $ckp";
my $exitcode = 2;

if ( $ckp < $ocskp ) {
	$message="CRITICAL - OPCert Not Yet Valid";
	$exitcode=2;
} elsif ( $ckp > $ocekp ) {
	$message="CRITICAL - OPCert Has Expired ( $ckp > $ocekp )";
	$exitcode=2;
} elsif ( ( $ocekp - $ckp ) < $crit ) {
        $message = "CRITICAL - Certificate Expires Imminently ( $ckp < $ocekp )";
        $exitcode = 1;
} elsif ( ( $ocekp - $ckp ) < $warn ) {
	$message = "WARNING - Certificate Expires Soon ( $ckp < $ocekp )";
	$exitcode = 1;
} elsif ( ( $ckp > $ocskp ) && ( $ckp < $ocekp ) ) {
	$message="OK - Certificate is OK ( $ckp < $ocekp )";
	$exitcode=0;
} else {
	$message = "UNKNOWN - NFI";
	$exitcode = 3;
}

print $message;
exit $exitcode;

