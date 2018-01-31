=head1  NAME

Spider::PotentialCustomer - Data model for potential_customer table

=cut

package Spider::PotentialCustomer;
use strict;
use warnings;
use base 'Spider::DBI';

__PACKAGE__->table('potential_customer');
__PACKAGE__->columns( Primary => qw/id/ );
__PACKAGE__->columns( Essential => qw/site_url site_title email phone twitter facebook Snapshat mail_address created updated/);

1;
