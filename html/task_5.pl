#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Scalar::Util "looks_like_number";


sub parse_csv {
  #
  # Reads a comma-separated CSV file into a 2D array
  # Terminates execution with an HTML message if the file is empty
  #
  my ($q, $path) = @_;

  open(my $fh, '<', $path) or die "Cannot open file $path for reading: $!";
  
  my @books;
  while (my $raw_line = <$fh>) {
    chomp $raw_line;
    push @books, [split(/,/, $raw_line)];
  }
  close $fh or die "Cannot close file $path $!";

  unless (@books) {
    print $q->p("CSV is empty");
    print $q->end_html();
    exit;
  }

  return @books;
}


sub analyse_by_pages {
  #
  # Analyzes the count column (index 3) and calculates statistics
  # Returns valid count, sum, min, max, avg
  #
  my (@books) = @_;

  my @pages = map { $_->[3] } @books;

  my $valid = 0;
  my $sum = 0;
  my ($min, $max);
  for my $page (@pages) {
    next unless (defined $page and looks_like_number($page));

    $valid++;
    $sum += $page;
    $max = $page if !defined $max or $page > $max;
    $min = $page if !defined $min or $page < $min;
  }

  my $avg = ($valid > 0) ? ($sum / $valid) : undef;

  # TODO: bonus: calculate median

  return ($valid, $sum, $min, $max, $avg);
}


sub create_html_rows {
  #
  # Converts 2D array rows to HTML table rows
  # Highlights page values above average in red
  #
  my ($q, $avg, @books) = @_;

  my @html_table;
  for my $book (@books) {
    my $color = (defined $book->[3] and $book->[3] > $avg) ? "red" : "";
    push @html_table, $q->Tr(
      $q->td([@$book[0..2]]),
      $q->td({ -style => "color: $color" }, $book->[3])
    );
  }

  return @html_table;
}

my $q = CGI->new;

print $q->header({ -charset => "utf-8"});
print $q->start_html();
print $q->h1("task 5");

my @books = parse_csv($q, "/home/kipry/src/task_5.csv");
my ($valid, $sum, $min, $max, $avg) = analyse_by_pages(@books);
my @html_table = create_html_rows($q, $avg, @books);

print $q->h3("page analysis:");
print $q->p("valid values: ", $valid);
print $q->p("sum: ", $sum);
print $q->p("min: ", $min);
print $q->p("max: ", $max);
print $q->p("avg: ", $avg);
print $q->table({ -border => 1 }, @html_table);

print $q->end_html();
