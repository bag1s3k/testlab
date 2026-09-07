#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON::PP;
use CGI::Carp "fatalsToBrowser";
use Scalar::Util "looks_like_number";

open(my $fh, '<', "../src/task_7.csv") or die "Cannot open file 'task_7.csv' for reading: $!";

my $header_line = <$fh>;
chomp $header_line;
my @headers = split(/,/, $header_line);

my @books;
while (my $raw_line = <$fh>) {
  chomp $raw_line;
  my @values = split(/,/, $raw_line);

  my %book;
  for (my $i = 0; $i < scalar @headers; $i++) {
    $book{$headers[$i]} = $values[$i];
  }

  push @books, \%book;
}
close $fh;

my $q = CGI->new();
my $json = JSON::PP->new;
print $q->header(
  -type => "application/json",
  -charset => 'utf-8'
);

my @user_input = grep { $_ ne 'sort' and $_ ne 'order' } $q->param();
my $result;

if (@user_input) {
  my $key = $user_input[0];
  my $value = $q->param($key);

  my @filtered;
  for my $book (@books) {
    if (defined $book->{$key} and $book->{$key}=~ /$value/i) {
      push @filtered, $book;
    }
  }
  if (scalar @filtered == 0) {
    print $json->encode({
       status => 404,
       message => "Not Found",
       detail => "No books matched the given criteria"
    });
    exit;
  }
  $result = \@filtered;
} else {
  $result = \@books;
}

my $sort_by = $q->param('sort') // 'title';
my $order = $q->param('order') // 'asc';

my $sorted = [sort {
  my $val_a = $a->{$sort_by};
  my $val_b = $b->{$sort_by};

  if (looks_like_number($val_a)) {
    return ($order eq 'asc') ? $val_a <=> $val_b : $val_b <=> $val_a;
  } else {
    return ($order eq 'asc') ? $val_a cmp $val_b : $val_b cmp $val_a;
  }
} @{$result}];

print $json->encode($sorted);
