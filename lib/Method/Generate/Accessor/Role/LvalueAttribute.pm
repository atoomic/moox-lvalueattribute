package Method::Generate::Accessor::Role::LvalueAttribute;
use strictures 1;

# ABSTRACT: Provides Lvalue accessors to Moo class attributes

use Moo::Role;
use Variable::Magic qw(wizard cast);
use Class::Method::Modifiers qw(install_modifier);
use Hash::Util::FieldHash::Compat qw(fieldhash idhash register id);
use Scalar::Util q/weaken/;

after generate_method => sub {
    my $self = shift;
    my ($into, $name, $spec, $quote_opts) = @_;

    return if !$spec->{lvalue};

    my $reader = $spec->{reader} || $spec->{accessor}
        or die "lvalue was set but no accessor nor reader";
    my $writer = $spec->{writer} || $spec->{accessor}
        or die "lvalue was set but no accessor nor writer";

    my $read_code = $into->can($reader);
    my $write_code = $into->can($writer);

    my $wiz = wizard(
        data => sub { $_[1] },
        get  => sub { ${$_[0]} = $_[1]->$read_code; 1 },
        set  => sub { 
            # return unless defined $_[1];
            # return unless defined $_[0];
            # #use Test::More; note explain \@_;
            $_[1]->$write_code( ${$_[0]} ); 1 
        },
    );

    #fieldhash my %cast;
    #idhash my %cast;
    my %cast;

    foreach my $method (grep defined, map $spec->{$_}, qw(writer accessor)) {
        install_modifier($into, 'around', $method, sub :lvalue {
            my $orig = shift;
            my $self = shift;
            my $val;
            $val = $self->$orig(@_) if @_;
            if (!exists $cast{$self}) {
                cast $cast{ $self }, $wiz, $self;
            }

            return $cast{ $self };
        });
    }

   my $original = $into->can( "DESTROY" );

   {
        no strict 'refs';
        no warnings "redefine";
        my $destroy = $into . "::DESTROY";
        *$destroy = sub {
            my ( $self ) = @_;

            my $current = "$self";

            if ( $original ) {
                $original->( $self );    
            }
            
            my %new;
            foreach my $k ( keys %cast ) {
                next unless $k eq $current;
                $new{ $k } = $cast{ $k };
            }

            undef %cast;
            %cast = %new;

        };
   }

    return;
};

1;
