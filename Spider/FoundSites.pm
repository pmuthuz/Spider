package Spider::FoundSites;
use strict;
use warnings;
use WWW::Mechanize;
use WWW::Mechanize::Frames;
use Digest::MD5 qw(md5_hex);
use HTTP::Response;
use Scalar::Util qw(blessed);
use base 'Spider::DBI';
use Data::Dumper;
use Spider::PotentialCustomer;

__PACKAGE__->table('found_sites');
__PACKAGE__->columns( Primary => qw/id/ );
__PACKAGE__->columns( Essential => qw/url_md5 seed_id status url title/);
__PACKAGE__->columns( Other => qw/content site_type date_found updated email phone mail_address twitter facebook linkedin
                                                                          responsive has_built_by_link built_by service_needed_design service_needed_seo service_needed_maint copyright_year snapchat/ );

__PACKAGE__->add_trigger(
    before_create => sub {
        my $self = shift;
        $self->{url_md5} = md5_hex($self->{url});
	}
);

sub new {
    my $class = shift;
    my $url = shift;
    my $site_id = shift;

    my $self = {
      url => $url,
      site_id => $site_id,
    };

    return bless $self, $class;

}

sub save {
    my $self = shift;
    $self->{url_md5} = md5_hex($self->{url});
    $self->{status} = 'Not Scanned';

    #warn Dumper( $self );

    my $res = Spider::FoundSites->find_or_create({ url_md5 =>$self->{url_md5},  url => $self->url, site_id => $self->{site_id} });

    return $res;
}

sub scan {
     my $self = shift;
     my $mech = WWW::Mechanize::Frames->new();
     $self->{url} = 'http://www.' . $self->url;
     $mech->get( $self->url );
     $self->status('In Progress');
     $self->update;
     $self->{title} =  $mech->title();
     $self->{content} =  $mech->content( format => 'text' );
     $self->get_contact_page;
     $self->{site_type} = $self->check_cms();
     #$self->{email}  = $self->get_email();
     #$self->{phone} = $self->get_phone();
     #$self->{mail_address} = $self->get_mail_address();
     $self->{has_built_by_link} = $self->get_built_by_link();
     $self->{built_by} = $self->get_built_by();
     $self->{date_found} = localtime();
     if( $self->facebook || $self->twitter || $self->linkedin ) {
          $self->{responsive} = 'Yes';
     }
     # service_needed_design 
     $self->{built_by} = $self->need_design();
     # service_needed_seo 
     $self->{need_seo} = $self->need_seo();
     # service_needed_maintenance 
     $self->{need_maintenance} = $self->need_maintenance();

     $self->status('Scanned');
     $self->update;
     $self->{site_type} = $self->check_SEO();
     return 1;
}

sub need_design {
    my $self = shift;
    if ( defined $self->copyright_year && $self->copyright_year ) {
        my $cur_year =  1900 + (localtime)[5];
        if ( $cur_year >= $self->copyright_year) {
            return 'No';
        }
        else {
            return 'Yes';
        }
    }
    else {
        return 'No';
    }
} 

sub need_seo {  # TODO
    my $self = shift;
    return $self->need_design;
} 

sub need_maintenance {  # TODO
    my $self = shift;
    return $self->need_design;
} 

sub get_built_by_link {
    my $self = shift;
    my $content  = $self->{content};
    if ( $content =~ /Designed by\s(.*)/smig ){
        return $1;
    }
    return 'not found';
} 

sub get_built_by {
    my $self = shift;
    my $content  = $self->{content};
    if ( $content =~ /Designed by\s(.*)/smig ){ # TODO Still needs some fine tuning
        return $1;
    }
    return 'not found';
} 

sub check_cms {
     my $self = shift;

     #my $client= new Gearman::Client;
     #$client->job_servers('localhost:4730');

     if ( $self->is_wordpress ) {
          return 'Wordpress';
          #Spider::FoundSites->find_or_create( { url => $self->url, type => 'Wordpress' });
          #$client->dispatch_background('get_contact_form', $self->id);
     }
     elsif ( $self->is_drupal ) {
          return 'Drupal';
          #Spider::FoundSites->find_or_create( { url => $self->url, type => 'Drupal' });
          #$client->dispatch_background('get_contact_form', $self->id);
     }

     return;

}

