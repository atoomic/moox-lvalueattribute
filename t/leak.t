#!/bin/env perl

{

    package T;

    use Moo;
    use MooX::Types::MooseLike::Base qw( :all );
    use MooX::LvalueAttribute;
    use Test::More;

    has objName => (
        'is'  => 'rw',
        'isa' => Str,
    );
    has num => (
        'is'      => 'rw',
        'isa'     => Int,
        'default' => 0,
        'lvalue'  => 1,
    );

    sub DESTROY {
        my $self = shift;

        is ${^GLOBAL_PHASE}, 'RUN',
          "destruction of " . $self->objName . " happening at RUN time";

        undef $self;

        return;
    }

    __PACKAGE__->meta->make_immutable;

    1;
}

package main;

use strictures 1;
use Test::More tests => 33;

use T;

my $t;

END {
    note "GLOBAL DESTRUCTION";
}

sub run {

    $t = T->new( objName => 'item 1' );
    $t = T->new( objName => 'item 2' );
    $t = T->new( objName => 'item 3' );
    $t->num++;
    is $t->num, 1, "num = 1";
    $t = T->new( objName => 'item 4' );
    $t = T->new( objName => 'item 5' );
    $t->num(7);
    is $t->num, 7, "num = 7";
    $t = T->new( objName => 'item 6', num => 6 );
    $t->num(12);
    $t = T->new( objName => 'item 7', num => 6 );
    $t->num += 3;

    $t = T->new( objName => 'item 8' );
    undef $t;
    note "Just undefed item 8; should have seen a destroy\n";

    return;
}

run();

undef($t);

{
    # checking conflicts between two objects
    my $x = T->new( objName => 'item X' );
    my $y = T->new( objName => 'item Y' );

    $x->num += 10;
    $y->num += 5;
    is $x->num, 10, 'x = 10';
    is $y->num, 5,  'y = 5';

    undef $x;
    $y->num += 3;
    is $y->num, 8, 'y = 8';

}

$t = T->new( objName => 'item 9' );
$t->num++;
is $t->num, 1, 'num = 1';
$t->DESTROY;
undef($t);

note "Just undefed item 9; should have seen a destroy\n";

for ( my $i = 1; $i <= 3; $i++ ) {
    note "loop i=$i\n";
    my $t1 = T->new( objName => "A$i" );
    $t1->DESTROY;
}

for ( my $j = 1; $j <= 3; $j++ ) {
    note "loop j=$j\n";
    my $t2 = T->new( objName => "B$j" );
    $t2->num++;
    is $t2->num, 1, 'num = 1';
    $t2->DESTROY;

    #undef($t2);
}

undef $t;

