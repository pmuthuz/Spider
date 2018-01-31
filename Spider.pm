package Spider;

use strict;
use warnings;

use WWW::Mechanize;
use WWW::Mechanize::Frames;
use URI::URL;
use Data::Validate::URI qw(is_uri is_https_uri is_http_uri);
use Domain::PublicSuffix qw( );
use Spider::ScanLink;
use Spider::SeedSites;
use Config::Tiny;
use Spider::FoundSites;
use Digest::MD5 qw(md5_hex);
use POSIX qw (strftime);

sub new {
    my ($class, $url, $depth, $url_id, $url_name) = @_;

    my $self = {
      url => $url,
      depth => $depth,
      url_id => $url_id,
      url_name => $url_name,
      links => {},
      sites => {},
    };

    my $config = Config::Tiny->read('./spider.conf');
    $self->{config} = $config;

    return bless $self, $class;

}

=head2 Spider::get_links

This method crawls a web page and get all the unique links the page

=cut

sub get_links {
    my $self = shift;
    my $mech = WWW::Mechanize::Frames->new();
    my $response;
    $self->debug_log("Crawling the URL - " . $self->{url} ." at " . strftime("%d %m %Y %H:%M:%S", localtime(time)));
    eval { $response = $mech->get($self->{url}) };
    if ($@) {
         $self->{error} = $@;
         $self->error_log($@, $self->{url});
    }
    my @links = $mech->find_all_links;

    my $uniq_links = {};
    foreach my $link ( @links ) {
        my $uri = $link->url_abs;
        $uri = "$uri";
        next if !($self->valid_uri($uri));
        $uniq_links->{$uri} = $self->{depth};
    }
    $self->{links} = $uniq_links;
    return $self->{links};
}

=head2 Spider::debug_log

This method adds debug information into log file

=cut

sub debug_log {
    my ($self, $msg) = @_;
    open(my $fh, ">>", $self->{config}->{log}{scanlog})
	or die "Can't open $self->{config}->{log}{scanlog} $!";

    print $fh $msg, "\n";
    close $fh;
    return;
}

=head2 Spider::error_log

This method adds errors into log file

=cut

sub error_log {
    my ($self, $url, $error) = @_;

    open(my $fh, ">>", $self->{config}->{log}{errorlog})
	or die "Can't open $self->{config}->{log}{errorlog} $!";

    print $fh "Error while crawling $url ", $error;
    close $fh;
    return;
}

=head2 Spider::get_sites

This method crawls a web page and gets all the unique links / external URLs in the page

=cut

sub get_sites {
    my $self = shift;
    my $sites = {};

    $self->get_links unless ( keys %{$self->{links}} );

    my $other_tld = $self->{exclude_tld};

    foreach my $link ( keys %{$self->{links}} ) {
         print $link, "\n";
         my $uri = URI::URL->new($link);
         my $suffix = Domain::PublicSuffix->new();
         my $root_domain = $suffix->get_root_domain($uri->host);
         my $tld = $suffix->tld;
         
         if ( ( defined $root_domain) && ( defined $tld ) && (  not exists $other_tld->{$tld} )) {
             $sites->{$root_domain} = 1;
         } 
    }
    $self->{sites} = $sites;
}

=head2 Spider::save

This method saves the links and sites into DB

=cut

sub save {
    my $self = shift;

    #my $client= new Gearman::Client;
    #$client->job_servers('localhost:4730');
    
    foreach my $link ( keys %{$self->{links}} ) {
        my ($exists) = Spider::ScanLink->search( uri_md5 => md5_hex($link) );
        next if $exists;
        Spider::ScanLink->find_or_create({ uri => $link, depth_level => $self->{depth}+1, url_id => $self->{url_id}  });
    }

    foreach my $site ( keys %{$self->{sites}} ) {
         my ($exists) = Spider::FoundSites->search(url_md5 => md5_hex($site));
         next if $exists;
         my $site = Spider::FoundSites->find_or_create( { url => $site, seed_id => $self->{url_id} } );
         #$client->dispatch_background('scan_deep_links', $site->id);
    }
    return 1;
}

=head2 Spider::valid_uri

This method validates a URI

=cut

sub valid_uri {
    my $self = shift;
    my $uri = shift;
    
    return 0 if ($uri =~ /^javascript:/ );
    return 1 if ( ( (is_http_uri($uri)) || (is_https_uri($uri))) && ( _valid_content_type($uri) ) );
        
    return 0;
}

=head2 Spider::exclude_tld

This method validates TLD. It is not used

