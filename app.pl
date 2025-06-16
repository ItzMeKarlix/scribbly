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
    my $password = sha1_hex($c->param('password'));

    if (Model::user_exists($username)) {
        return $c->render(text => 'User already exists.');
    }

    Model::create_user($username, $password);
    $c->redirect_to('/login');
};

get '/login' => sub {
    my $c = shift;
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

get '/workspace' => sub {
    my $c = shift;
    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $sth->execute($user_id);
    my ($username) = $sth->fetchrow_array;
    $c->render(template => 'protected/workspace', username => $username);
};

get '/dashboard' => sub {
    my $c = shift;
    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $dbh = Model::connect();
    my $sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $sth->execute($user_id);
    my ($username) = $sth->fetchrow_array;
    $c->render(template => 'protected/dashboard', username => $username);
};

post '/save-note' => sub {
    my $c = shift;
    return $c->render(json => { success => 0, error => 'Not logged in' }) unless $c->session('user_id');
    my $user_id = $c->session('user_id');
    my $content = $c->req->json->{content};
    my $dbh = Model::connect();
    my $now = scalar localtime;
    # Insert or update the note for this user (one note per user for now)
    my $sth = $dbh->prepare('SELECT id FROM notes WHERE user_id = ?');
    $sth->execute($user_id);
    my ($note_id) = $sth->fetchrow_array;
    if ($note_id) {
        $dbh->do('UPDATE notes SET content = ?, updated_at = ? WHERE id = ?', undef, $content, $now, $note_id);
    } else {
        $dbh->do('INSERT INTO notes (user_id, content, updated_at) VALUES (?, ?, ?)', undef, $user_id, $content, $now);
    }
    $c->render(json => { success => 1 });
};

app->start;
