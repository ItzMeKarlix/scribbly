#!/usr/bin/env perl
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use Model;
use Digest::SHA qw(sha1_hex);

helper db => sub { Model::connect() };

get '/' => sub {
    my $c = shift;
    return $c->redirect_to('/login');
};

get '/register' => sub {
    my $c = shift;
    $c->render(template => 'auth/register');
};

post '/register' => sub {
    my $c = shift;
    my $username = $c->param('username');
    my $raw_password = $c->param('password');

    # Password must be alphanumeric and contain at least one capital letter
    unless ($raw_password =~ /^(?=.*[A-Z])[A-Za-z0-9]+$/) {
        return $c->render(text => 'Password must be alphanumeric and contain at least one capital letter.');
    }
    my $password = sha1_hex($raw_password);

    if (Model::user_exists($username)) {
        return $c->render(text => 'User already exists.');
    }

    Model::create_user($username, $password);
    $c->redirect_to('/login');
};

get '/login' => sub {
    my $c = shift;
    # If already logged in, redirect to workspace
    return $c->redirect_to('/workspace') if $c->session('user_id');
    $c->render(template => 'auth/login');
};

post '/login' => sub {
    my $c = shift;
    my $username = $c->param('username');
    my $password = sha1_hex($c->param('password'));

    my $user = Model::validate_login($username, $password);
    if ($user) {
        $c->session(user_id => $user->{id});
        $c->redirect_to('/workspace');
    } else {
        $c->render(text => 'Invalid credentials.');
    }
};

get '/logout' => sub {
    my $c = shift;
    $c->session(expires => 1); # Clear session    $c->res->headers->cache_control('no-store, no-cache, must-revalidate, max-age=0');
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->redirect_to('/login');
};


get '/workspace' => sub {
    my $c = shift;
    $c->res->headers->cache_control('no-store, no-cache, must-revalidate, max-age=0');
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->res->headers->expires(0);
    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $note_id = $c->param('note_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $sth->execute($user_id);
    my ($username) = $sth->fetchrow_array;
    my ($note_title, $note_content);

    # If note_id is 'new', always show a blank note and clear session
    if (defined $note_id && $note_id eq 'new') {
        $note_title = '';
        $note_content = '';
        $c->session(last_note_id => undef);
    } else {
        # Session-based last opened note
        if (!$note_id) {
            $note_id = $c->session('last_note_id');
        }
        if ($note_id) {
            my $note_sth = $dbh->prepare('SELECT title, content FROM notes WHERE id = ? AND user_id = ?');
            $note_sth->execute($note_id, $user_id);
            ($note_title, $note_content) = $note_sth->fetchrow_array;
            $c->session(last_note_id => $note_id); # update session
        } else {
            $note_title = '';
            $note_content = '';
            $c->session(last_note_id => undef);
        }
    }
    $c->render(template => 'protected/workspace', username => $username, note_title => $note_title, note_content => $note_content);
};

get '/workspace-new' => sub {
    my $c = shift;
    $c->res->headers->cache_control('no-store, no-cache, must-revalidate, max-age=0');
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->res->headers->expires(0);
    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $sth->execute($user_id);
    my ($username) = $sth->fetchrow_array;
    # Always show a blank note and clear session
    $c->session(last_note_id => undef);
    $c->render(template => 'protected/workspace', username => $username, note_title => '', note_content => '');
};

get '/dashboard' => sub {
    my $c = shift;
    $c->res->headers->cache_control('no-store, no-cache, must-revalidate, max-age=0');
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->res->headers->expires(0);
    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $sth->execute($user_id);
    my ($username) = $sth->fetchrow_array;
    my $notes_sth = $dbh->prepare('SELECT id, title, content, updated_at FROM notes WHERE user_id = ? ORDER BY updated_at DESC');
    $notes_sth->execute($user_id);
    my $notes = $notes_sth->fetchall_arrayref({});
    $c->render(template => 'protected/dashboard', username => $username, notes => $notes);
};

# List all notes for the user
get '/notes-list' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare('SELECT id, title, updated_at FROM notes WHERE user_id = ? ORDER BY updated_at DESC');
    $sth->execute($user_id);
    my $notes = $sth->fetchall_arrayref({});
    $c->render(json => { success => 1, notes => $notes });
};

# Get a single note by id
get '/note/:id' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $note_id = $c->param('id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare('SELECT id, title, content FROM notes WHERE id = ? AND user_id = ?');
    $sth->execute($note_id, $user_id);
    my $note = $sth->fetchrow_hashref;
    if ($note) {
        $c->render(json => { success => 1, note => $note });
    } else {
        $c->render(json => { success => 0, error => 'Note not found' });
    }
};

# Save or update a note
post '/save-note' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $data = $c->req->json;
    my $content = $data->{content};
    my $title = $data->{title};
    my $note_id = $data->{id};
    my $dbh = Model::connect();
    my $now = scalar localtime;
    if ($note_id) {
        $dbh->do('UPDATE notes SET title = ?, content = ?, updated_at = ? WHERE id = ? AND user_id = ?', undef, $title, $content, $now, $note_id, $user_id);
        $c->session(last_note_id => $note_id); # Set last opened/edited note
        $c->render(json => { success => 1, id => $note_id });
    } else {
        $dbh->do('INSERT INTO notes (user_id, title, content, updated_at) VALUES (?, ?, ?, ?)', undef, $user_id, $title, $content, $now);
        my $new_id = $dbh->sqlite_last_insert_rowid;
        $c->session(last_note_id => $new_id); # Set last opened/edited note
        $c->render(json => { success => 1, id => $new_id });
    }
};

# Delete note endpoint
post '/delete-note' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $id = $c->req->json->{id};
    my $dbh = Model::connect();
    $dbh->do('DELETE FROM notes WHERE id = ? AND user_id = ?', undef, $id, $user_id);
    $c->render(json => { success => 1 });
};

# Delete all notes for the current user
post '/delete-all-notes' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    $dbh->do('DELETE FROM notes WHERE user_id = ?', undef, $user_id);
    $c->render(json => { success => 1 });
};

app->start;
