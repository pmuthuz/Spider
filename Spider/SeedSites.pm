=head1  NAME

Spider::SeedSites - Data model for seed_sites table

=cut

package Spider::SeedSites;
use strict;
use warnings;
use base 'Spider::DBI';

__PACKAGE__->table('seed_sites');
__PACKAGE__->columns( Primary => qw/id/ );
__PACKAGE__->columns( Essential => qw/url name checked created updated/);

1;