=cut
sub exclude_tld {
    my $self = shift;

    my $other_tld = {
'.af'=>'Afghanistan',
'.ax'=>'Aland',
'.al'=>'Albania',
'.dz'=>'Algeria',
'.as'=>'American Samoa',
'.ad'=>'Andorra',
'.ao'=>'Angola',
'.ai'=>'Anguilla',
'.aq'=>'Antarctica',
'.ag'=>'Antigua and Barbuda',
'.ar'=>'Argentina',
'.am'=>'Armenia',
'.aw'=>'Aruba',
'.ac'=>'Ascension Island',
'.au'=>'Australia',
'.at'=>'Austria',
'.az'=>'Azerbaijan',
'.bs'=>'Bahamas',
'.bh'=>'Bahrain',
'.bd'=>'Bangladesh',
'.bb'=>'Barbados',
'.eus'=>'Basque Country',
'.by'=>'Belarus',
'.be'=>'Belgium',
'.bz'=>'Belize',
'.bj'=>'Benin',
'.bm'=>'Bermuda',
'.bt'=>'Bhutan',
'.bo'=>'Bolivia',
'.bq'=>'Bonaire',
'.ba'=>'Bosnia and Herzegovina',
'.bw'=>'Botswana',
'.bv'=>'Bouvet Island',
'.br'=>'Brazil',
'.io'=>'British Indian Ocean Territory',
'.vg'=>'British Virgin Islands',
'.bn'=>'Brunei',
'.bg'=>'Bulgaria',
'.bf'=>'Burkina Faso',
'.mm'=>'Burma (officially: Myanmar)',
'.bi'=>'Burundi',
'.kh'=>'Cambodia',
'.cm'=>'Cameroon',
'.ca'=>'Canada',
'.cv'=>'Cape Verde',
'.cat'=>'Catalonia',
'.ky'=>'Cayman Islands',
'.cf'=>'Central African Republic',
'.td'=>'Chad',
'.cl'=>'Chile',
'.cn'=>'China, Peopleâ€™s Republic of',
'.cx'=>'Christmas Island',
'.cc'=>'Cocos (Keeling) Islands',
'.co'=>'Colombia',
'.km'=>'Comoros',
'.cd'=>'Congo, Democratic Republic of the (Congo-Kinshasa)',
'.cg'=>'Congo, Republic of the (Congo-Brazzaville)',
'.ck'=>'Cook Islands',
'.cr'=>'Costa Rica',
'.ci'=>'CÃ´te dâ€™Ivoire (Ivory Coast)',
'.hr'=>'Croatia',
'.cu'=>'Cuba',
'.cw'=>'CuraÃ§ao',
'.cy'=>'Cyprus',
'.cz'=>'Czech Republic',
'.dk'=>'Denmark',
'.dj'=>'Djibouti',
'.dm'=>'Dominica',
'.do'=>'Dominican Republic',
'.tl'=>'East Timor (Timor-Leste)',
'.ec'=>'Ecuador',
'.eg'=>'Egypt',
'.sv'=>'El Salvador',
'.gq'=>'Equatorial Guinea',
'.er'=>'Eritrea',
'.ee'=>'Estonia',
'.et'=>'Ethiopia',
'.eu'=>'European Union',
'.fk'=>'Falkland Islands',
'.fo'=>'Faeroe Islands',
'.fm'=>'Federated States of Micronesia',
'.fj'=>'Fiji',
'.fi'=>'Finland',
'.fr'=>'France',
'.gf'=>'French Guiana',
'.pf'=>'French Polynesia',
'.tf'=>'French Southern and Antarctic Lands',
'.ga'=>'Gabon (officially: Gabonese Republic)',
'.gal'=>'Galicia',
'.gm'=>'Gambia',
'.ps'=>'Gaza Strip (Gaza)',
'.ge'=>'Georgia',
'.de'=>'Germany',
'.gh'=>'Ghana',
'.gi'=>'Gibraltar',
'.gr'=>'Greece',
'.gl'=>'Greenland',
'.gd'=>'Grenada',
'.gp'=>'Guadeloupe',
'.gu'=>'Guam',
'.gt'=>'Guatemala',
'.gg'=>'Guernsey',
'.gn'=>'Guinea',
'.gw'=>'Guinea-Bissau',
'.gy'=>'Guyana',
'.ht'=>'Haiti',
'.hm'=>'Heard Island and McDonald Islands',
'.hn'=>'Honduras',
'.hk'=>'Hong Kong',
'.hu'=>'Hungary',
'.is'=>'Iceland',
'.in'=>'India',
'.id'=>'Indonesia',
'.ir'=>'Iran',
'.iq'=>'Iraq',
'.ie'=>'Ireland',
'.im'=>'Isle of Man',
'.il'=>'Israel',
'.it'=>'Italy',
'.jm'=>'Jamaica',
'.jp'=>'Japan',
'.je'=>'Jersey',
'.jo'=>'Jordan',
'.kz'=>'Kazakhstan',
'.ke'=>'Kenya',
'.ki'=>'Kiribati',
'.kw'=>'Kuwait',
'.kg'=>'Kyrgyzstan',
'.la'=>'Laos',
'.lv'=>'Latvia',
'.lb'=>'Lebanon',
'.ls'=>'Lesotho',
'.lr'=>'Liberia',
'.ly'=>'Libya',
'.li'=>'Liechtenstein',
'.lt'=>'Lithuania',
'.lu'=>'Luxembourg',
'.mo'=>'Macau',
'.mk'=>'Macedonia, Republic of (the former Yugoslav Republic of Macedonia, FYROM)',
'.mg'=>'Madagascar',
'.mw'=>'Malawi',
'.my'=>'Malaysia',
'.mv'=>'Maldives',
'.ml'=>'Mali',
'.mt'=>'Malta',
'.mh'=>'Marshall Islands',
'.mq'=>'Martinique',
'.mr'=>'Mauritania',
'.mu'=>'Mauritius',
'.yt'=>'Mayotte',
'.mx'=>'Mexico',
'.md'=>'Moldova',
'.mc'=>'Monaco',
'.mn'=>'Mongolia',
'.me'=>'Montenegro',
'.ms'=>'Montserrat',
'.ma'=>'Morocco',
'.mz'=>'Mozambique',
'.mm'=>'Myanmar',
'.na'=>'Namibia',
'.nr'=>'Nauru',
'.np'=>'Nepal',
'.nl'=>'Netherlands',
'.nc'=>'New Caledonia',
'.nz'=>'New Zealand',
'.ni'=>'Nicaragua',
'.ne'=>'Niger',
'.ng'=>'Nigeria',
'.nu'=>'Niue',
'.nf'=>'Norfolk Island',
'.nc.tr'=>'North Cyprus (unrecognised, self-declared state)',
'.kp'=>'North Korea',
'.mp'=>'Northern Mariana Islands',
'.no'=>'Norway',
'.om'=>'Oman',
'.pk'=>'Pakistan',
'.pw'=>'Palau',
'.ps'=>'Palestine',
'.pa'=>'Panama',
'.pg'=>'Papua New Guinea',
'.py'=>'Paraguay',
'.pe'=>'Peru',
'.ph'=>'Philippines',
'.pn'=>'Pitcairn Islands',
'.pl'=>'Poland',
'.pt'=>'Portugal',
'.pr'=>'Puerto Rico',
'.qa'=>'Qatar',
'.ro'=>'Romania',
'.ru'=>'Russia',
'.rw'=>'Rwanda',
'.re'=>'RÃ©union Island',
'.bq'=>'Saba',
'.bl'=>'Saint BarthÃ©lemy (informally also referred to as Saint Barthâ€™s or Saint Barts)',
'.sh'=>'Saint Helena',
'.kn'=>'Saint Kitts and Nevis',
'.lc'=>'Saint Lucia',
'.mf'=>'Saint Martin (officially the Collectivity of Saint Martin)',
'.pm'=>'Saint-Pierre and Miquelon',
'.vc'=>'Saint Vincent and the Grenadines',
'.ws'=>'Samoa',
'.sm'=>'San Marino',
'.st'=>'SÃ£o TomÃ© and PrÃ­ncipe',
'.sa'=>'Saudi Arabia',
'.sn'=>'Senegal',
'.rs'=>'Serbia',
'.sc'=>'Seychelles',
'.sl'=>'Sierra Leone',
'.sg'=>'Singapore',
'.bq'=>'Sint Eustatius',
'.sx'=>'Sint Maarten',
'.sk'=>'Slovakia',
'.si'=>'Slovenia',
'.sb'=>'Solomon Islands',
'.so'=>'Somalia',
'.so'=>'Somaliland',
'.za'=>'South Africa',
'.gs'=>'South Georgia and the South Sandwich Islands',
'.kr'=>'South Korea',
'.ss'=>'South Sudan',
'.es'=>'Spain',
'.lk'=>'Sri Lanka',
'.sd'=>'Sudan',
'.sr'=>'Suriname',
'.sj'=>'Svalbard and Jan Mayen Islands',
'.sz'=>'Swaziland',
'.se'=>'Sweden',
'.ch'=>'Switzerland',
'.sy'=>'Syria',
'.tw'=>'Taiwan',
'.tj'=>'Tajikistan',
'.tz'=>'Tanzania',
'.th'=>'Thailand',
'.tg'=>'Togo',
'.tk'=>'Tokelau',
'.to'=>'Tonga',
'.tt'=>'Trinidad & Tobago',
'.tn'=>'Tunisia',
'.tr'=>'Turkey',
'.tm'=>'Turkmenistan',
'.tc'=>'Turks and Caicos Islands',
'.tv'=>'Tuvalu',
'.ug'=>'Uganda',
'.ua'=>'Ukraine',
'.ae'=>'United Arab Emirates (UAE)',
'.uk'=>'United Kingdom (UK)',
'.vi'=>'United States Virgin Islands',
'.uy'=>'Uruguay',
'.uz'=>'Uzbekistan',
'.vu'=>'Vanuatu',
'.va'=>'Vatican City',
'.ve'=>'Venezuela',
'.vn'=>'Vietnam',
'.wf'=>'Wallis and Futuna',
'.eh'=>'Western Sahara',
'.ye'=>'Yemen',
'.zm'=>'Zambia',
'.zw'=>'Zimbabwe',
    };

    return $other_tld;

}

=head2 Spider::exclude_tld

This method checks if the content type is html

=cut
sub _valid_content_type {
    my $url = shift;

    my $cmech = WWW::Mechanize::Frames->new;
    $cmech->get($url);
    my $ct = $cmech->content_type();
    if ($ct =~ /text\/html/ ) {
         return 1;
    }
    else {
         return 0;
    }

}

1;
