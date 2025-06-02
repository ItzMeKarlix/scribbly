use Dancer2;

set template => 'template_toolkit';

# Show login page
get '/' => sub {
    template 'index';
};

# Handle login submission
post '/login' => sub {
    my $username = body_parameters->get('username');
    my $password = body_parameters->get('password');

    if ($username eq 'admin' && $password eq '1234') {
        session user => $username;
        redirect '/workspace';
    } else {
        template 'index', { error => 'Invalid credentials' };
    }
};

# Show the workspace page
get '/workspace' => sub {
    if (!session('user')) {
        redirect '/';
    }
    template 'workspace', { user => session('user') };
};

start;
