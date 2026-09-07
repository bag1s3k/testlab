#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Scalar::Util "looks_like_number";

my $q = CGI->new;

print $q->header({ -charset => "utf-8"});
print $q->start_html();
print $q->h1("task 5");

open(my $fh, '<', "../src/task_5.csv") or die "Cannot open file 'file name' for reading: $!";

my @books;
while (my $raw_line = <$fh>) {
  chomp $raw_line;
  push @books, [split(/,/, $raw_line)];
}
close $fh or die "Cannot close file 'task_5.csv' $!";

unless (@books) {
  print $q->p("CSV is empty");
  print $q->end_html();
  exit;
}

my $valid = scalar @books;
my $sum = 0;
my $min = $books[0][3];
my $max = $books[0][3];
for my $book (@books) {
  my $val = $book->[3];

  unless (defined $val and looks_like_number($val)) {
    $valid--;
  } else {
    $sum += $val;
    $max = $val if $val > $max;
    $min = $val if $val < $min;
  }
}

my $avg = ($valid > 0) ? ($sum / $valid) : 0;
my @html_table;
for my $book (@books) {
  my $color = (defined $book->[3] and $book->[3] > $avg) ? "red" : "";
  push @html_table, $q->Tr(
    $q->td([@$book[0..2]]),
    $q->td({ -style => "color: $color" }, $book->[3])
  );
}

print $q->h3("page analysis:");
print $q->p("valid values: ", $valid);
print $q->p("sum: ", $sum);
print $q->p("min: ", $min);
print $q->p("max: ", $max);
print $q->p("avg: ", $avg);
print $q->table({ -border => 1 }, @html_table);

print $q->end_html();
