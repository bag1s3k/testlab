#!/usr/bin/perl

use warnings;
use strict;
use CGI;
use CGI::Carp "fatalsToBrowser";

use lib ".";
use Database;

my $q = CGI->new();
my $db = Database->new();
$db->load_creds("/home/kipry/.db_env")->connect("mysql", 0);

my $selected_subject = $q->param("selected_subject");
if (defined $q->param("save")) {
    for my $param ($q->param()) {
        if ($param =~ /^mark_(\d+)_(\d+)$/) {
            my ($student_id, $subject_id) = ($1, $2);

            my $mark = $q->param($param);

            if ($mark ne "N/A") {
                $db->run(
                    "UPDATE marks SET mark = ? WHERE student_id = ? AND subject_id = ?",
                    [$mark, $student_id, $subject_id]
                );
            } else {
                $db->run(
                    "UPDATE marks SET mark = ? WHERE student_id = ? AND subject_id = ?",
                    [undef, $student_id, $subject_id]
                )
            }
        }
    }
}

if (defined $q->param("delete")) {
    for my $param ($q->param()) {
        if ($param =~ /^mark_(\d+)_(\d+)$/) {
            my ($student_id, $subject_id) = ($1, $2);

            if ($q->param("delete") eq "delete_$student_id") {
                $db->run(
                    "DELETE FROM marks WHERE student_id = ? AND subject_id = ?",
                    [$student_id, $subject_id]
            )
            }
            
        }
    }
}

sub get_received_credits {
    my ($db, $student_id) = @_;

    my $marks = $db->run("SELECT subject_id, mark FROM marks WHERE student_id = ?", [$student_id]);

    my $total_credits = 0;

    for my $mark (@$marks) {
        my ($subject_id, $mark_value) = @$mark;

        if ($mark_value && $mark_value < 5) {
            my $credits = $db->run("SELECT credits FROM subjects WHERE id = ?", [$subject_id])->[0][0];
            $total_credits += $credits;
        }
    }

    return $total_credits;
}

my $subjects = $db->run("SELECT * FROM subjects");
my %subjects_map = map { $_->[0] => $_->[1] } @$subjects;
my $marks = $db->run("SELECT * FROM marks WHERE subject_id = ?", [$selected_subject]);

my @html_table;
push @html_table, $q->Tr($q->th(["id", "name", "lastname", "birth date", "weighted avg.", "received credits", "mark", "", ""]));
if (@$marks) {
    my %id_by_mark = map { $_->[0] => $_->[2] } @$marks;
    my $selected_students = $db->get_specific("students", [keys %id_by_mark]);

    for my $row (@$selected_students) {
        push @html_table, $q->Tr(
            $q->td($row),
            $q->td(), # TODO: weighted average marks by credits per student
            $q->td(get_received_credits($db, $row->[0])),
            $q->td(
                $q->popup_menu(
                    -name=>"mark_" . $row->[0] . "_" . $selected_subject,
                    -values=>[1..5, "N/A"],
                    -default=>$id_by_mark{$row->[0]} // "N/A"
                )
            ),
            $q->td($q->submit(-name=>"save")), # FIX: same problem as with delete button
            $q->td($q->submit(-name=>"delete", -value=>"delete_" . $row->[0]))
        );
    }
}

my $subject_credits = $db->run("SELECT credits FROM subjects WHERE id = ?", [$selected_subject])->[0][0];

my $sum_marks = $db->run("SELECT SUM(mark) FROM marks WHERE subject_id = ?", [$selected_subject])->[0][0];
my $student_num = $db->run("SELECT COUNT(mark) FROM marks WHERE subject_id = ?", [$selected_subject])->[0][0];
my $avg = ($student_num) ? ($sum_marks / $student_num) : "-";

print $q->header();
print $q->start_html();
print $q->h1("task 4");

print $q->start_form( -method=>'GET' );

print $q->popup_menu(
    -name=>"selected_subject",
    -values=>[sort { $a <=> $b } keys %subjects_map],
    -labels =>\%subjects_map
);
print $q->submit();

print $q->table( { -border=>1 }, @html_table);

print $q->p("Avg: " . $avg);

print $q->end_form();

print $q->end_html();
