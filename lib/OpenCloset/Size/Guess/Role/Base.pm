package OpenCloset::Size::Guess::Role::Base;
# ABSTRACT: OpenCloset::Size::Guess base role

use Moo::Role;
use Types::Standard qw( Enum Int );

our $VERSION = '0.004';

has height => ( is => 'rw', isa => Int );
has weight => ( is => 'rw', isa => Int );
has gender => ( is => 'rw', isa => Enum [qw( male female )] );

requires 'guess';

1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

    package OpenCloset::Size::Guess::MyDriver;

    use Moo;

    with 'OpenCloset::Size::Guess::Role::Base';

    sub guess {
        ...
    }


=head1 DESCRIPTION

The C<OpenCloset::Size::Guess::Role::Base> class provides an abstract
base class for all L<OpenCloset::Size::Guess> driver classes.

At this time it does not provide any implementation code for drivers
(although this may change in the future).
It does serve as something you should sub-class your driver from
to identify it as a L<OpenCloset::Size::Guess> driver.

Please note that if your driver class not B<not> return true for
C<$driver->does('OpenCloset::Size::Guess::Role::Base')> then the
L<OpenCloset::Size::Guess> constructor will refuse to use your class
as a driver.


=attr height

=attr weight

=attr gender


=method guess

Returns C<HASHREF> which contains information of body measurement size.
C<HASHREF> MUST contain following key and value pairs.

=for :list
* C<arm>: C<SCALAR>.
* C<belly>: C<SCALAR>.
* C<bust>: C<SCALAR>.
* C<foot>: C<SCALAR>.
* C<hip>: C<SCALAR>.
* C<knee>: C<SCALAR>.
* C<leg>: C<SCALAR>.
* C<thigh>: C<SCALAR>.
* C<topbelly>: C<SCALAR>.
* C<waist>: C<SCALAR>.
