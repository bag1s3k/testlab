#!/usr/bin/perl 

use warnings;
use strict;
use CGI;
use CGI::Carp "fatalsToBrowser";

use lib '.';
use Database;


my $q = CGI->new();
my $db = Database->new();
$db->load_creds("/home/kipry/.db_env")->connect("mysql", 0);

my $action = $q->param("action") // "list";

if ($action eq "list") {
  show_list($q, $db);
} elsif ($action eq "delete") {
  handle_delete($q, $db);
} elsif ($action eq "edit") {
  handle_edit($q, $db);
} elsif ($action eq "add") {
  handle_add($q, $db);
}


sub show_list {
  #
  # Show home page. READ part.
  #
  my ($q, $db) = @_;

  print $q->header({ -charset => "utf-8" });
  print $q->start_html();
  print $q->h1("Task 2");

  my $list = $db->run("SELECT * FROM subjects ORDER BY title ASC");

  print $q->start_form({ -method => "GET" });
  
  my @html_rows;
  push @html_rows, $q->Tr($q->th(["", "id", "title", "credits"]));
  for my $row (@$list) {
    push @html_rows, $q->Tr(
      $q->td($q->checkbox(-name => 'selected', -value => $row->[0], -label => '')),
      $q->td($row)
    );
  }

  print $q->table({ border => 1 }, @html_rows);

  print $q->p(
    $q->submit({ -name => "action", -value => "edit", -label => "Edit Selected" }),
    $q->submit({ -name => "action", -value => "delete", -label => "Delete Seletecd" }),
    $q->submit({ -name => "action", -value => "add", -label => "Add new" })
  );

  print $q->end_form();

  print $q->end_html();
}

sub handle_delete {
  #
  # Delete selected rows
  #
  my ($q, $db) = @_;

  my $selected = [$q->param("selected")];

  $db->delete_data("subjects", $selected);

  print $q->redirect("?action=list");
}

sub handle_edit {
  #
  # Edit selected rows
  #
  my ($q, $db) = @_;

  my $selected = [$q->param("selected")];

  if (grep { defined $q->param("title_$_") } @$selected) {
    my @updates;
    for my $id (@$selected) {
      my $title   = $q->param("title_$id");
      my $credits = $q->param("credits_$id");
      push @updates, [$id, $title, $credits];
    }

    $db->save_data("subjects", \@updates);

    print $q->redirect("?action=list");
    exit;
  }

  print $q->header({ -charset => "utf-8" });
  print $q->start_html();
  print $q->h1("Task 2");
  print $q->start_form({ -method => "GET" });

  my $table = $db->get_specific("subjects", $selected);
  for my $row (@$table) {
    print $q->p(
      $row->[0],
      $q->textfield(-name=>"title_$row->[0]", -default=>$row->[1]),
      $q->textfield(-name=>"credits_$row->[0]", -default=>$row->[2])
    );
    print $q->hidden(-name=>"selected", -value=>$row->[0]);
  }
  print $q->submit({ -name=>"action", -value=>"edit" });

  print $q->end_form();
  print $q->end_html();
}

sub handle_add {
  #
  # Show form for adding new records
  #
  my ($q, $db) = @_;

  if (defined $q->param("title") and defined $q->param("credits")) {
    my $title = $q->param("title");
    my $credits = $q->param("credits");

    $db->add_data("subjects",["title", "credits"], [[ $title, $credits ]]);
    print $q->redirect("?action=list");
    exit;
  }

  print $q->header({ -charset => "utf-8"});
  print $q->start_html();
  print $q->h1("Task 2");

  print $q->start_form({ -method => 'GET' });

  for my $header ("title", "credits") {
    print $q->textfield(-name=>$header, -placeholder=>$header);
  }

  print $q->submit({ -name => "action", -value => "add" });
  print $q->end_form();
  print $q->end_html();
}
