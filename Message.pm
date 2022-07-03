package Mail::PrettyPrint::Message;
use strict;
use warnings;

#
# (c) 2016, Daniel Tuijnman, Netherlands
#
# $Id: Message.pm,v 1.3 2016/10/10 16:08:58 daniel Exp daniel $
#
# Module that encapsulates a Mail::Message and enriches it with locale
# and timezone information
#
### TODO LIST
#  3. 
#

=head1 NAME

Mail::PrettyPrint::Message - email message for use in pretty printing

=head1 SYNOPSIS

    my $mail = # some Mail::Message object
    my $fmt  = Mail::PrettyPrint::Format->new('%d-%m-%y_@F');
    my $msg1 = Mail::PrettyPrint::Message->new($mail);
    my $msg2 = Mail::PrettyPrint::Message->new(
        msg => $mail, locale => 'nl', timezone => 'Europe/Amsterdam'
    );
    print $fmt->format($msg1);
    print $msg2->format($fmt);

=head1 DESCRIPTION

This module defines localized email messages. An object contains a reference
to a B<Mail::Message> object holding the actual email message, as well as
I<locale> and I<timezone> attributes.

=head1 CONSTRUCTOR

The constructor is called with a hash of arguments:

=over

=item I<msg>: a B<Mail::Message> object containing an email message, or
another B<Mail::PrettyPrint::Message> object

=item I<locale>: a B<DateTime::Locale> object or the name of a locale

=item I<timezone>: a B<DateTime> object of the name of a timezone

=back

The argument I<msg> is required, the other two are optional. If the locale
and/or the timezone is missing, the default locale resp. timezone as
administered by B<Mail::PrettyPrint::Localization> is used.

If the I<msg> argument is another B<Mail::PrettyPrint::Message> object,
a shallow copy of that object is made; the locale and timezone arguments
override the copy if they are supplied.

The constructor can also be called with the email message as
its only argument.

=over

=item B<copy>( SRC )

Copy constructor. Makes a shallow copy of its argument.

=back

=head1 METHODS

=head2 ACCESSOR METHODS

The module provides the following accessor methods:

=over

=item B<getMessage>: gives the email message of class B<Mail::Message>

=item B<getLocale>: gives the locale of the object

=item B<getTimezone>: gives the time zone of the object

=back

=head2 FORMATTING METHODS

The module provides the following methods for formatting an email message:

=over

=item B<format>( FMT )

This method evaluates the given format. The argument can either be a string
or a B<Mail::PrettyPrint::Format> object. If the argument is an invalid
format string, the method dies. If the format contains formatting codes that
cannot be evaluated for a simple message, the method also dies.

=item B<getTimestamp>

This method gives the timestamp of the message as a B<DateTime> object.

=item B<getDaySerial>, B<getDayCount>, B<getBoxSerial>, B<getBoxCount>

Basic implementation of methods used for evaluating a format. As they can
only be calculated for messages that belong in an email folder, they die.

=item B<getPageNumber>, B<getPageCount>

Basic implementation of methods used for evaluating a format. As they can
only be calculated for a message with an associated document, they die.

=back

=head2 FORWARDING METHODS to Mail::Message

All methods from B<Mail::Message> are made available by forwarding any
unknown method call to the message attribute.

=head1 AUTHOR

(c) 2016 Daniel Tuijnman

=cut

use Carp;
use Scalar::Util qw/blessed/;
use Mail::Message;
use Mail::PrettyPrint::Localization;
use Mail::PrettyPrint::Format;

our $VERSION = v1.2.1;

#
# A Mail::PrettyPrint::Message object has attributes:
# Required arguments for new:
# - msg         a Mail::Message object
# Optional arguments for new:
# - locale      a DateTime::Locale object
# - timezone    a DateTime::TimeZone object
#

#
# CONSTRUCTORS
#

#
# Method: new
# Arguments:
#   1) A hash of named arguments:
#      * msg: a Mail::Message object or a Mail::PrettyPrint::Message object
#      * locale
#      * timezone
#   2) Only the value of of the 'msg' argument
# Returns: a new Mail::PP::Message object
# Description:
#   'new' creates a wrapper around a Mail::Message object.
#   In case the 'msg' argument is itself a Mail::PrettyPrint::Message
#   object, it creates a wrapper around the Mail::Message object contained
#   therein.
#
sub new() {
    my $class = shift;
    my $self  = bless {}, $class;
    # simple sanity check
    die __PACKAGE__, "::new: no arguments given\n" if ! @_;
    # and so we can call new() with just an email message and nothing else:
    unshift @_, "msg" if @_ == 1;
    $self->init(@_);
}

