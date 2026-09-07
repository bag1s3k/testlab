#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Scalar::Util "looks_like_number";

my $q = CGI->new;
my $selected_column = $q->param("selected_column") // 0;

open(my $fh, "<", "../src/task_2.txt") or die("couldn't open file, $!");

my @lines;
for my $item (<$fh>) {
  chomp $item;
  push @lines, [split(/\|/, $item)];
}

my @sorted_by_pages = sort {
  my $val_1 = $a->[$selected_column];
  my $val_2 = $b->[$selected_column];
  return (looks_like_number $a->[$selected_column]) ? $val_1 <=> $val_2 : $val_1 cmp $val_2;
} @lines;


my @html_rows;
for my $row (@sorted_by_pages) {
  push @html_rows, $q->Tr($q->td($row));
}

close($fh) or die "couldn't close file properly, $!";

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1( 'task 2' );
print $q->table( { -border => 1 }, @html_rows);

print $q->start_form();
print $q->radio_group(
  -name => 'selected_column',
  -values => [0..3],
  -default => 0
);
print $q->submit();
print $q->end_form();

print $q->p("number of records: ", scalar @lines);
print $q->end_html();
