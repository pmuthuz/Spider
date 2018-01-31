use strict;
use warnings;
use lib 'lib/share/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/lib/x86_64-linux-gnu/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/share/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/lib/perl5/x86_64-linux-gnu-thread-multi/';
use Data::Dumper;
use WWW::Mechanize::Frames;
use Domain::PublicSuffix;
use URI::URL;
use Spider;
use Spider::DBI;
use Spider::FoundSites;
use Spider::ScanLink;
use Spider::SeedSites;
use Spider::ExcludeCrawl;
use POSIX qw (strftime);

my @sites = Spider::FoundSites->search( status => 'Not Scanned');
foreach my $site (@sites) {
    debug_log("Get the info the site - " . $site->url ." at " . strftime("%d %m %Y %H:%M:%S", localtime(time)));
    my $ret = $site->scan;
}

sub debug_log {
    my ($self, $msg) = @_;
    open(my $fh, ">>", $self->{config}->{log}{foundsitelog})
        or die "Can't open $self->{config}->{log}{foundsitelog} $!";

    print $fh $msg, "\n";
    close $fh;
    return;
}
