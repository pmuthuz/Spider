=head1  NAME

Spider::ScanLink - Data model for scan_links table

=cut

package Spider::ScanLink;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

use base 'Spider::DBI';

__PACKAGE__->table('scan_links');
__PACKAGE__->columns( Primary => qw/uri_md5/ );
__PACKAGE__->columns( Essential => qw/url_id uri uri_md5 depth_level status created updated/);


__PACKAGE__->add_trigger(
    before_create => sub {
        my $self = shift;
        $self->{uri_md5} = md5_hex($self->{uri});
	}
);

1;
