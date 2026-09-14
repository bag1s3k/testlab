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

my $subjects = $db->run("SELECT id, title FROM subjects ORDER BY id");
my %subjects_map = map { $_->[0] => $_->[1] } @$subjects;

my $selected_subject = $q->param("selected_subject") // (sort { $a <=> $b } keys %subjects_map)[0];

handle_save($q, $db) if defined $q->param("save");

handle_delete($q, $db) if defined $q->param("delete");

my @table_rows;
push @table_rows, $q->Tr($q->td(
    ["id", "name", "lastname", "birth date", "weighted avg.", "earned credits", "mark", "", ""]
));

my $marks = $db->run("
    SELECT student_id, mark FROM marks WHERE subject_id = ?
    ", [$selected_subject]);

my %marks;
for my $row (@$marks) {
    my ($student_id, $mark) = @$row;
    $marks{$student_id} = $mark;
}

my $students = $db->run("
    SELECT id, name, lastname, birth_date
    FROM students
    WHERE id IN (
        SELECT student_id
        FROM marks
        WHERE subject_id = ?
    )
    ORDER BY lastname, name
    ", [$selected_subject]);

for my $student (@$students) {
    my ($student_id, $name, $lastname, $birth_date) = @$student;

    my $mark = $marks{$student_id};

    my $weighted = get_weighted_average($db, $student_id);
    my $credits = get_earned_credits($db, $student_id);

    my $mark_default = defined $mark ? $mark : 'N/A';

    push @table_rows, $q->Tr(
        $q->td($student_id),
        $q->td($name),
        $q->td($lastname),
        $q->td($birth_date),
        $q->td($weighted),
        $q->td($credits),

        $q->td($q->popup_menu(
            -name => "mark_${student_id}_${selected_subject}",
            -values => [1..5, 'N/A'],
            -default => $mark_default
        )),

        $q->td($q->submit(
            -name => "save",
            -value => "save_${student_id}_${selected_subject}",
        )),

        $q->td($q->submit(
            -name => "delete",
            -value => "delete_${student_id}_${selected_subject}",
            -label => "delete",
            -do_label => 1
        ))
    );
}

my $avg = defined $selected_subject ? get_subject_average($db, $selected_subject) : "-";

render_page($q, \%subjects_map, $selected_subject, \@table_rows, $avg);

sub render_page {
    #
    # TODO: docs
    #
    my ($q, $subject_map, $selected_subject, $table_rows, $avg) = @_;

    print $q->header();
    print $q->start_html();
    print $q->h1("task 4");

    print $q->start_form( -method=>'GET' );

    print $q->popup_menu(
        -name => 'selected_subject',
        -values => [sort { $a <=> $b } keys %$subject_map ],
        -labels => $subject_map,
        -default => $selected_subject
    );

    print $q->submit(-value => 'Select');

    print $q->table({ -border => 1}, @table_rows);

    print $q->p("Avg: $avg");

    print $q->end_form();
    print $q->end_html();
}

sub get_subject_average {
    #
    # TODO: docs
    #
    my ($db, $subject_id) = @_;

    my $row = $db->run("
        SELECT AVG(mark) FROM marks WHERE subject_id = ? AND mark IS NOT NULL
    ", [$subject_id])->[0];

    my $avg = $row->[0];

    return defined $avg ? sprintf("%.2f", $avg) : "-";
}

sub get_earned_credits {
    #
    # TODO: docs
    #
    my ($db, $student_id) = @_;

    my $marks = $db->run("
        SELECT mark, subject_id FROM marks
        WHERE student_id = ?
            AND mark IS NOT NULL
            AND mark >= 1
            AND mark < 5
    ", [$student_id]);
    
    my $credits_sum = 0;

    for my $mark (@$marks) {
        my ($value, $subject_id) = @$mark;

        my $subject = $db->run("
            SELECT credits FROM subjects WHERE id = ?
        ", [$subject_id])->[0];

        my $credits = $subject->[0];
        $credits_sum += $credits;
    }
    return $credits_sum;
}

sub get_weighted_average {
    #
    # TODO: docs
    #
    my ($db, $student_id) = @_;

    my $marks = $db->run("
        SELECT mark, subject_id FROM marks
        WHERE student_id = ?
            AND mark IS NOT NULL
            AND mark BETWEEN 1 AND 5
    ", [$student_id]);

    my $weighted_sum = 0;
    my $credits_sum = 0;

    for my $mark (@$marks) {
        my ($value, $subject_id) = @$mark;

        my $subject = $db->run("
            SELECT credits FROM subjects WHERE id = ?
        ", [$subject_id])->[0];

        my $credits = $subject->[0];

        $weighted_sum += $value * $credits;
        $credits_sum += $credits;
    }

    return $credits_sum ? sprintf("%.2f", $weighted_sum / $credits_sum) : 0;
}

sub handle_save {
    #
    # TODO: docs
    #
    my ($q, $db) = @_;

    my $save_value = $q->param("save");
    if ($save_value =~ /^save_(\d+)_(\d+)$/) {
        my ($student_id, $subject_id) = ($1, $2);

        my $mark = $q->param("mark_${student_id}_${subject_id}");

        $mark = undef if !defined $mark or $mark eq 'N/A';

        $db->run(
            "UPDATE marks SET mark = ? WHERE student_id = ? AND subject_id = ?",
            [$mark, $student_id, $subject_id]
        );
    }
}

sub handle_delete {
    #
    # TODO: docs
    #
    my ($q, $db) = @_;

    my $delete_value = $q->param("delete");
    if ($delete_value =~ /^delete_(\d+)_(\d+)$/) {
        my ($student_id, $subject_id) = ($1, $2);

        $db->run(
            "DELETE FROM marks WHERE student_id = ? AND subject_id = ?",
            [$student_id, $subject_id]
        );
    }
}
