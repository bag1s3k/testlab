#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON::PP;


my $q = CGI->new;
my $json = JSON::PP->new;

open(my $fh, '<', "../src/task_6.json") or die "Cannot open file 'task_6.json' for reading: $!";

$/ = undef;
my $json_text = <$fh>;
my $data = $json->decode($json_text);

close $fh;

my @html_rows;
my $keys = [sort keys %{$data->[0]}];
my $max = @{$data}[0]->{"ram"};

for my $value (@$data) {
  my $val = $value->{"ram"};
  $max = $val if $val > $max;
}

push @html_rows, $q->Tr($q->th([@$keys]));

my %servers_by_services;
for my $log (@$data) {
  my @log_values;
  my $highlight = ($log->{"ram"} == $max) ? "red" : "";
  
  for my $service (@{$log->{"services"}}) {
    push @{$servers_by_services{$service}}, $log->{"name"};
  }

  for my $item (@$keys) {
    my $value = $log->{$item};

    if (ref $value eq 'ARRAY') {
      $value = join ', ', @$value;
    }
    push @log_values, $value // '';
  }

  push @html_rows, $q->Tr($q->td({ -style => "color: $highlight" }, [@log_values]));
}

my $avaiable_services = [sort keys %servers_by_services];
my $default_value = @$avaiable_services[0];
my $user_input = $q->param('selected_service') // $default_value;

print $q->header();
print $q->start_html();
print $q->h1("task 6");

print $q->table({ -border => 1}, @html_rows);
print $q->start_form({ -method => 'GET' });
print $q->radio_group(
  -name=>'selected_service',
  -values=>$avaiable_services,
  -default=>$default_value
);
print $q->submit();
print $q->end_form();

print $q->p(join ", ", @{$servers_by_services{$user_input}});

print $q->end_html();
