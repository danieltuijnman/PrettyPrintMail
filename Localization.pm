package Mail::PrettyPrint::Localization;
use strict;
use warnings;

#
# (c) 2016, Daniel Tuijnman, Netherlands
#
# $Id: Localization.pm,v 1.6 2016/10/10 16:08:58 daniel Exp daniel $
#
# Module that keeps track of default locale and timezone
#
### TODO LIST
#  1. write documentation
#  2. 
#

=head1 NAME

Mail::PrettyPrint:Localization - default locale and timezone

=head1 SYNOPSIS

    use Mail::PrettyPrint::Localization
        qw/getDefaultLocale getDefaultTimezone
           setDefaultLocale setDefaultTimezone/;

    setDefaultLocale('nl_NL');
    setDefaultTimezone('Europe/Amsterdam');
    my $loc = getDefaultLocale();
    my $tz  = getDefaultTimezone()

=head1 DESCRIPTION

This module keeps track of default values for locale and timezone
for the other modules in the B<Mail::PrettyPrint> package.
It provides four getters, which are standard exported, and two setters, which
are not standard exported.

On loading the module, the defaults are set to the defaults from the
environment. The environment locale is taken from the environment variable
LC_TIME.

=head1 FUNCTIONS

=head2 GETTERS

=over

=item B<getDefaultLocale>()

returns the default locale as registered.

=item B<getDefaultTimezone>()

returns the default timezone as registered.

=item B<normLocale>( [LOCALE] )

returns a B<DateTime::Locale> object corresponding to the argument. The
argument may either be a Locale object itself, or a string. If the argument
is I<undef> or missing, the default locale is returned.

=item B<normTimezone>( [TIMEZONE] )

returns a B<DateTime::TimeZone> object corresponding to the argument. The
argument may either be a TimeZone object itself, or a string. If the argument
is I<undef or missing>, the default locale is returned.

=back

=head2 SETTERS

=over

=item B<setDefaultLocale>( [LOCALE] )

registers a new default locale. The argument can either be a
B<DateTime::Locale> object or the name of a known locale.
If the argument is omitted, it registers again the locale from the
environment.

=item B<setDefaultTimezone>( [TIMEZONE] )

registers a new default timezone. The argument can either be a
B<DateTime::TimeZone> object or the name of a known timezone.
If the argument is omitted, it registers again the timezone from the
environment.

=back

=head1 AUTHOR

(c) 2016 Daniel Tuijnman

=cut

use Carp;
use POSIX qw/setlocale LC_ALL LC_TIME/;
use Scalar::Util qw/blessed/;
use DateTime;
use DateTime::Locale;
use DateTime::TimeZone;

use base 'Exporter';
our @EXPORT    = qw/getDefaultLocale getDefaultTimezone
                    normLocale normTimezone/;
our @EXPORT_OK = qw/setDefaultLocale setDefaultTimezone/;

our $VERSION = v1.2.1;

#
# local values and defaults for locale and timezone
#
my $lc_env;
my $lc_default;
my $tz_env;
my $tz_default;


#
# GETTERS
#
sub getDefaultLocale() {
    $lc_default;
}

sub getDefaultTimezone() {
    $tz_default;
}

sub normLocale(;$) {
    if ( ! @_ ) {
        return $lc_default;
    }
    my $arg = shift;
    my $lc;
    if ( blessed $arg && $arg->isa('DateTime::Locale::Base') ) {
        $lc = $arg;
    } elsif ( ! ref $arg ) {
        eval { $lc = DateTime::Locale->load($arg); } ;
        if ( $@ ) {
            croak __PACKAGE__, "::normLocale: not a valid locale name: $arg\n";
        }
    } else {
        croak __PACKAGE__, "::normLocale: not a valid argument, type: ",
            ref $arg, "\n";
    }
    $lc;
}

sub normTimezone(;$) {
    if ( ! @_ ) {
        return $tz_default;
    }
    my $arg = shift;
    my $tz;
    if ( blessed $arg && $arg->isa('DateTime::TimeZone') ) {
        $tz = $arg;
    } elsif ( ! ref $arg ) {
        eval { $tz = DateTime::TimeZone->new( name => $arg ); };
        if ( $@ ) {
            croak __PACKAGE__,
                "::normTimezone: not a valid timezone name: $arg\n";
        }
    } else {
        croak __PACKAGE__, "::normTimezone: not a valid argument\n";
    }
    $tz;
}

#
# SETTERS
#
sub setDefaultLocale(;$) {
    if ( ! @_ ) {
        $lc_default = $lc_env;
    } else {
        my $arg = shift;
        if ( blessed $arg ) {
            if ( ! $arg->isa('DateTime::Locale') ) {
                croak __PACKAGE__, "::setDefaultLocale: not a locale object\n";
            }
            $lc_default = $arg;
        } else {
            my $lc;
            eval { $lc = DateTime::Locale->load($arg); };
            if ( $@ ) {
                croak __PACKAGE__,
                    "::setDefaultLocale: not a valid locale name: $arg\n";
            }
            $lc_default = $lc;
        }
    }
    $lc_default;
}

sub setDefaultTimezone(;$) {
    if ( ! @_ ) {
        $tz_default = $tz_env;
    } else {
        my $arg = shift;
        if ( blessed $arg ) {
            if ( ! $arg->isa('DateTime::TimeZone') ) {
                croak __PACKAGE__,
                    "::setDefaultTimezone: not a timezone object\n";
            }
            $tz_default = $arg;
        } else {
            my $tz;
            eval { $tz = DateTime::TimeZone->new( name => $arg ); };
            if ( $@ ) {
                croak __PACKAGE__,
                    "::setDefaultTimezone: not a valid timezone name: $arg\n";
            }
            $tz_default = $tz;
        }
    }
    $tz_default;
}

#
# INITIALIZATION
#

BEGIN {
    setDefaultLocale(setlocale(LC_TIME));
    $lc_env = $lc_default;
    setDefaultTimezone('local');
    $tz_env = $tz_default;
}

1;

