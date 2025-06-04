package Model;
use strict;
use warnings;
use DBI;

my $DB_FILE = "scribbly.db";

sub connect {
    my $dbh = DBI->connect("dbi:SQLite:$DB_FILE", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    });
    return $dbh;
}

sub user_exists {
    my ($username) = @_;
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT 1 FROM users WHERE username = ?");
    $sth->execute($username);
    my $row = $sth->fetchrow_arrayref;
    return $row ? 1 : 0;
}

sub create_user {
    my ($username, $password) = @_;
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("INSERT INTO users (username, password) VALUES (?, ?)");
    $sth->execute($username, $password);
}

sub validate_login {
    my ($username, $password) = @_;
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT id FROM users WHERE username = ? AND password = ?");
    $sth->execute($username, $password);
    return $sth->fetchrow_hashref;
}

1;
