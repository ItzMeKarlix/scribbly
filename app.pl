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
    require SecurityQuestions;
    my $questions = SecurityQuestions::available_questions();
    $c->stash(security_questions => $questions);
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

    # Save security question and answer (only 1)
    my $question = $c->param('security_question_1');
    my $answer   = $c->param('security_answer_1');
    require SecurityQuestions;
    SecurityQuestions::save_user_security($username, [$question], [$answer]);

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

get '/searchuser' => sub {
    my $c = shift;
    $c->render(template => 'auth/forgotpass/searchuser');
};

post '/searchuser' => sub {
    my $c = shift;
    my $username = $c->param('username');
    if (!Model::user_exists($username)) {
        $c->flash(error => 'There is no account found.');
        return $c->redirect_to('/searchuser');
    }
    $c->stash(username => $username);
    $c->redirect_to('/forgotpassword?username=' . $username);
};

get '/forgotpassword' => sub {
    my $c = shift;
    require SecurityQuestions;
    my $username = $c->param('username');
    my $questions = SecurityQuestions::get_user_questions($username);
    $c->stash(username => $username, user_questions => $questions);
    $c->render(template => 'auth/forgotpass/forgotpassword');
};

post '/forgotpassword' => sub {
    my $c = shift;
    require SecurityQuestions;
    my $username = $c->param('username');
    my $user_answer = $c->param('security_answer_1');
    $username ||= $c->stash('username') || $c->param('user');
    unless ($username) {
        $c->flash(error => 'No username provided.');
        return $c->redirect_to('/searchuser');
    }
    # Validate answer (only 1)
    if (SecurityQuestions::validate_user_answers($username, [$user_answer])) {
        $c->redirect_to('/changepass?username=' . $username);
    } else {
        $c->flash(error => 'Incorrect answer. Please try again.');
        $c->redirect_to('/forgotpassword?username=' . $username);
    }
};

get '/changepass' => sub {
    my $c = shift;
    my $username = $c->param('username');
    $c->stash(username => $username);
    $c->render(template => 'auth/forgotpass/changepass');
};

