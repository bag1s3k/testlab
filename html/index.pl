#! /usr/bin/perl

use strict;
use warnings;
use CGI;

my $q = new CGI;

print $q->header;
print $q->start_html;
print $q->h1( 'Perl works.' );
print $q->end_html;

