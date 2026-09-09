#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp "fatalsToBrowser";


sub parse_csv {
  #
  # Reads a comma-separated CSV file and returns a 2D array of rows
  #
  my ($path) = @_;

  open(my $fh, '<', $path) or die "Cannot open file $path for reading: $!";
  
  my @books;
  while (my $raw_line = <$fh>) {
    chomp $raw_line;
    push @books, [split(/,/, $raw_line)];
  }
  close $fh or die "Cannot close file 'task_4.csv' $!";
  return @books;
}


sub search {
  #
  # Performs a case-insensitive search across all columns except the last one
  # Returns a 2D array of matching rows
  #
  my ($user_input, @books) = @_;

  my @results;
  for my $book (@books) {
    if (join(" ", (@$book)[0..2]) =~ /\Q$user_input\E/i) {
      push @results, $book;
    }
  }
  return @results;
}


sub create_html_rows {
  # 
  # Converts 2D array data to HTML table rows (<tr>/<td>)
  #
  my ($q, @results) = @_;

  my @html_results;
  if (scalar @results == 0) {
    print $q->p("No results");
  } else {
    for my $book (@results) {
      push @html_results, $q->Tr($q->td($book));
    }
  }
  return @html_results;
}

my $q = CGI->new;

print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1("task 4");

my $user_input = lc($q->param('search_field') // '');

print $q->start_form({ -method => 'GET' });
print $q->textfield(
  -name=>'search_field',
  -placeholder=>"",
  -default=>$user_input
);
print $q->submit(
  -name=>'submit',
	-value=>'search'
);
print $q->end_form();

if ($user_input eq '') {
  print $q->p("\nNo input\n");
  print $q->end_html();
  exit;
}

my @books = parse_csv("/home/kipry/src/perl/task_4.csv");
my @results = search($user_input, @books);
my @html_rows = create_html_rows($q, @results);

print $q->table( { -border => 1 }, @html_rows);
print $q->end_html();
