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

# Add note save/update helper for future use
sub save_note_for_user {
    my ($user_id, $content) = @_;
    my $dbh = Model::connect();
    my $now = scalar localtime;
    my $sth = $dbh->prepare('SELECT id FROM notes WHERE user_id = ?');
    $sth->execute($user_id);
    my ($note_id) = $sth->fetchrow_array;
    if ($note_id) {
        $dbh->do('UPDATE notes SET content = ?, updated_at = ? WHERE id = ?', undef, $content, $now, $note_id);
    } else {
        $dbh->do('INSERT INTO notes (user_id, content, updated_at) VALUES (?, ?, ?)', undef, $user_id, $content, $now);
    }
}

1;
