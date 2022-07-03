package Mail::PrettyPrint::BoxMessage;
use strict;
use warnings;

#
# (c) 2016, Daniel Tuijnman, Netherlands
#
# $Id: BoxMessage.pm,v 1.2 2016/10/10 16:08:58 daniel Exp daniel $
#
# Module that encapsulates a Mail::Message and enriches it with locale,
# timezone and folder reference
#
### TODO LIST
#  2. 
#

=head1 NAME

Mail::PrettyPrint::BoxMessage - email message for use in pretty printing

=head1 SYNOPSIS

    my $mail = # some Mail::Box::Message object
    my $fmt  = Mail::PrettyPrint::Format->new('%d-%m-%y_@_{0}n_@F');
    my $msg  = Mail::PrettyPrint::BoxMessage->new(
        msg => $mail, locale => 'nl', timezone => 'Europe/Amsterdam'
    );
    print $msg->format($fmt);    

=head1 DESCRIPTION

This module defines localized email messages which belong to a email folder.
It is a subclass of B<Mail::PrettyPrint::Message>.

=head1 CONSTRUCTOR

The constructor is called with a hash of arguments:

=over

=item I<msg>: a B<Mail::Box::Message> object containing a email message, or
another B<Mail::PrettyPrint::BoxMessage> object

=item I<locale>: a B<DateTime::Locale> object or the name of a locale

=item I<timezone>: a B<DateTime> object of the name of a timezone

=item I<box>: the email folder the email message belongs to, either a
B<Mail::Box> object or a B<Mail::PrettyPrint::Box> object.

=back

The arguemnt I<msg> is required, the other three are optional. If the locale
and/or the timezone is missing, the default from the
B<Mail::PrettyPrint::Localization> module is used. If the I<box> argument is
supplied, it is only used to check that the message really belongs to that
email folder: the email message itself already must contain a reference to
an email folder.

The constructor can also be called with the email message as its only
argument.

If necessary, the constructor will create a B<Mail::PrettyPrint::Box> object
for the mail folder with the requested locale and timezone.

=head1 METHODS

=head2 ACCESSOR METHODS

=over

=item B<getBox> retrieves the B<Mail::PrettyPrint::Box> email box the email
belongs to

=item B<getFolder> retrieves the B<Mail::Box> email folder the email belongs
to.

=back

=head2 FORMATTING METHODS

=over

=item B<format>( FMT )

The implementation of B<format> in this class checks if the evaluation of
the format string has already been cached in the associated email box.

=item B<getDaySerial>, B<getDayCount>, B<getBoxSerial>, B<getBoxCount>

These methods which implement the formatting codes I<@n>, I<@N>, I<@o>, and
I<@O> respectively, are properly implemented.

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
use Mail::Message;
use Mail::PrettyPrint::Localization;
use Mail::PrettyPrint::Format;
use Mail::PrettyPrint::Box;

use base 'Mail::PrettyPrint::Message';

our $VERSION = v1.2.1;

#
# A Mail::PrettyPrint::Mail object has attributes:
# Inherited from Mail::PrettyPrint::Message:
# - msg         a Mail::Message object
# - locale      a DateTime::Locale object
# - timezone    a DateTime::TimeZone object
# Optional arguments for new:
# - box         a Mail::PrettyPrint::Box
#

#
# CONSTRUCTOR
#
# The 'msg' attribute must be a Mail::Box::Message
#
# The constructor has an optional 'box' argument which may be either:
# 1) a Mail::Box object
# 2) a Mail::PrettyPrint::Box object
# If the 'box' argument is present, it will only be used to check that the
# message really belongs to that box
#

sub init(@) {
    my $self = shift;
    my %args = @_;
    $self->SUPER::init(@_);
    if ( ! $self->{msg}->isa('Mail::Box::Message') ) {
        croak __PACKAGE__, "::init: message does not belong to a folder\n";
    }
    my $folder = $self->getFolder();
    my $lc = $self->getLocale();
    my $tz = $self->getTimezone();

    my $box;
    if ( exists $args{box} ) {
        # if the box argument is supplied, we only check that it is the
        # correct email folder the message belongs to
        $box = $args{box};
        if ( blessed $box && $box->isa('Mail::Box') ) {
            if ( $box == $folder ) {
                $box = Mail::PrettyPrint::Box->new(
                    folder => $folder, locale => $lc, timezone => $tz
                );
            } else {
                croak __PACKAGE__, "::init: box is wrong folder\n";
            }
        } elsif ( blessed $box && $box->isa('Mail::PrettyPrint::Box') ) {
            if ( $box->getFolder() != $folder ) {
                croak __PACKAGE__, "::init: box is wrong folder\n";
            }
            if ( $box->getLocale()->id() ne $self->getLocale()->id() ) {
                croak __PACKAGE__, "::init: box has wrong locale\n";
            }
            if ( DateTime->compare(
                    $box->getTimezone(), $self->getTimezone() ) ) {
                croak __PACKAGE__, "::init: box has wrong timezone\n";
            }
        } else {
            croak __PACKAGE__, "::init: box: not a mail folder\n";
        }
    } else {
        $box = Mail::PrettyPrint::Box->new(
            folder => $folder, locale => $lc, timezone => $tz
        );
    }
    $self->{box} = $box;
    $self;
}

#
# ACCESSORS
#
sub getBox() {
    (shift)->{box};
}

#
# FORWARDING METHODS for Mail::Box::Message
#
sub getFolder() {
    (shift)->{msg}->folder();
}

#
# ACCESSOR METHODS for Format
#

sub getDaySerial() {
    my $self = shift;
    print STDERR "BoxMessage::getDaySerial called\n" if $main::debug & 2;
    my $box  = $self->getBox();
    $box->getDaySerial($self->{msg});
}

sub getDayCount() {
    my $self = shift;
    print STDERR "BoxMessage::getDayCount called\n" if $main::debug & 2;
    my $box  = $self->getBox();
    $box->getDayCount($self->{msg});
}

sub getBoxSerial() {
    my $self = shift;
    my $box  = $self->getBox();
    $box->getBoxSerial($self->{msg});
}

sub getBoxCount() {
    my $self = shift;
    my $box  = $self->getBox();
    $box->getBoxCount();
}


#
# FORMATTING
#

sub format($) {
    my $self = shift;
    my $fmt  = shift;
    my $fmtobj;
    if ( ! ref $fmt ) {
        $fmtobj = Mail::PrettyPrint::Format->new( $fmt );
    } elsif ( blessed $fmt && $fmt->isa('Mail::PrettyPrint::Format') ) {
        $fmtobj = $fmt;
    } else {
        croak __PACKAGE__, "::format: not a format\n";
    }
    my $box = $self->getBox();
    my $str = $box->formatInCache($fmtobj, $self->getMessage());
    defined $str ? $str : $fmtobj->basicFormat($self);
}

1;

