package Routes;
use strict;
use warnings;
use Mojolicious::Lite;
use Digest::SHA qw(sha1_hex);
use Model;

sub routes {
    my $app = shift;

    my $r = $app->routes;

    $r->get('/')->to(cb => sub {
        my $c = shift;
        return $c->redirect_to('/login');
    });

    $r->get('/register')->to(cb => sub {
        my $c = shift;
        $c->render(template => 'register');
    });

    $r->post('/register')->to(cb => sub {
        my $c = shift;
        my $username = $c->param('username');
        my $password = sha1_hex($c->param('password'));

        if (Model::user_exists($username)) {
            return $c->render(text => 'User already exists.');
        }

        Model::create_user($username, $password);
        $c->redirect_to('/login');
    });

    $r->get('/login')->to(cb => sub {
        my $c = shift;
        $c->render(template => 'login');
    });

    $r->post('/login')->to(cb => sub {
        my $c = shift;
        my $username = $c->param('username');
        my $password = sha1_hex($c->param('password'));

        my $user = Model::validate_login($username, $password);
        if ($user) {
            $c->session(user_id => $user->{id});
            $c->redirect_to('/dashboard');
        } else {
            $c->render(text => 'Invalid credentials.');
        }
    });

    $r->get('/searchuser')->to(cb => sub {
        my $c = shift;
        $c->render(template => 'searchuser');
    });

    $r->get('/dashboard')->to(cb => sub {
        my $c = shift;
        return $c->redirect_to('/login') unless $c->session('user_id');
        $c->render(template => 'dashboard');
    });

    $r->get('/logout')->to(cb => sub {
        my $c = shift;
        $c->session(expires => 1);
        $c->redirect_to('/login');
    });

    $r->get('/dashboard')->to(cb => sub {
        my $c = shift;
        return $c->redirect_to('/login') unless $c->session('user_id');
        $c->render(template => 'dashboard');
    });
}

1;
