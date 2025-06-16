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
    $c->render(template => 'protected/workspace');
};

get '/dashboard' => sub {
    my $c = shift;
    return $c->redirect_to('/login') unless $c->session('user_id');
    $c->render(template => 'protected/dashboard');
};

app->start;
