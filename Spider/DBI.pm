package Spider::DBI;
use Class::DBI 3.0.14;
use base 'Class::DBI';
use Config::Tiny;

#my $dsn      = 'dbi:mysql:database=spider;host=xxx.amazonaws.com;port=:3306';
#my $user     = 'xxx';
#my $password = 'xxx';

sub db_Main {
  my $self = shift;
  __PACKAGE__->_remember_handle( 'Main' );

  return $self->dbh();
}

sub dbh {
    my $self = shift;
    unless ( $self->{dbh} ) {
         my $config = Config::Tiny->read('./spider.conf');
         
        $self->{dbh} = DBI->connect($config->{mysql}->{dsn}, $config->{mysql}->{user}, $config->{mysql}->{password}, {
            PrintError         => 1,
            RaiseError         => 1,
            RootClass          => 'DBIx::ContextualFetch',
            FetchHashKeyName   => 'NAME_lc',
            ShowErrorStatement => 1,
            AutoCommit         => 1,
          }) || die "Couldn't connect to DB\n";
    }
    return $self->{dbh};
    #Scan::DBI->set_db('Main', $dsn, $user, $password);
}
1;
