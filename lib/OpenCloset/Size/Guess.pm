package OpenCloset::Size::Guess;
# ABSTRACT: Driver-based API to guess proper body measurement

use Moo;
use Types::Standard qw( Object );

use Carp;
use Module::Runtime;
use Params::Util 0.14 ();
use Try::Tiny;

our $VERSION = '0.004';

has driver => (
    is      => 'ro',
    isa     => Object,
    handles => [qw( height weight gender )],
);

sub BUILDARGS {
    my ( $class, $driver_class, @args ) = @_;

    my $package = __PACKAGE__;

    unless ( defined $driver_class && !ref $driver_class && length $driver_class ) {
        Carp::croak("Did not provide a $package driver name");
    }
    unless ( Params::Util::_CLASS($driver_class) ) {
        Carp::croak("Not a valid $package driver name");
    }

    my $driver_name = $driver_class;
    $driver_class = "${package}::${driver_class}";
    try {
        Module::Runtime::require_module($driver_class);
    }
    catch {
        if (m/^Can't locate /) {
            # Driver does not exist
            Carp::croak("$package driver $driver_name does not exist, or is not installed");
        }
        else {
            # Fatal error within the driver itself
            # Pass on without change
            Carp::croak($_);
        }
    };
    unless ( $driver_class->can('new') ) {
        Carp::croak("$driver_class does not have new method");
    }
    my %public_args = @args;
    for my $key ( keys %public_args ) {
        next if $key eq 'height';
        next if $key eq 'weight';
        next if $key eq 'gender';

        delete $public_args{$key};
    }
    my $driver = $driver_class->new( %public_args, $class->_PRIVATE(@args) );
    unless ( $driver->can('does') && $driver->does("${package}::Role::Base") ) {
        Carp::croak("$driver_class does not have ${package}::Role::Base role");
    }

    return +{ driver => $driver };
}

sub guess {
    my $self = shift;

    my $rv = $self->driver->guess;

    Carp::croak("Driver did not return a result")
        unless Params::Util::_HASH($rv);

    Carp::croak("Driver returned an invalid \$result->{arm}")
        unless Params::Util::_SCALAR0( \$rv->{arm} );
    Carp::croak("Driver returned an invalid \$result->{belly}")
        unless Params::Util::_SCALAR0( \$rv->{belly} );
    Carp::croak("Driver returned an invalid \$result->{bust}")
        unless Params::Util::_SCALAR0( \$rv->{bust} );
    Carp::croak("Driver returned an invalid \$result->{foot}")
        unless Params::Util::_SCALAR0( \$rv->{foot} );
    Carp::croak("Driver returned an invalid \$result->{hip}")
        unless Params::Util::_SCALAR0( \$rv->{hip} );
    Carp::croak("Driver returned an invalid \$result->{knee}")
        unless Params::Util::_SCALAR0( \$rv->{knee} );
    Carp::croak("Driver returned an invalid \$result->{leg}")
        unless Params::Util::_SCALAR0( \$rv->{leg} );
    Carp::croak("Driver returned an invalid \$result->{thigh}")
        unless Params::Util::_SCALAR0( \$rv->{thigh} );
    Carp::croak("Driver returned an invalid \$result->{topbelly}")
        unless Params::Util::_SCALAR0( \$rv->{topbelly} );
    Carp::croak("Driver returned an invalid \$result->{waist}")
        unless Params::Util::_SCALAR0( \$rv->{waist} );

    return $rv;
}

# Filter params for only the private params
sub _PRIVATE {
    my $class  = ref $_[0] ? ref shift : shift;
    my @input  = @_;
    my @output = ();
    while (@input) {
        my $key   = shift @input;
        my $value = shift @input;
        if ( Params::Util::_STRING($key) and $key =~ /^_/ ) {
            $key =~ s/^_//;
            push @output, $key, $value;
        }
    }
    return @output;
}

1;

