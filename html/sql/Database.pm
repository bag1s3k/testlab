#!/usr/bin/perl 

use warnings;
use strict;
use DBI;

package Database;
#
# Manages database connections, configuration loading
# and CRUD operations
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

sub run {
  #
  # Executes a custom SQL statement with given bind parameters
  #
  my ($self, $sql, $data) = @_;

  my $sth = $self->{_dbh}->prepare($sql);
  $sth->execute(@$data);
  return $sth->fetchall_arrayref();
}

sub get_specific {
  #
  # Fetches rows from a table matching a list by IDs
  #
  my ($self, $table, $ids) = @_;

  my $placeholder = join(", ", ("?") x scalar @$ids);

  my $sth = $self->{_dbh}->prepare("SELECT * FROM $table WHERE id IN ($placeholder)");
  $sth->execute(@$ids);
  return $sth->fetchall_arrayref();
}

sub save_data {
  #
  # Updates multiple rows at once.
  #
  my ($self, $table, $data) = @_;

  my $sth = $self->{_dbh}->prepare("UPDATE $table SET title = ?, credits = ? WHERE id = ?");

  for my $row (@$data) {
    my ($id, $title, $credits) = @$row;
    $sth->execute($title, $credits, $id);
  }

  $self->{_dbh}->commit();
}

sub delete_data {
  #
  # Deletes rows from a table where ID matches from the given array
  #
  my ($self, $table, $ids) = @_;

  return unless @$ids;

  my $placeholder = join(", ", ("?") x scalar @$ids);

  my $sth = $self->{_dbh}->prepare("DELETE FROM $table WHERE id IN ($placeholder)");
  $sth->execute(@$ids);
  $self->{_dbh}->commit();
}

sub add_data {
  #
  # Inserts multiple rows into specified table columns
  #
  my ($self, $table, $columns, $rows) = @_;

  my $cols = join(", ", @$columns);
  my $placeholder = join(", ", ("?") x scalar @$columns);
  my $sth = $self->{_dbh}->prepare("INSERT INTO $table ($cols) VALUES ($placeholder)");

  for my $row (@$rows) {
    $sth->execute(@$row);
  }

  $self->{_dbh}->commit();
}

sub DESTROY {
  #
  # Automatically disconnect database connection
  #
  my ($self) = @_;
  $self->{_dbh}->disconnect() if $self->{_dbh};
}

1; # End of package declaration

