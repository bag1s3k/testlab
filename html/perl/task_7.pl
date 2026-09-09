#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON::PP;
use CGI::Carp "fatalsToBrowser";
use Scalar::Util "looks_like_number";


sub read_books {
  #
  # Reads CSV file and returns array of book records
  #
  my ($path) = @_;

  open(my $fh, '<', $path) or die "Cannot open file $path for reading: $!";

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

  return @books;
}


sub filter_books {
  #
  # Filters books by query parameters
  # Returns arrayref of matched books or original if no filter
  #
  my ($books_ref, $q) = @_;

  my @user_input = grep { $_ ne 'sort' and $_ ne 'order' } $q->param();

  if (@user_input) {
    my $key = $user_input[0];
    my $value = $q->param($key);

    my @filtered;
    for my $book (@$books_ref) {
      if (defined $book->{$key} and $book->{$key} =~ /$value/i) {
        push @filtered, $book;
      }
    }

    if (scalar @filtered == 0) {
      my $json = JSON::PP->new;
      print $json->encode({
         status => 404,
         message => "Not Found",
         detail => "No books matched the given criteria"
      });
      exit;
    }

    return \@filtered;
  }

  return $books_ref;
}


sub sort_books {
  #
  # Sorts array of books by key and order
  #
  my ($books_ref, $sort_by, $order) = @_;

  my $sorted = [sort {
    my $val_a = $a->{$sort_by};
    my $val_b = $b->{$sort_by};

    if (looks_like_number($val_a)) {
      return ($order eq 'asc') ? $val_a <=> $val_b : $val_b <=> $val_a;
    } else {
      return ($order eq 'asc') ? $val_a cmp $val_b : $val_b cmp $val_a;
    }
  } @$books_ref];

  return $sorted;
}


my $q = CGI->new;
my $json = JSON::PP->new;

print $q->header(
  -type => "application/json",
  -charset => 'utf-8'
);

my @books = read_books("/home/kipry/src/perl/task_7.csv");
my $result_ref = filter_books(\@books, $q);

my $sort_by = $q->param('sort') // 'title';
my $order = $q->param('order') // 'asc';
my $sorted = sort_books($result_ref, $sort_by, $order);

print $json->encode($sorted);
