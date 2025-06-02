package Scribbly;
use Dancer2;

get '/' => sub {
    template 'index';
};

1;
