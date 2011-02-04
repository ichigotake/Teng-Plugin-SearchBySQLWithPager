package Teng::Plugin::SearchBySQLWithPager;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.00_01';
use Carp ();
use Data::Page::NoTotalEntries;

our @EXPORT = qw/search_by_sql_with_pager/;

sub search_by_sql_with_pager {
    my ($self, $sql) = splice @_, 0, 2;
    my $opt = pop;
    my @binds = @{ shift || [ ] };

    my ($page, $rows) = map {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
        Carp::croak("$_ must be an integer") if $opt->{$_} =~ tr/0-9//c;
        $opt->{$_};
    } qw/page rows/;

    $sql =~ s/ ; \s* \z//xms;
    $sql .= ' LIMIT ? OFFSET ?';
    push @binds, $rows + 1, $rows*($page-1);
    my $ret = [ $self->search_by_sql($sql, \@binds, @_) ];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) { pop @$ret }

    my $pager = Data::Page::NoTotalEntries->new(
        entries_per_page     => $rows,
        current_page         => $page,
        has_next             => $has_next,
        entries_on_this_page => scalar(@$ret),
    );

    return ($ret, $pager);
}

1;
__END__

=head1 NAME

Teng::Plugin::SearchBySQLWithPager - Teng plugin to add 'search_by_sql_with_pager' method

=head1 SYNOPSIS

  package MyApp::DB;
  use parent 'Teng';
  __PACKAGE__->load_plugin('SearchBySQLWithPager');
  
  package main;
  my $db = MyApp::DB->new(...);
  my $page = $c->req->param('page') || 1;
  my ($rows, $pager) = $db->search_by_sql_with_pager(
      'SELECT id, name, type FROM user WHERE type = ?',
      [ 3 ],
      'user',
      { page => $page, rows => 5 },
  );

=head1 DESCRIPTION

Teng::Plugin::SearchBySQLWithPager is

=head1 AUTHOR

Yuki Ibe E<lt>yibe at yibe dot orgE<gt>

=head1 SEE ALSO

L<Teng>, L<Teng::Plugin::Pager>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
