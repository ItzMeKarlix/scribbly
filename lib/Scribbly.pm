package Scribbly;
use Dancer2;

get '/' => sub {
    send_file('index.html', system_path => 0);  # load views/index.html
};

true;  # must return true at the end of any module
