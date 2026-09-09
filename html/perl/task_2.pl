#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Scalar::Util "looks_like_number";


sub parse_txt {
  #
  # Reads a pipe-separated text file and returns a 2D array of rows
  #
  my ($path) = @_;

  open(my $fh, "<", $path) or die("couldn't open file, $!");

  my @lines;
  for my $item (<$fh>) {
    chomp $item;
    push @lines, [split(/\|/, $item)];
  }
  close($fh) or die "couldn't close file properly, $!";

  return @lines;
}


sub sort_by_selected_column {
  #
  # Sorts rows by the specified column index
  # Automatically switches between numeric and string sorting
  #
  my ($selected_column, @lines) = @_;

  return sort {
    my $val_1 = $a->[$selected_column];
    my $val_2 = $b->[$selected_column];

    return (looks_like_number $a->[$selected_column]) ? $val_1 <=> $val_2 : $val_1 cmp $val_2;
  } @lines;
}


sub create_html_rows {
  # 
  # Converts 2D array data into HTML table rows
  #
  my ($q, @data) = @_;

  my @html_rows;
  for my $row (@data) {
    push @html_rows, $q->Tr($q->td($row));
  }
  return @html_rows;
}


use constant DEFAULT => 0; # represents 1. column
my $q = CGI->new;
my $selected_column = $q->param("selected_column") // DEFAULT;

my @lines = parse_txt("/home/kipry/src/perl/task_2.txt");
my @sorted_lines = sort_by_selected_column($selected_column, @lines);
my @html_rows = create_html_rows($q, @sorted_lines);

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1( 'task 2' );
print $q->table( { -border => 1 }, @html_rows);

print $q->start_form();
print $q->radio_group(
  -name => 'selected_column',
  -values => [0..3], # creates options 0-3 (4 columns)
  -default => DEFAULT
);
print $q->submit();
print $q->end_form();

print $q->p("number of records: ", scalar @lines);
print $q->end_html();