# COPYRIGHT

__END__

=for Pod::Coverage BUILDARGS

=head1 SYNOPSIS

    # Create a guesser
    my $guesser = OpenCloset::Size::Guess->new( 'Test',
        height => 172,
        weight => 72,
        gender => 'male',
    );

    # Or adjust after object creation
    my $guesser = OpenCloset::Size::Guess->new('Test');
    $guesser->height(172);
    $guesser->weight(72);
    $guesser->gender('male');

    # Guess the body measurement size
    my $result = $guesser->guess;

    # Get the information what you want.
    if ( $result ) {
        print "$result->{arm}\n";
        print "$result->{belly}\n";
        print "$result->{bust}\n";
        print "$result->{foot}\n";
        print "$result->{hip}\n";
        print "$result->{knee}\n";
        print "$result->{leg}\n";
        print "$result->{thigh}\n";
        print "$result->{topbelly}\n";
        print "$result->{waist}\n";
    }
    else {
        print "Failed to guess information\n";
    }


=head1 DESCRIPTION

C<OpenCloset::Size::Guess> is intended to provide a driver-based single API for
guessing body measurement size. The intent is to provide a single API against
which to write the code to guess the body measurement information.

C<OpenCloset::Size::Guess> drivers are installed separately.

The design of this module is almost stolen from L<SMS::Send>.


=attr height

=attr weight

=attr gender

=attr driver

Returns loaded driver object.
You can access attributes and methods of specific driver.

    $guesser = OpenCloset::Size::Guess->new( 'MyDriver',
        height    => 172,
        weight    => 72,
        gender    => 'male',
        _username => 'keedi',
        _password => 'keedi',
    );
    $guesser->driver->username; # NOT _username BUT username
    $guesser->driver->password; # NOT _password BUT password
    $guesser->driver->foo( $dummy1 );
    $guesser->driver->bar( $dummy2, $dummy3 );


=method new

    # The most basic guesser
    $guesser = OpenCloset::Size::Guess->new( 'Test',
        height => 172,
        weight => 72,
        gender => 'male',
    );

    # Pass arbitrary params to the driver
    $guesser = OpenCloset::Size::Guess->new( 'MyDriver',
        height    => 172,
        weight    => 72,
        gender    => 'male',
        _username => 'keedi',
        _password => 'keedi',
    );

The C<new> constructor creates a new size guesser.

It takes as its first parameter a driver name. These names map the class
names. For example driver "Test" matches the testing driver
L<OpenCloset::Size::Guess::Test>.

Any additional parameters should be key/value pairs, split into two types.

Parameters without a leading underscore are "public" options and relate to
standardized features within the L<OpenCloset::Size::Guess> API itself.
At this time, there are no usable public options.

Parameters B<with> a leading underscore are "private" driver-specific options
and will be passed through to the driver B<without> the underscore.

    $guesser = OpenCloset::Size::Guess->new( 'MyDriver',
        height    => 172,
        weight    => 72,
        gender    => 'male',
        _username => 'keedi',
        _password => 'keedi',
    );
    $guesser->driver->username; # NOT _username BUT username
    $guesser->driver->password; # NOT _password BUT password

Returns a new L<OpenCloset::Size::Guess> object, or dies on error.


=method guess

Returns C<HASHREF> which contains information of guessing the body size.

    my $guesser = OpenCloset::Size::Guess->new( 'Test',
        height => 172,
        weight => 72,
        gender => 'male',
    );
    my $info = $guesser->guess;
    print "$info->{from}\n";
    print "$info->{to}\n";
    print "$info->{result}\n";
    print "$_\n" for @{ $info->{htmls} };
    print "$_\n" for @{ $info->{descs} };

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


=head1 SEE ALSO

=for :list
* L<OpenCloset::Size::Guess::DB>
* L<OpenCloset::Size::Guess::BodyKit>
* L<SMS::Send>
* L<Parcel::Track>
