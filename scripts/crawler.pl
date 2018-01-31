use strict;
use warnings;
use lib 'lib/share/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/lib/x86_64-linux-gnu/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/share/perl/5.22.1/';
use lib '/home/ubuntu/Spider/lib/lib/perl5/x86_64-linux-gnu-thread-multi/';
use Data::Dumper;
use Spider;
use Spider::SeedSites;
use Spider::ScanLink;
use Spider::Config;

my @seeds = Spider::SeedSites->search(checked => 'N');

foreach my $seed (@seeds) {
    my $spider = Spider->new($seed->url, 0, $seed->id);

    my @sites = $spider->get_sites;
    my $ret = $spider->save;
    $seed->checked('Y');
    $seed->update;
}

my ($config) = Spider::Config->search( option_name => 'depth_level');

for(my $level = 1; $level <= $config->option_value; $level++) {
    my @links = Spider::ScanLink->search(status => 'Not Scanned', depth_level => $level);

    foreach my $link (@links) {
         my $spider = Spider->new($link->uri, $link->depth_level, $link->url_id);
         $link->status('In Progress');
         $link->update;

         my @sites = $spider->get_sites;
         my $ret = $spider->save;
         $link->status('Scanned');
         $link->update;
    }
}


exit;
