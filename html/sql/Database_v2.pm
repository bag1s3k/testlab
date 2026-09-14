#!/usr/bin/perl

use warnings;
use strict;
use DBI;

package Database_v2;
#
# Manages database connections, configuration loading
# and CRUD operations
#

sub new {
    #
    # Constructor. Creates a new Database obejct.
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

    open(my $fh, '<', $path) or die "Cannot open file '$path' for reading: $!";

    my %creds;
    while (my $row = <$fh>) {
        chomp $row;
        my ($k, $v) = $row =~ /^([A-Z0-9_]+)=(.*)/;
        $creds{$k} = $v;
    }
    close $fh;
    $self->{_creds} = \%creds;

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
    # TODO: docs
    my ($self, $sql, @bind) = @_;

    my $sth = $self->{_dbh}->prepare($sql);
    $sth->execute(@bind);
    return $sth;
}

sub select_all {
    # TODO: docs
    my ($self, $sql, @bind) = @_;

    my $sth = $self->run($sql, @bind);
    my $rows = $sth->fetchall_arrayref();

    return $rows;
}

sub select_hashes {
    # TODO: docs
    my ($self, $sql, @bind) = @_;

    my $sth = $self->run($sql, @bind);
    my $rows = $sth->fetchall_arrayref( {} );

    return $rows;
}

sub select_hash {
    # TODO: docs
    my ($self, $sql, @bind) = @_;

    my $sth = $self->run($sql, @bind);
    my $row = $sth->fetchrow_hashref();

    return $row;
}

sub select_row {
    # TODO: docs
    my ($self, $sql, @bind) = @_;
    return $self->run($sql, @bind)->fetchall_arrayref();
}

sub select_value {
    # TODO: docs
    my ($self, $sql, @bind) = @_;
    my $row = $self->select_row($sql, @bind);
    return $row ? $row->[0] : undef;
}

sub _iden {
    # TODO: docs
    my ($name) = @_;
    return "`$name`";
}

sub _idens {
    # TODO: docs
    my @names = @_;

    my @indents;
    for my $name (@names) {
        push @indents, _iden($name);
    }

    return join(", ", @indents);
}

sub insert {
    # TODO: docs
    # NOTE: supports method chaining
    my ($self, $table, $data) = @_;

    my ($cols, $vals);
    if (ref $data eq 'HASH') {
        $cols = [keys %$data];
        $vals = [values %$data];
    } elsif (ref $data eq 'ARRAY') {
        ($cols, $vals) = @$data;
    }

    my $table_name = _iden($table);
    my $column_names = _idens(@$cols);
    my $values = join(", ", ("?") x @$cols);

    my $sql = "INSERT INTO $table_name ($column_names) VALUES ($values)";
    $self->run($sql, @$vals);

    return $self;
}

sub insert_namy {
    # TODO: docs
    # NOTE: supports method chaining
    my ($self, $table, $cols, $rows) = @_;

    my $table_name = _iden($table);
    my $column_names = _idens(@$cols);
    my $values = join(", ", ("?") x @$cols);
    
    my $sql = "INSERT INTO $table_name ($column_names) VALUES ($values)";

    my $sth = $self->{_dbh}->prepare($sql);

    for my $row (@$rows) {
        $sth->execute(@$row);
    }

    return $self;
}

sub update {
    # TODO: docs
    # NOTE: supports method chaining
    my ($self, $table, $set, $where) = @_;

    my @set_columns = keys %$set;
    my @where_columns = keys %$where;

    my $table_name = _ident($table);

    my @set_parts;
    for my $column (@set_columns) {
        push @set_parts, _iden($column) . " = ?";
    }
    my $set_sql = join(" AND ", @set_parts);

    my @where_parts;
    for my $column (@where_columns) {
        push @where_parts, iden($column) . " = ?";
    }
    my $where_sql = join(" AND ", @where_parts);

    my $sql = "UPDATE $table_name SET $set_sql WHERE $where_sql";

    my @values = (
        @{$set}{@set_columns},
        @{$where}{@where_columns}
    );

    my $sth = $self->run($sql, @values);

    return $self;
}

sub update_by_id {
    my ($self, $table, $id, $set) = @_;
    return $self->update($table, $set, { id => $id });
}

sub delete {
    # TODO: docs
    # NOTE: supports method chaining
    my ($self, $table, $where) = @_;

    my @where_columns = keys %$where;
    
    my $table_name = _iden($table);

    my @where_parts;
    for my $column (@where_columns) {
        push @where_parts, _iden($column) . " = ?";
    }
    my $where_sql = join(" AND ", @where_parts);

    my $sql = "DELETE FROM $table_name WHERE $where_sql";

    my @values = @{$where}{@where_columns};

    my $sth = $self->run($sql, @values);

    return $self;
}

sub delete_by_id {
    # TODO: docs
    # NOTE: supports method chaining
    my ($self, $table, $ids) = @_;

    my $table_name = _iden($table);

    my $values = join(", ", ("?") x @$ids);

    my $sql = "DELETE FROM $table_name WHERE id IN ($values)";

    my $sth = $self->run($sql, @$ids);

    return $self;
}

sub commit {
    # TODO: docs
    my ($self) = @_;
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
