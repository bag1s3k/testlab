#!/usr/bin/perl

use strict;
use warnings;
use CGI;


my $q = CGI->new;

my @raw_data = (-1, "banana", 10, "apple", 2, 100, 3.14);

my %user_data = (
  "user_10" => "100",
  "user_20" => "20",
  "user_1" => "3",
  "a_user_2" => "alpha",
  "user_3" => "zeta"
);

my @list_asc = sort @raw_data;
my @list_des = reverse @list_asc;
my @list_asc_num = sort {$a <=> $b} @list_asc;

sub rows_for_keys {
  my ($hash, $keys) = @_;
  my @rows;
  for my $key (@$keys) {
    my $value = $hash->{$key};
    push @rows, $q->Tr($q->td($key), $q->td($value));
  }
  return @rows;
}

my @rows_by_key_asc = rows_for_keys(\%user_data, [sort keys %user_data]);
my @rows_by_val_asc = rows_for_keys(
  \%user_data,
  [ sort { $user_data{$a} cmp $user_data{$b} } keys %user_data ]
);
my @rows_by_key_des = reverse @rows_by_key_asc;
my @rows_by_val_des = reverse @rows_by_val_asc;

my $border_style = { -border => 1 };
print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1('task 1');

print $q->h3('sort basic array');
print $q->table($border_style, $q->Tr($q->td([@list_asc])) );

print $q->h3('sort hash by keys');
print $q->table($border_style, @rows_by_key_asc );

print $q->h3('sort hash by values');
print $q->table($border_style, @rows_by_val_asc );

print $q->h3('sort descending');
print $q->table($border_style, $q->Tr($q->td([@list_des])) );
print $q->br();
print $q->table($border_style, @rows_by_key_des );
print $q->br();
print $q->table($border_style, @rows_by_val_des );

print $q->h3('sort basic array by num');
print $q->table($border_style, $q->Tr($q->td([@list_asc_num])) );
print $q->end_html();