post '/changepass' => sub {
    my $c = shift;
    my $username = $c->param('username');
    my $new_password = $c->param('new_password');
    my $confirm_password = $c->param('confirm_password');
    unless ($new_password && $confirm_password && $new_password eq $confirm_password) {
        $c->flash(error => 'Passwords do not match.');
        return $c->redirect_to('/changepass?username=' . $username);
    }
    unless ($new_password =~ /^(?=.*[A-Z])[A-Za-z0-9]+$/) {
        $c->flash(error => 'Password must be alphanumeric and contain at least one capital letter.');
        return $c->redirect_to('/changepass?username=' . $username);
    }
    my $hashed = Digest::SHA::sha1_hex($new_password);
    my $dbh = Model::connect();
    $dbh->do('UPDATE users SET password = ? WHERE username = ?', undef, $hashed, $username);
    $c->flash(error => 'Password changed successfully. Please log in.');
    $c->redirect_to('/login');
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


    if (defined $note_id && $note_id eq 'new') {
        $note_title = '';
        $note_content = '';
        $c->session(last_note_id => undef);
    } else {

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
    require SecurityQuestions;
    my $questions = SecurityQuestions::available_questions();
    $c->render(template => 'protected/workspace', username => $username, note_title => $note_title, note_content => $note_content, security_questions => $questions);
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

    $c->session(last_note_id => undef);
    require SecurityQuestions;
    my $questions = SecurityQuestions::available_questions();
    $c->render(template => 'protected/workspace', username => $username, note_title => '', note_content => '', security_questions => $questions);
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
    require SecurityQuestions;
    my $questions = SecurityQuestions::available_questions();
    $c->render(template => 'protected/dashboard', username => $username, notes => $notes, security_questions => $questions);
};

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

get '/trash' => sub {
    my $c = shift;
    $c->res->headers->cache_control('no-store, no-cache, must-revalidate, max-age=0');
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->res->headers->expires(0);

    return $c->redirect_to('/login') unless $c->session('user_id');
    my $user_id = $c->session('user_id');

    my $dbh = Model::connect();

    # Get username
    my $user_sth = $dbh->prepare("SELECT username FROM users WHERE id = ?");
    $user_sth->execute($user_id);
    my ($username) = $user_sth->fetchrow_array;

    # Get trashed notes
    my $trash_sth = $dbh->prepare('
        SELECT id, title, content, deleted_at, original_updated_at
        FROM trash
        WHERE user_id = ?
        ORDER BY deleted_at DESC
    ');
    $trash_sth->execute($user_id);
    my $trashed_notes = $trash_sth->fetchall_arrayref({});

    # Render the trash view with trashed notes
    $c->render(template => 'protected/trash', username => $username, trashed_notes => $trashed_notes);
};


post '/delete-note' => sub {
  my $c = shift;

  my $user_id = $c->session('user_id');
  my $id = $c->param('id');

  return $c->redirect_to('/login') unless $user_id;

  # Fetch the note
  my $sth = $c->db->prepare('SELECT * FROM notes WHERE id = ? AND user_id = ?');
  $sth->execute($id, $user_id);
  my $note = $sth->fetchrow_hashref;

  unless ($note) {
    $c->flash(error => 'Note not found.');
    return $c->redirect_to('/dashboard');
  }

  # Insert into trash
  my $insert = $c->db->prepare('INSERT INTO trash (user_id, note_id, title, content, deleted_at, original_updated_at) VALUES (?, ?, ?, ?, datetime("now"), ?)');
  $insert->execute($user_id, $note->{id}, $note->{title}, $note->{content}, $note->{updated_at});

  # Delete from notes
  my $delete = $c->db->prepare('DELETE FROM notes WHERE id = ? AND user_id = ?');
  $delete->execute($id, $user_id);

  $c->flash(message => 'Note moved to trash.');
  return $c->redirect_to('/dashboard');
};


post '/delete-all-notes' => sub {
  my $c = shift;

  my $user_id = $c->session('user_id');
  return $c->redirect_to('/login') unless $user_id;

  # Fetch all notes
  my $sth = $c->db->prepare('SELECT * FROM notes WHERE user_id = ?');
  $sth->execute($user_id);
  my $notes = $sth->fetchall_arrayref({});

  unless (@$notes) {
    $c->flash(error => 'No notes to delete.');
    return $c->redirect_to('/dashboard');
  }

  # Insert each note into trash
  my $insert = $c->db->prepare('INSERT INTO trash (user_id, note_id, title, content, deleted_at, original_updated_at) VALUES (?, ?, ?, ?, datetime("now"), ?)');
  for my $note (@$notes) {
    $insert->execute($user_id, $note->{id}, $note->{title}, $note->{content}, $note->{updated_at});
  }

  # Delete all notes
  my $delete = $c->db->prepare('DELETE FROM notes WHERE user_id = ?');
  $delete->execute($user_id);

  $c->flash(message => 'All notes moved to trash.');
  return $c->redirect_to('/dashboard');
};

# Restore a single note from trash
post '/restore-note' => sub {
    my $c        = shift;
    my $user_id  = $c->session('user_id') // return $c->redirect_to('/login');
    my $note_id  = $c->param('id');

    my $dbh = Model::connect();

    # Fetch trashed note
    my $sth = $dbh->prepare('SELECT * FROM trash WHERE id = ? AND user_id = ?');
    $sth->execute($note_id, $user_id);
    my $note = $sth->fetchrow_hashref;

    unless ($note) {
        return $c->redirect_to('/trash');
    }

    # Insert back to notes
    my $insert = $dbh->prepare('
        INSERT INTO notes (user_id, title, content, updated_at)
        VALUES (?, ?, ?, ?)
    ');
    $insert->execute($user_id, $note->{title}, $note->{content}, $note->{original_updated_at});

    # Delete from trash
    $dbh->do('DELETE FROM trash WHERE id = ? AND user_id = ?', undef, $note_id, $user_id);

    return $c->redirect_to('/trash');
};

# Permanently delete a single trashed note
post '/delete-forever' => sub {
    my $c       = shift;
    my $user_id = $c->session('user_id') // return $c->redirect_to('/login');
    my $note_id = $c->param('id');

    my $dbh = Model::connect();

    # Just delete from trash
    $dbh->do('DELETE FROM trash WHERE id = ? AND user_id = ?', undef, $note_id, $user_id);

    return $c->redirect_to('/trash');
};

# Restore all notes from trash
post '/restore-all-notes' => sub {
    my $c       = shift;
    my $user_id = $c->session('user_id') // return $c->redirect_to('/login');

    my $dbh = Model::connect();

    # Fetch all trash
    my $sth = $dbh->prepare('SELECT * FROM trash WHERE user_id = ?');
    $sth->execute($user_id);
    my $trashed_notes = $sth->fetchall_arrayref({});

    # Reinsert into notes
    my $insert = $dbh->prepare('
        INSERT INTO notes (user_id, title, content, updated_at)
        VALUES (?, ?, ?, ?)
    ');
    foreach my $note (@$trashed_notes) {
        $insert->execute($user_id, $note->{title}, $note->{content}, $note->{original_updated_at});
    }

    # Clear trash
    $dbh->do('DELETE FROM trash WHERE user_id = ?', undef, $user_id);

    return $c->redirect_to('/trash');
};

# Permanently delete all trashed notes
post '/delete-all-trashed-notes' => sub {
    my $c       = shift;
    my $user_id = $c->session('user_id') // return $c->redirect_to('/login');

    my $dbh = Model::connect();

    # Delete all trash for this user
    $dbh->do('DELETE FROM trash WHERE user_id = ?', undef, $user_id);

    return $c->redirect_to('/trash');
};




sub cleanup_trash {
  my $c = shift;
  $c->db->delete('trash', \["deleted_at < NOW() - INTERVAL '7 days'"]);
}

app->start;
