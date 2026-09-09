#!/usr/bin/perl

use strict;
use warnings;
use CGI;


# TODO: SORTING
# When values or keys are equal, so there isn't ony option to decide which item
# has privileges. Continue sorting again the opposite site (key or value)
# - 
# Reason: Hashes are randomized per process, so equal-value rows shuffle on reload.
#         Because of that, it looks like the sorting doesn't work.


sub rows_for_keys {
  #
  # Generate HTML lines (<tr>) from hash
  # Uses the $keys array to keep a specific row order
  #
  my ($q, $hash, $keys) = @_;

  my @rows;
  for my $key (@$keys) {
    my $value = $hash->{$key};
    push @rows, $q->Tr($q->td($key), $q->td($value));
  }
  return @rows;
}


sub build_array_sorts {
  #
  # Returns references to 4 sorted array variants
  # (lexicographically and numerically, both ascending and descending)
  #
  my @l = @_;

  my @lex_asc = sort @l;
  my @lex_des = reverse @lex_asc;
  my @num_asc = sort { $a <=> $b } @l;
  my @num_des = reverse @num_asc;
  return (\@lex_asc, \@lex_des, \@num_asc, \@num_des);
}


sub build_hash_sorts {
  #
  # Returns references to 4 sorted array variants from hashes
  # (sorted by key or value, both lexicographically and numerically)
  #
  my %h = @_;
  my @lex_key = sort keys %h;
  my @lex_val = sort { $h{$a} cmp $h{$b} } keys %h;
  my @num_key = sort { $a <=> $b } keys %h;
  my @num_val = sort { $h{$a} <=> $h{$b} } keys %h;
  return (\@lex_key, \@lex_val, \@num_key, \@num_val);
}


my @array_data = (-1, "banana", 10, "apple", 2, 100, 3.14);
my %hash_data = (
    "user_10" => "100",
    "user_20" => "20",
    "user_1" => "3",
    "a_user_2" => "alpha",
    "user_3" => "zeta"
);

my $q = CGI->new;

# arrays
my ($lex_asc, $lex_des, $num_asc, $num_des) = build_array_sorts(@array_data);
my ($lex_key_asc, $lex_val_asc, $num_key_asc, $num_val_asc) = build_hash_sorts(%hash_data);

# hashes
my @rows_lex_key_asc = rows_for_keys($q, \%hash_data, $lex_key_asc);
my @rows_lex_val_asc = rows_for_keys($q, \%hash_data, $lex_val_asc);
my @rows_num_key_asc = rows_for_keys($q, \%hash_data, $num_key_asc);
my @rows_num_val_asc = rows_for_keys($q, \%hash_data, $num_val_asc);
my @rows_lex_key_des = reverse @rows_lex_key_asc;
my @rows_lex_val_des = reverse @rows_lex_val_asc;
my @rows_num_key_des = reverse @rows_num_key_asc;
my @rows_num_val_des = reverse @rows_num_val_asc;


my $border_style = { -border => 1 };
print $q->header({ -charset => "utf-8" });
print $q->start_html();
print $q->h1('task 1');

print $q->h3('sort array');
print $q->table($border_style, $q->Tr($q->td($lex_asc)));
print $q->br();
print $q->table($border_style, $q->Tr($q->td($num_asc)));

print $q->h3('sort hash by keys');
print $q->table($border_style, @rows_lex_key_asc);
print $q->br();
print $q->table($border_style, @rows_num_key_asc);

print $q->h3('sort hash by values');
print $q->table($border_style, @rows_lex_val_asc);
print $q->br();
print $q->table($border_style, @rows_num_val_asc);

print $q->h3('sort descending');
print $q->table($border_style, $q->Tr($q->td($lex_des)));
print $q->br();
print $q->table($border_style, $q->Tr($q->td($num_des)));
print $q->br();
print $q->table($border_style, @rows_lex_key_des);
print $q->br();
print $q->table($border_style, @rows_num_key_des);
print $q->br();
print $q->table($border_style, @rows_lex_val_des);
print $q->br();
print $q->table($border_style, @rows_num_val_des);
print $q->end_html();
