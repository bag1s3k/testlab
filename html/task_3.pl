#!/usr/bin/perl

use strict;
use warnings;
use CGI;

my $q = CGI->new;

open(my $fh, "<", "../src/task_3.csv") or die "couldn't open file, $!";

my @lines;
for my $item (<$fh>) {
  chomp $item;
  my @line = split(/^("(?:[^"]|"")*"|[^,]*),("(?:[^"]|"")*"|[^,]*),("(?:[^"]|"")*"|[^,]*)$/, $item);
  shift @line;
  push @lines, [@line];
}

close $fh or die "couldn't close file properly, $!";

my @html_rows;
push @html_rows, $q->Tr($q->th(@lines[0]));
shift @lines;
for my $row (@lines) {
  push @html_rows, $q->Tr($q->td($row));
}

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1( "task 3" );
print $q->table( { -border => 1 }, @html_rows);
print $q->end_html();

