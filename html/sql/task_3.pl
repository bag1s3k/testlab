#!/usr/bin/perl

use warnings;
use strict;
use CGI;
use CGI::Carp "fatalsToBrowser";

use lib ".";
use Database;

# Vytvořte podobnou aplikaci na údržbu tabulky studentů. Umožněte přetřídit tabulku volbou
# záhlaví tabulky (jako Excel) u id, jména, příjmení, data narození. Umožněte druhým kliknutím
# volit směr řazení. Každý řádek tabulky se seznamem studentů udělejte rozklikávací na
# přiřazování předmětů pro tohoto studenta.

my $q = CGI->new();
my $db = Database->new();
$db->load_creds("/home/kipry/.db_env")->connect("mysql", 0);

my $column = $q->param("sort") // "id";
my $order = $q->param($column) // 1;
my $order_str = $order ? "ASC" : "DESC";

print $q->header();
print $q->start_html();
print $q->h1("task 3");

my $data = $db->run("SELECT * FROM students ORDER BY `$column` $order_str");
my $subjects = $db->run("SELECT * FROM subjects");

show_table($q, $data, $subjects, $order, $column);

print $q->end_html();

sub parse_subject_data {
    #
    # Parses subject data and returns values and labels for the popup menu.
    #
    my ($subjects) = @_;

    my @values = ("");
    my %labels = ("" => "-- Choose Subject --");

    for my $row (@$subjects) {
        push @values, $row->[0];
        $labels{$row->[0]} = $row->[1];
    }

    return \@values, \%labels;
}

sub show_table {
    # 
    # Displays the table with students and subject selection dropdowns.
    #
    my ($q, $data, $subjects, $order, $column) = @_;

    my ($values, $labels) = parse_subject_data($subjects);

    print $q->start_form({ -method=>'GET' });

    print $q->hidden(-name=>$column, -value=>($order ? 0 : 1), -override=>1);

    my @headers;
    for my $header ("id", "name", "lastname", "birth_date") {
        push @headers, $q->submit(
            -name=>"sort",
            -value=>$header
        );
    }

    my @html_table = $q->Tr($q->td([@headers]));
    for my $row (@$data) {
        push @html_table, $q->Tr(
            $q->td($row),
            $q->td(
                $q->popup_menu(
                    -name=>"student_" . $row->[0],
                    -values=>$values,
                    -labels =>$labels,
                    -default=>""
                )
            )
        );
    }
    
    print $q->table({ -border=>1 }, @html_table);
    
    print $q->end_form();
}
