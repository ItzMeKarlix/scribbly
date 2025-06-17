package SecurityQuestions;
use strict;
use warnings;
use JSON;
use File::Slurp;

my $json_file = 'security_questions.json';

# List of available security questions
sub available_questions {
    return [
        'What is the name of your first pet?',
        'What is your mother\'s maiden name?',
        'What was the name of your elementary school?',
        'What is your favorite food?',
        'What city were you born in?',
        'What is your favorite color?',
        'What is your father\'s middle name?',
        'What was your childhood nickname?',
        'What is the name of your favorite teacher?',
        'What is your favorite movie?'
    ];
}

# Save user's security questions and answers
sub save_user_security {
    my ($username, $questions, $answers) = @_;
    my $data = {};
    if (-e $json_file) {
        $data = decode_json(read_file($json_file));
    }
    $data->{$username} = {
        questions => $questions,
        answers   => $answers,
    };
    write_file($json_file, encode_json($data));
    return 1;
}

# Get user's security questions
sub get_user_questions {
    my ($username) = @_;
    return unless -e $json_file;
    my $data = decode_json(read_file($json_file));
    return $data->{$username}{questions};
}

# Validate user's answers
sub validate_user_answers {
    my ($username, $user_answers) = @_;
    return 0 unless -e $json_file;
    my $data = decode_json(read_file($json_file));
    my $stored = $data->{$username};
    return 0 unless $stored;
    my $correct = $stored->{answers};
    # Only check the first answer
    return 0 unless defined $user_answers->[0] && defined $correct->[0];
    return lc($user_answers->[0]) eq lc($correct->[0]) ? 1 : 0;
}

1;