sub get_email {
    my $self = shift;
    return if ( defined $self->email && $self->email );
    my $content  = $self->{content};
    if ( $content =~ /[a-zA-Z0-9\.\_]+\@\w+\.com/g ){
        my $email = $1;
        if ( defined $email && $email ) {
             $self->email($email);
             $self->update;
        }
    }
    return undef;
} 

sub get_phone {
    my $self = shift;
    return if (defined $self->phone && $self->phone );
    my $content  = $self->{content};
    my $phone = undef;
    if ( $content =~ /(\(\d+\)\s\d+\s\d+)/g ){
        $phone = $1;
    }
    elsif ($content =~/phone[\s:](.*?)\n/i) {
        $phone = $1;
    }
    if (defined $phone) {
        $phone =~ s/phone//i;
        $phone =~ s/<(.*?)>//;
        if ( length($phone) ) {
              $self->phone($phone);
              $self->update;
         }
    }
    return undef;
}

sub get_mail_address {
     my $self = shift;
    return if ( defined $self->mail_address && $self->mail_address );
     my $content  = $self->{content};
    my $mail_address = undef;
    if ( $content =~ /address[\:|\-|\n](.*)/smig ){
        $mail_address = $1;
         if ( length($mail_address) ) {
              $self->mail_address($mail_address);
              $self->update;
         }
    }
    return undef;
}

sub check_SEO {
    my $self = shift;
    my $content  = $self->{content};

    if( $content && $content =~ /SEO/g ){
       print "\n FOUND SEO \n";
       Spider::PotentialCustomer->find_or_create( { site_title => $self->{title} , site_url => $self->url, email => $self->{email}, phone => $self->{phone}, 
                                                                                     facebook => $self->{facebook}, twitter => $self->{twitter}, Snapchat => $self->{Snapchat}, 
                                                                                     mail_address => $self->{mail_address}, created => localtime() });
    } else {
       print "\n NOT FOUND SEO \n";
    }

}

sub is_wordpress {
     my $self = shift;
     my $url = $self->url;

     if ( $url !~ /^http/ ) {
          $url = "http://www.".$url;
     } 

     my $mech = WWW::Mechanize->new();
     my ($response, $content);
     eval { $response = $mech->get($url); $content = $mech->content; };

     if (blessed($response) eq 'HTTP::Response') {
          return 1 if ( ( defined $content ) && ( length($content) > 1 ) && ($content =~ /wordpress/i ) );

          return 1 if ( ( defined $content ) && ( length($content) > 1 ) && ( ( $content =~ /wp-content/i ) || ( $content =~ /wp-includes/i ) ) );

     }

     #Check license.txt
     eval { $response = $mech->get($url . '/license.txt')};
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( $mech->content =~ /wordpress/i ));

     #Check wp-admin
     eval { $response = $mech->get($url . '/wp-admin.php') };
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( $mech->content =~ /wordpress/i ));

     #Check wp-login.php
     eval { $response = $mech->get($url . '/wp-login.php') };
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( $mech->content =~ /wordpress/i ) );

     #Check wp-trackback.php
     eval { $response = $mech->get($url . '/wp-trackback.php') };
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( $mech->content =~ /<response>/i ));

     #Check readme.html
     eval { $response = $mech->get($url . '/readme.html')};
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( $mech->content =~ /wordpress/i ) );

     return 0;

}

