#!/usr/bin/perl

use strict;
use warnings;
use DBI;

package Database_v2;
#
# v. 2
# Manages database connections, configuration loading
# and CRUD operations
#


sub new {
    #
    # Constructor, Creates a new Database object
    #
    my ($class, %args) = @_;

    my $self = {
        _creds => $args{creds},
        _dbh => undef
    };

    bless $self, $class;
    return $self;
}

sub 
package Database;

use warnings;
use strict;
use DBI;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    return bless {
        creds => $args{creds},
        dbh   => undef,
    }, $class;
}

sub load_creds {
    my ($self, $path) = @_;
    open(my $fh, '<', $path) or croak "Cannot open $path: $!";
    my %creds;
    while (my $row = <$fh>) {
        chomp $row;
        next if $row =~ /^\s*(?:\#|$)/;
        my ($k, $v) = $row =~ /^([A-Z0-9_]+)=(.*)$/ or next;
        $creds{$k} = $v;
    }
    close $fh;
    $self->{creds} = \%creds;
    return $self;
}

sub get_creds {
    my ($self) = @_;
    return { %{ $self->{creds} // {} } };
}

sub connect {
    my ($self, $db_type, $auto_commit) = @_;
    $db_type //= 'mysql';
    my $c = $self->{creds} or croak "No credentials loaded";

    my $dsn = sprintf "DBI:%s:database=%s;host=%s;port=%s",
        $db_type,
        $c->{DATABASE},
        $c->{HOST} // 'localhost',
        $c->{PORT} // 3306;

    my $dbh = DBI->connect(
        $dsn,
        $c->{USER}     // 'root',
        $c->{PASSWORD} // '',
        {
            RaiseError           => 1,
            PrintError           => 0,
            mysql_enable_utf8mb4 => 1,
            AutoCommit           => $auto_commit ? 1 : 0,
        }
    ) or croak "DB connect failed: " . DBI->errstr;

    $self->{dbh} = $dbh;
    return $self;
}

sub dbh { $_[0]->{dbh} }

# ---------------------------------------------------------------
# Low-level
# ---------------------------------------------------------------

sub run {
    my ($self, $sql, @bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@bind);
    return $sth;
}

sub select_all    { return $_[0]->run($_[1], @_[2..$#_])->fetchall_arrayref() }
sub select_hashes { return $_[0]->run($_[1], @_[2..$#_])->fetchall_arrayref({}) }
sub select_hash   { return $_[0]->run($_[1], @_[2..$#_])->fetchrow_hashref() }

sub select_row {
    my ($self, $sql, @bind) = @_;
    return $self->run($sql, @bind)->fetchrow_arrayref();
}

sub select_value {
    my ($self, $sql, @bind) = @_;
    my $row = $self->select_row($sql, @bind);
    return $row ? $row->[0] : undef;
}

# ---------------------------------------------------------------
# Identifier safety (tabulky/sloupce nelze bindovat)
# ---------------------------------------------------------------

sub _ident {
    my ($name) = @_;
    croak "Invalid identifier: " . ($name // 'undef')
        unless defined $name && $name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
    return "`$name`";
}

sub _idents { return join(", ", map { _ident($_) } @_) }

# ---------------------------------------------------------------
# CRUD
# ---------------------------------------------------------------

sub insert {
    # insert('students', { name => 'Jan', age => 20 })
    # insert('students', [ ['name','age'], ['Jan', 20] ])
    my ($self, $table, $data) = @_;

    my ($cols, $vals);
    if (ref $data eq 'HASH') {
        $cols = [keys %$data];
        $vals = [values %$data];
    } elsif (ref $data eq 'ARRAY') {
        ($cols, $vals) = @$data;
    } else {
        croak "insert: expected hashref or [cols, vals]";
    }

    my $sql = sprintf "INSERT INTO %s (%s) VALUES (%s)",
        _ident($table), _idents(@$cols), join(", ", ("?") x @$cols);

    $self->run($sql, @$vals);
    return $self->{dbh}->last_insert_id(undef, undef, undef, undef);
}

sub insert_many {
    # insert_many('students', ['name','age'], [['Jan',20],['Eva',22]])
    my ($self, $table, $cols, $rows) = @_;
    return 0 unless $rows && @$rows;

    my $sql = sprintf "INSERT INTO %s (%s) VALUES (%s)",
        _ident($table), _idents(@$cols), join(", ", ("?") x @$cols);

    my $sth = $self->{dbh}->prepare($sql);
    my $n = 0;
    for my $row (@$rows) {
        $sth->execute(@$row);
        $n++;
    }
    $self->commit;
    return $n;
}

sub update {
    # update('students', { age => 21 }, { id => 5 })
    my ($self, $table, $set, $where) = @_;
    croak "update: empty SET"   unless $set   && %$set;
    croak "update: empty WHERE" unless $where && %$where;

    my @sc = keys %$set;
    my @wc = keys %$where;

    my $sql = sprintf "UPDATE %s SET %s WHERE %s",
        _ident($table),
        join(", ", map { _ident($_) . " = ?" } @sc),
        join(" AND ", map { _ident($_) . " = ?" } @wc);

    my $sth = $self->run($sql, @{$set}{@sc}, @{$where}{@wc});
    $self->commit;
    return $sth->rows;
}

sub update_by_id {
    my ($self, $table, $id, $set) = @_;
    return $self->update($table, $set, { id => $id });
}

sub delete {
    # delete('students', { active => 0 })
    my ($self, $table, $where) = @_;
    croak "delete: empty WHERE" unless $where && %$where;

    my @wc = keys %$where;
    my $sql = sprintf "DELETE FROM %s WHERE %s",
        _ident($table),
        join(" AND ", map { _ident($_) . " = ?" } @wc);

    my $sth = $self->run($sql, @{$where}{@wc});
    $self->commit;
    return $sth->rows;
}

sub delete_by_ids {
    my ($self, $table, $ids) = @_;
    return 0 unless $ids && @$ids;

    my $sql = sprintf "DELETE FROM %s WHERE id IN (%s)",
        _ident($table), join(", ", ("?") x @$ids);

    my $sth = $self->run($sql, @$ids);
    $self->commit;
    return $sth->rows;
}

# ---------------------------------------------------------------
# SELECT helpers
# ---------------------------------------------------------------

sub fetch_all {
    # fetch_all('students', where => {class => 'A'},
    #                        order_by => ['name','ASC'],
    #                        limit => 20,
    #                        columns => ['id','name'])
    my ($self, $table, %opts) = @_;
    my ($sql, @bind) = $self->_build_select($table, %opts);
    return $self->select_all($sql, @bind);
}

sub fetch_one {
    my ($self, $table, $where) = @_;
    my @cols = keys %$where;
    my $sql = sprintf "SELECT * FROM %s WHERE %s LIMIT 1",
        _ident($table),
        join(" AND ", map { _ident($_) . " = ?" } @cols);
    return $self->select_row($sql, @{$where}{@cols});
}

sub fetch_by_id {
    my ($self, $table, $id) = @_;
    return $self->fetch_one($table, { id => $id });
}

sub _build_select {
    my ($self, $table, %opts) = @_;
    my @bind;

    my $cols = $opts{columns}
        ? join(", ", map { _ident($_) } @{ $opts{columns} })
        : "*";
    my $sql = "SELECT $cols FROM " . _ident($table);

    if ($opts{where} && %{ $opts{where} }) {
        my @wc = keys %{ $opts{where} };
        $sql .= " WHERE " . join(" AND ", map { _ident($_) . " = ?" } @wc);
        push @bind, @{ $opts{where} }{@wc};
    }

    if ($opts{order_by}) {
        my ($col, $dir) = @{ $opts{order_by} };
        $dir = uc($dir // 'ASC');
        croak "Invalid order direction: $dir"
            unless $dir eq 'ASC' || $dir eq 'DESC';
        $sql .= " ORDER BY " . _ident($col) . " $dir";
    }

    if ($opts{limit}) {
        $sql .= " LIMIT " . int($opts{limit});
    }

    return ($sql, @bind);
}

# ---------------------------------------------------------------
# Transactions
# ---------------------------------------------------------------

sub commit   { $_[0]->{dbh}->commit   }
sub rollback { $_[0]->{dbh}->rollback }

sub txn {
    # $db->txn(sub { my ($db) = @_; $db->insert(...); $db->update(...); });
    my ($self, $code) = @_;
    my $ok = eval { $code->($self); $self->commit; 1 };
    unless ($ok) {
        my $err = $@;
        eval { $self->rollback };
        croak "Transaction failed: $err";
    }
    return 1;
}

sub DESTROY {
    my ($self) = @_;
    $self->{dbh}->disconnect if $self->{dbh};
}

1;
