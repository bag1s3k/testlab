#!/usr/bin/perl 

use warnings;
use strict;
use DBI;
use CGI;

package Database;
#
# TODO: class docstring
#

sub new {
  #
  # Constructor. Creates a new Database object.
  #
  my ($class, %args) = @_;

  my $self = {
    _creds => $args{creds},
    _dbh => undef
  };

  bless $self, $class;
  return $self;
}

sub load_creds {
  #
  # Parses KEY=VALUE pairs from an environment file
  #
  my ($self, $path) = @_;

  open(my $fh, '<', $path) or die "Cannot open file $path for reading: $!";

  my $credentials;
  while (my $row = <$fh>) {
    my ($key, $value) = $row =~ /(^[A-Z0-9_]+)=(.*$)/;
    $credentials->{$key} = $value;
  }

  $self->{_creds} = $credentials;

  return $self;
}

sub get_creds {
  # 
  # Returns the copy of currently stored credentials
  # In case of uninitialized credentials return empty anonymous hash
  #
  my ($self) = @_;
  return { %{ $self->{_creds} // {} } };
}

sub get_conn {
  #
  # Returns database handle
  #
  my ($self) = @_;
  return $self->{_dbh};
}

sub connect {
  #
  # Established a DBI database connection using stored credentials.
  #
  my ($self, $db_type, $auto_commit) = @_;

  my $creds = $self->{_creds};
  my $db_name = $creds->{'DATABASE'};
  my $host = $creds->{'HOST'} // "localhost";
  my $port = $creds->{'PORT'} // 3306;
  my $user = $creds->{'USER'} // "root";
  my $password = $creds->{'PASSWORD'} // "";
  
  my $dbh = DBI->connect(
    "DBI:$db_type:database=$db_name;host=$host;port=$port",
    $user,
    $password,
    {
      RaiseError => 1,
      mysql_enable_utf8 => 1,
      auto_commit => ($auto_commit // 0)
    }
  ) or die "Unable to connect to database: $db_name";

  $self->{_dbh} = $dbh;

  return $self;
}

sub DESTROY {
  #
  # Disconnect the database connection
  #
  my ($self) = @_;
  $self->{_dbh}->disconnect();
}

1; # End of package declaration

my $db = Database->new();
$db->load_creds("/home/kipry/.db_env")->connect("mysql", 0);
my $dbh = $db->get_conn();
my $sth = $dbh->prepare("SELECT * FROM subjects");
$sth->execute();

while (my @row = $sth->fetchrow_array()) {
  print "@row\n";
}

