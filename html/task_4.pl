#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp "fatalsToBrowser";

my $q = CGI->new;

my $user_input = $q->param('search_field');

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1("task 4");

print $q->start_form({ -method => 'GET' });
print $q->textfield(
  -name=>"search_field",
  -placeholder=>"",
  -default=>$user_input // ""
);
print $q->submit(
  -name=>'submit',
	-value=>'search'
);
print $q->end_form();

$user_input = lc $user_input;
unless (defined $user_input and $user_input ne "") {
  print "\nNo input\n";
  print $q->end_html();
  exit;
}

open(my $fh, '<', "../src/task_4.csv") or die "Cannot open file 'task_4.csv' for reading: $!";

my @books;
while (my $raw_line = <$fh>) {
  chomp $raw_line;
  push @books, [split(/,/, $raw_line)];
}

close $fh or die "Cannot close file 'task_4.csv' $!";

my @results;
for my $book (@books) {
  if (join(" ", (@$book)[0..2]) =~ /\Q$user_input\E/i) {
    push @results, $book;
  }
}

my @html_results;
if (scalar @results == 0) {
  print $q->p("No results");
} else {
  for my $book (@results) {
    push @html_results, $q->Tr($q->td($book));
  }
}
print $q->table( { -border => 1 }, @html_results);
print $q->end_html();
