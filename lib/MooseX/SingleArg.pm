package MooseX::SingleArg;
{
  $MooseX::SingleArg::VERSION = '0.01';
}
use Moose ();
use Moose::Exporter;

=head1 NAME

MooseX::SingleArg - No-fuss instantiation of Moose objects using a single argument.

=head1 SYNOPSIS

Use this module in your class:

    package Person;
    use Moose;
    
    use MooseX::SingleArg;
    
    single_arg 'name';
    
    has name => ( is=>'ro', isa=>'Str' );

Then instantiate a new instance of your class with a single argument:

    my $john = Person->new( 'John Doe' );
    print $john->name();

=head1 DESCRIPTION

This module provides a role and declarative sugar for allowing Moose instances
to be constructed with a single argument.  Your class must use this module and
then use the single_arg method to declare which of the class's attributes will
be assigned the single argument value.

If the class is constructure using the typical argument list name/value pairs,
or with a hashref, then things work as is usual.  But, if the arguments are a
single non-hashref value then that argument will be assigned to whatever
attribute you have declared.

The reason for this module's existence is that when people want this feature
they usually find L<Moose::Cookbook::Basics::Recipe10> which asks that something
like the following be written:

    around BUILDARGS => sub{
        my $orig = shift;
        my $self = shift;
        
        if (@_==1 and ref($_[0]) ne 'HASH') {
            return $self->$orig( foo => $_[0] );
        }
        
        return $self->$orig( @_ );
    };

The above is complex boilerplate for a simple feature.  This module aims to make
it simple and fool-proof to support single-argument Moose object construction.

=cut

use Carp qw( croak );

Moose::Exporter->setup_import_methods(
    with_meta => [ 'single_arg' ],
);

sub single_arg {
    my ($meta, $arg) = @_;
    my $class = $meta->name();
    croak "A single arg has already been declared for $class" if $class->_has_single_arg();
    $class->_single_arg( $arg );
    return;
}

sub init_meta {
    shift;
    my %args = @_;

    Moose->init_meta( %args );

    my $class = $args{for_class};

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $class,
        roles => [ 'MooseX::SingleArg::Role' ],
    );

    return $class->meta();
}

{
    package MooseX::SingleArg::Role;
{
  $MooseX::SingleArg::Role::VERSION = '0.01';
}
    use Moose::Role;

    use MooseX::ClassAttribute;

    class_has _single_arg => (
        is        => 'rw',
        isa       => 'Str',
        predicate => '_has_single_arg',
    );

    around BUILDARGS => sub{
        my $orig = shift;
        my $self = shift;

        if (@_==1 and ref($_[0]) ne 'HASH') {
            return $self->$orig( $self->_single_arg() => $_[0] );
        }

        return $self->$orig( @_ );
    };
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