#
# Method: init
# Arguments:
#   a hash of named arguments, see new()
# Returns: the newly initialized Mail::PP::Message object
# Description:
#   Initializes the contents of the object
#
sub init(@) {
    my $self = shift;
    my %args = @_;
    if ( ! exists $args{msg} ) {
        croak __PACKAGE__, "::init: no mail message given\n";
    }
    my $msg = $args{msg};
    if ( blessed $msg && $msg->isa('Mail::Message') ) {
        $self->{msg}      = $msg;
        $self->{locale}   = normLocale($args{locale});
        $self->{timezone} = normTimezone($args{timezone});
    } elsif ( blessed $msg && $msg->isa('Mail::PrettyPrint::Message') ) {
        $self->copy($msg);
        $self->{locale}   = normLocale($args{locale})     if $args{locale};
        $self->{timezone} = normTimezone($args{timezone}) if $args{timezone};
    } else {
        croak __PACKAGE__, "::init: not an email message\n";
    }
    $self;
}

#
# Method: copy
# Arguments:
# - src: a Mail::PP:Message object
# Description:
#   Shallow copy the contents of the argument to the object
#   It will copy all attributes, also those of subclasses of Message
#   It does not bless $dst to the subclass $src belongs to
#
sub copy($) {
    my $dst = shift;
    my $src = shift;
    if ( ! blessed $src || ! $src->isa('Mail::PrettyPrint::Message') ) {
        croak __PACKAGE__, "::copy: not an email message\n";
    }
    foreach my $key ( keys %$src ) {
        $dst->{$key} = $src->{$key};
    }
    $dst;
}

#
# GETTER METHODS
#
sub getMessage() {
    (shift)->{msg};
}
sub getLocale() {
    (shift)->{locale};
}
sub getTimezone() {
    (shift)->{timezone};
}


#
# FORWARDING METHODS to Mail::Message
#
# All methods from Mail::Message are made accessible through this class
# by means of forwarding. 
#

#
# Method: DESTROY
# Description:
#   empty method so AUTOLOAD won't catch it
#
sub DESTROY { }

#
# Method: AUTOLOAD
# Description:
#   forward all unknown methods to Mail::Message
#
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $call = $AUTOLOAD;
    $call =~ s/.*\:\://g;
    return $self->$call(@_) if $self->can($call);
    $self->{msg}->$call(@_);
}

#
# ACCESSOR METHODS for Format
#

sub getTimestamp() {
    my $self = shift;
    my $time = $self->{msg}->timestamp();
    DateTime->from_epoch(
        epoch       => $time
      , locale      => $self->{locale}
      , time_zone   => $self->{timezone}
    );
}

#
# These are methods used in the compilation of a Format object for
# evaluating the object, which apply specifically to messages within
# an email box or to page numbers.
# Their default implementations all die.
#

sub getDaySerial() {
    croak __PACKAGE__, "::getDaySerial: message without mail box\n";
}
sub getDayCount() {
    croak __PACKAGE__, "::getDayCount: message without mail box\n";
}
sub getBoxSerial() {
    croak __PACKAGE__, "::getBoxSerial: message without mail box\n";
}
sub getBoxCount() {
    croak __PACKAGE__, "::getBoxCount: message without mail box\n";
}
sub getPageNumber() {
    croak __PACKAGE__, "::getPageNumber: message without document\n";
}
sub getPageCount() {
    croak __PACKAGE__, "::getPageCount: message without document\n";
}


#
# FORMATTING
#

#
# Method: format
# Arguments:
# - fmt: either a Mail::PP::Format object or a string
# Result: evaluation of the format object/string
# Description:
#   This method evaluates the format object/string for this message.
#   It essentially forwards to the 'basicFormat' method in Mail::PP::Format.
#   The method dies if the argument is an invalid format string
#
sub format($) {
    my $self = shift;
    my $fmt  = shift;
    if ( ! ref $fmt ) {
        my $fmtobj = Mail::PrettyPrint::Format->new( $fmt );
        $fmtobj->format($self);
    } elsif ( blessed $fmt && $fmt->isa('Mail::PrettyPrint::Format') ) {
        $fmt->basicFormat($self);
    } else {
        croak __PACKAGE__, "::format: not a format\n";
    }
}


1;

