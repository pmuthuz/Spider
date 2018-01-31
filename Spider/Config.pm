=head1  NAME

Spider::Config - Data model for config table

=cut

package Spider::Config;
use strict;
use warnings;
use base 'Spider::DBI';

__PACKAGE__->table('config');
__PACKAGE__->columns( Primary => qw/id/ );
__PACKAGE__->columns( Essential => qw/option_name option_value/);

1;
