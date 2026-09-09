#!/usr/bin/perl

use strict;
use warnings;
use CGI;


sub parse_csv {
  #
  # Parses a 3-column CSV file into 2D array using REGEX
  #
  my ($path) = @_;

  open(my $fh, "<", $path) or die "couldn't open file, $!";

  my @lines;
  for my $item (<$fh>) {
    chomp $item;
    my @line = split(/^("(?:[^"]|"")*"|[^,]*),("(?:[^"]|"")*"|[^,]*),("(?:[^"]|"")*"|[^,]*)$/, $item); # TODO: remove edge double quotes
    shift @line;
    push @lines, [@line];
  }
  close $fh or die "couldn't close file properly, $!";

  return @lines;
}


sub create_html_rows {
  #
  # Converts 2D array data into HTML table rows (<tr>)
  # Expects the first rows ($lines[0]) to contain column headers (<th>)
  #
  my ($q, @lines) = @_;

  my @html_rows;
  push @html_rows, $q->Tr($q->th($lines[0])); # on 0 index are headings
  shift @lines;
  for my $row (@lines) {
    push @html_rows, $q->Tr($q->td($row));
  }

  return @html_rows;
}


my $q = CGI->new;
my @lines = parse_csv("/home/kipry/src/task_3.csv");
my @html_rows = create_html_rows($q, @lines);

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1( "task 3" );
print $q->table( { -border => 1 }, @html_rows);
print $q->end_html();

