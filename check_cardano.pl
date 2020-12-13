#!/usr/bin/perl
use strict;
use warnings;
use feature qw(switch say);
use LWP::Simple;

my $DEBUG;

my $metricsurl="http://127.0.0.1:12798/metrics";
my $warn = 20;

my $metricsdata = get($metricsurl);

my %metric;

#Read all those metrics into a hash

my @lines = split /\n/,$metricsdata;

foreach my $line (@lines) {
	my ($key, $value)  = split(' ', $line);
	$metric{$key}=$value;
}

my $ocskp=$metric{'cardano_node_Forge_metrics_operationalCertificateStartKESPeriod_int'} || 0;
my $ocekp=$metric{'cardano_node_Forge_metrics_operationalCertificateExpiryKESPeriod_int'} || 0;
my $ckp=$metric{'cardano_node_Forge_metrics_currentKESPeriod_int'} || 0;

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
	$message="CRITICAL - OPCert Has Expired";
	$exitcode=2;
} elsif ( ( $ocekp - $ckp ) < $warn ) {
	$message = "WARNING - Certificate Expires Soon";
	$exitcode = 1;
} elsif ( ( $ckp > $ocskp ) && ( $ckp < $ocekp ) ) {
	$message="OK - Certificate is OK";
	$exitcode=0;
} else {
	$message = "UNKNOWN - NFI";
	$exitcode = 3;
}


#given ($used_space) {
#    chomp($used_space);
#    when ($used_space lt '85%') { print "OK - $used_space of disk space used."; exit(0);      }
#    when ($used_space eq '85%') { print "WARNING - $used_space of disk space used."; exit(1);      }
#    when ($used_space gt '85%') { print "CRITICAL - $used_space of disk space used."; exit(2); }
#    default { print "UNKNOWN - $used_space of disk space used."; exit(3); }
#}

print $message;
exit $exitcode;