sub is_drupal {
     my $self = shift;
     my $url = $self->url;
     if ( $url !~ /^http/ ) {
          $url = "http://www.".$url;
     } 

     my $mech = WWW::Mechanize->new();
     my ($response, $content );
     eval { $response = $mech->get($url); $content = $mech->content; };

     if ( ( blessed($response) eq 'HTTP::Response') && ( defined $content ) && ( length($content) > 1 ) ) {
         return 1 if $content =~ /Drupal/i;

         #Check if drupal.js exists
         return 1 if ( $content =~ /drupal.js/i);
     }

     #Check CHANGELOG.txt
     eval { $response = $mech->get($url . '/CHANGELOG.txt'); $content = $mech->content; };
     return 1 if ( ( blessed($response) eq 'HTTP::Response') && ( length($content) > 1 ) && ( $mech->content =~ /Drupal/i));

     #Check the site's misc folder


     #Check Response header
     eval { $response = $mech->get($url) };
     return 1 if ( (blessed($response) eq 'HTTP::Response') && ( $response->header('Expires') ) && ( $response->header('Expires') =~ /Sun, 19 Nov 1978 05:00:00 GMT/) );

     return 0;
}

sub get_contact_page {
     my $self = shift;

     my $mech = WWW::Mechanize::Frames->new();
    
     $mech->get($self->url);
     $self->{mech_object} = $mech;
     my $content = $mech->content;
     if ($content =~ /contact/i) {
         my $ret = $self->get_contact_info($content);
         return if $ret;
     }

     my @links = $mech->find_link(text => /contact/i);
     foreach my $link (@links) {
         my $mech = WWW::Mechanize::Frames->new();
         $mech->get($link->url_abs);
         my $content = $mech->content;
         $self->{mech_object} = $mech;
         my $ret = $self->get_contact_info($content);
         return if $ret;
     }
     @links = $mech->find_all_links();
     foreach my $link (@links) {
         my $mech = WWW::Mechanize::Frames->new();
         $mech->get($link->url_abs);
         my $content = $mech->content;
         $self->{mech_object} = $mech;
         my $ret = $self->get_contact_info($content);
         return if $ret;
     }
 
}

sub get_contact_info {
    my ($self, $content) = @_;
    $self->{content} = $content;
    $self->get_email();
    $self->get_phone();
    $self->get_mail_address();
    $self->copyright;
    $self->get_facebook_link;
    $self->get_twitter_link;
    $self->get_linkedin_link;
    $self->get_snapchat_link;
    if ( $self->email && $self->phone && $self->mail_address && $self->copyright_year && $self->facebook && $self->twitter && $self->linkedin && $self->snapchat) {
         return 1;
    }
    else {
         return 0;
    }    
}

sub get_facebook_link {
    my $self = shift;
    return if ( defined $self->facebook && $self->facebook );
    my $mech = $self->{mech_object};
    my @fb_links = $mech->find_link(text_regex => qr/facebook/i);
     foreach my $link ( @fb_links ) {
         $self->facebook($link->url);
         $self->update;
     }
     return;
}

sub get_twitter_link {
    my $self = shift;
    return if ( defined $self->twitter && $self->twitter );
    my $mech = $self->{mech_object};

     my @tweet_links = $mech->find_link(text_regex => qr/twitter/i);
     foreach my $link ( @tweet_links ) {
         $self->twitter($link->url);
         $self->update;
     }
     return;

}
sub get_linkedin_link {
    my $self = shift;
    return if ( defined $self->linkedin && $self->linkedin );
    my $mech = $self->{mech_object};

     my @linkedin_links = $mech->find_link(text_regex => qr/linkedin/i);
     foreach my $link ( @linkedin_links ) {
         $self->linkedin($link->url);
         $self->update;
     }
     return;

}

sub get_snapchat_link {
    my $self = shift;
    return if ( defined $self->snapchat && $self->snapchat );
    my $mech = $self->{mech_object};

     my @snapchat_links = $mech->find_link(text_regex => qr/snapchat/i);
     foreach my $link ( @snapchat_links ) {
         $self->snapchat($link->url);
         $self->update;
     }
     return;

}
sub copyright {
    my $self = shift;
    my $content = $self->{content};

    my $copy = $& if ($content =~ /copyright(.*?)\n/i);

    if ( defined $copy && $copy =~ /((\d){4})/ ) {
         my $year = $1;
         if ( length($year)) {
              $self->copyright_year($year);
              $self->update;
         }
    }
    return;
}
1;
