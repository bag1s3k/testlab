#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON::PP;


sub parse_json {
  #
  # Reads a JSON file and returns a JSON object
  #
  my ($path) = @_;

  open(my $fh, '<', $path) or die "Cannot open file 'task_6.json' for reading: $!";

  $/ = undef;
  my $json_text = <$fh>;
  close $fh;

  my $json = JSON::PP->new;
  my $data = $json->decode($json_text);
  return $data;
}


sub analyse_ram {
  #
  # Returns the maximum number of RAM
  #
  my ($data) = @_;
  my $max = $data->[0]->{"ram"};

  for my $value (@$data) {
    my $val = $value->{"ram"};
    $max = $val if $val > $max;
  }
  return $max;
}


sub build_table_rows {
  #
  # Converts array of servers hashes into HTML table rows
  # Highlight rows with max RAM
  # Expects first row ($data->[0]) to contain column headers
  #
  my ($q, $data, $max) = @_;

  my @html_rows;
  my $keys = [sort keys %{$data->[0]}];
  push @html_rows, $q->Tr($q->th([@$keys]));

  for my $log (@$data) {
    my @log_values;
    my $highlight = ($log->{"ram"} == $max) ? "red" : "";

    for my $item (@$keys) {
      my $value = $log->{$item};
      if (ref $value eq 'ARRAY') {
        $value = join ', ', @$value;
      }
      push @log_values, $value // '';
    }
    push @html_rows, $q->Tr($q->td({ -style => "color: $highlight" }, [@log_values]));
  }
  return \@html_rows;
}


sub map_servers_by_service {
  #
  # Builds index of servers grouped by service
  #
  my ($data) = @_;
  my %servers_by_services;
  for my $log (@$data) {
    for my $service (@{$log->{"services"}}) {
      push @{$servers_by_services{$service}}, $log->{"name"};
    }
  }
  return \%servers_by_services;
}


my $q = CGI->new;

my $data = parse_json("/home/kipry/src/task_6.json");
my $max = analyse_ram($data);
my $html_rows = build_table_rows($q, $data, $max);
my $servers_by_services = map_servers_by_service($data);

my $avaiable_services = [sort keys %$servers_by_services];
my $default_value = @$avaiable_services[0];
my $user_input = $q->param('selected_service') // $default_value;

print $q->header();
print $q->start_html();
print $q->h1("task 6");

print $q->table({ -border => 1}, @$html_rows);
print $q->start_form({ -method => 'GET' });
print $q->radio_group(
  -name=>'selected_service',
  -values=>$avaiable_services,
  -default=>$default_value
);
print $q->submit();
print $q->end_form();

print $q->p(join ", ", @{$servers_by_services->{$user_input}});

print $q->end_html();
