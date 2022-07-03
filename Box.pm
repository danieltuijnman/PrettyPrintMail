package Mail::PrettyPrint::Box;
use strict;
use warnings;

#
# (c) 2016, Daniel Tuijnman, Netherlands
#
# $Id: Box.pm,v 1.2 2016/10/10 16:08:58 daniel Exp daniel $
#
# Module that evaluates a format string for messages in a email box
#
### TODO LIST
#  1. checks on modification of underlying Mail::Box object
#  2. clean up documentation
#  3. cache evaluation of format for only a subset of the messages ?
#  4. extend isUnique to only a subset of the messages
#  5.
#

=head1 NAME

Mail::PrettyPrint:Box - caches information from email boxes for formatting

=head1 SYNOPSIS

    my $mgr  = Mail::Box::Manager->new();
    my $fold = $mgr->open( folder => FILENAME );
    my $box1 = Mail::PrettyPrint::Box->new(
        folder => $fold, timezone => TIMEZONE, locale => LOCALE
    );
    my $box2 = Mail::PrettyPrint::Box->new($fold);

    my @msgs = $box1->getMessages();

    my $msg  = $msgs[3];
    my $tim  = $box1->getTimestamp($msg);

=head1 DESCRIPTION

This module facilitates caching information about an email box that is
needed for evaluating format strings. A B<Mail::PrettyPrint::Box> object
represents a email box from the B<Mail::Box> package in a particular locale
and timezone. It caches the list of messages, sorted by time/date, as well as
the serial numbers of the messages within a day and within the email box.
It can also cache the evaluation of a particular format for all messages in
the email box.

The module caches which objects have been constructed. If you attempt to
create a second object with the same arguments, the constructor returns the
already existing object.

=head1 CONSTRUCTOR

The constructor takes three arguments:

=over

=item B<folder>: a B<Mail::Box> object

=item B<locale>: a B<DateTime::Locale> object

=item B<timezone>: a B<DateTime::TimeZone> object

=back

The B<folder> argument is mandatory, the other two are optional.
If the locale and/or the timezone are missing, the default value from the
module B<Mail::PrettyPrint::Localization> is used.

Alternatively, the constructor can be called with just a B<Mail::Box> object
as single argument.

=head1 METHODS

=head2 ACCESSOR METHODS

=over

=item B<isCached>()

returns if data has been cached about the email box.

=item B<getMessages>( [PRED] )

returns a list of all messages in the mail box, sorted ascending
by timestamp. The optional argument is a predicate, i.e., a boolean-valued
function, which expects as arguments the email message and the mailbox. If
this is supplied, only those messages fulfilling the predicate are returned.

=item B<hasMessage>( MSG [, PRED] )

returns if the message is included in the mail box. If the optional
argument, a predicate like that in B<getMessages> above, is supplied, the
method additionally tests if the message fulfills the predicate.

=item B<getDaySerial>( MSG )

gives the serial number within the same calendar day of the message.

=item B<getDayCount>( MSG )

gives the number of messages with a timestamp in the same calendar day.

=item B<getMboxSerial>( MSG )

gives the serial number within the whole email box of the message.

=item B<getMboxCount>()

gives the total number of messages in the email box.

=item B<getTimestamp>( MSG )

gives the timestamp of the message, as a B<DateTime> object.

=back

=head2 CLASS METHODS

=over

=item B<getBox>( BOX | MSG, [LOCALE], [TIMEZONE] )

retrieve the unique B<Mail::PrettyPrint::Box> object that has the given
B<Mail::Box>, locale and timezone as attributes.
The first argument to B<getBox> can also be a single email message that
belongs to an email box, i.e., an email message of class B<Mail::Box::Message>.
If the timezone (and locale) arguments are missing, the default 
timezone and locale are used.

=back

=head2 OTHER METHODS

=over

=item B<cache>()

forces generation of the cache for the email box.

=item B<cacheFormat>( FMT )

forces caching of the evaluation of the foramt for all messages in the email
box.

=item B<formatInCache>( FMT, MSG )

retrieves the cached evaluation of the format for the message. If it is not
present, B<undef> is returned.

=item B<isUnique>( FMT )

checks whether the evaluation of the format results in unique strings for
each message.

=back

=head1 LIMITATIONS

The current implementation does not check if the underlying B<Mail::Box>
object has been altered since construction of an object.

The current implementation is not Y10K proof.

=head1 AUTHOR

(c) 2015-2016 Daniel Tuijnman

=cut

use Carp;
use Tie::RefHash;
use Scalar::Util qw/blessed/;
use Mail::Box;
use Mail::Message;
use Mail::Address;
use Mail::PrettyPrint::Localization;
use Mail::PrettyPrint::Format;

our $VERSION = v1.2.1;

#
# class administration of all constructed objects
# %objects is a hash of a hash of a hash, keyed by
# (1) timezone, (2) locale, and (3) mail box, e.g.
# $objects{$tz}{$lc}{$folder}
#
my %objects;
BEGIN {
    tie %objects, 'Tie::RefHash::Nestable';
}

#
# A Mail::PrettyPrint::Box object has the following attributes:
# Required arguments:
# - folder:     Mail::Box object that will be cached
# Optional arguments:
# - locale:     locale of the object
# - timezone:   timezone of the object
# Internal (cached) attributes
# - _cached     if anything is cached
# - _msgs       sorted LIST of Mail::Messages in the box
# - _size       number of messages
# - _maxdaycnt  maximum number of messages in a day
# Internal attributes, hashes with Mail::Message as key:
# - _timestamp  DateTime object with timestamp
# - _boxserial serial number within the box
# - _dayserial  serial number within the day
# - _daycnt     number of messages in the same day
# Internal caching of format evaluations:
# - _format     hash with Format objects as key and as values hashes
#               with the following keys:
#               - str:  hash with Mail::Message keys, strings as values
#                       containing the evaluation of the format
#               - stat: status of cache. Possible values:
#                       1 - actual strings
#                       0 - fake strings because format contains page nrs
#               - msg:  hash of Mail::Message objects with strings as keys
#               - dbls: hash of strings that occur multiple times,
#                       with as value the number of occurrences minus 1
#

#
# CONSTRUCTOR
#
# Arguments:
#   - folder: an Mail::Box email box object
#   - locale: a DateTime::Locale object
#   - timezone: a DateTime::TimeZone object
#   Alternatively, a Mail::Box object can be passed to the constructor 
#   as the single argument
# Description:
#   Make a new Box object or return an existing one
#   Because we need to check if the object already exists, we fill all
#   required and optional arguments in the object.
#
sub new() {
    my $class = shift;
    # facilitate calling with just a folder argument
    if ( @_ == 1 ) {
        unshift @_, 'folder';
    }
    my %args  = @_;
    my $self;
    # first check the arguments
    my $folder;
    if ( not exists $args{folder} ) {
        croak __PACKAGE__, "::new: no folder argument\n";
    }
    $folder = $args{folder};
    my $lc = normLocale($args{locale});
    my $tz = normTimezone($args{timezone});
    # does the box already exist?
    if ( exists $objects{$tz}{$lc}{$folder} ) {
        # retrieve the existing object and fill its cache
        $self = $objects{$tz}{$lc}{$folder};
        $self->cache();
        return $self;
    }

    # make an empty object and put it in the object administration
    $self = bless {}, $class;
    $self->{folder}   = $folder;
    $self->{locale}   = $lc;
    $self->{timezone} = $tz;
    $objects{$tz}{$lc}{$folder} = $self;
    delete @args{qw/folder locale timezone/};
    $self->init(%args);
}

#
# Method: init
# Description:
#   Initialize the object
#   All arguments have been covered in new(), so we only fill the cache
#
sub init(@) {
    my $self = shift;
    my %args = @_;
    # there are no other arguments
    $self->_emptyCache();
    $self->cache();
    $self;
}

#
# ACCESSOR METHODS
#

sub getFolder() {
    (shift)->{folder};
}
sub getLocale() {
    (shift)->{locale};
}
sub getTimezone() {
    (shift)->{timezone};
}

#
# Method: getMessages
# Argument: a predicate (optional)
# Returns: (a selection of) the list of messages
# Description:
#   The messages returned are in ascending order of timestamp
#   The optional argument is a function which returns a boolean,
#   and has as arguments (1) a mail message, and (2) the mailbox.
#   If the optional argument is provided, only those messages for which
#   the function yields true are returned.
#
sub getMessages(;$) {
    my $self = shift;
    if ( @_ ) {
        my $pred = shift;
        grep { $pred->($_, $self) } @{$self->{_msgs}};
    } else {
        @{$self->{_msgs}};
    }
}

#
# Method: hasMessage
# Arguments:
# - an email message
# - optional: a predicate
# Returns: whether the message is in the mail box
# Description:
#   If the predicate is supplied, additionally it is tested whether the
#   message fulfills the predicate. See getMessages for explanation.
#
sub hasMessage($;$) {
    my $self = shift;
    my $msg  = shift;
    @_ ?  exists $self->{_timestamp}{$msg} && (shift)->($msg, $self)
    : exists $self->{_timestamp}{$msg};
}

#
# Method: getDaySerial
# Argument: an email message
# Returns: the serial number of the message within the calendar day
#
sub getDaySerial($) {
    my $self = shift;
    my $msg  = shift;
    print STDERR "Box::getDaySerial called with $msg\n" if $main::debug & 2;
    $self->{_dayserial}{$msg};
}

#
# Method: getDayCount
# Argument: an email message
# Returns: the number of messages in the same calendar day as the argument
#
sub getDayCount($) {
    my $self = shift;
    my $msg  = shift;
    print STDERR "Box::getDayCount called with $msg\n" if $main::debug & 2;
    $self->{_daycnt}{$msg};
}

#
# Method: getBoxSerial
# Argument: an email message
# Returns: the serial number of the message within the whole email box
#
sub getBoxSerial($) {
    my $self = shift;
    my $msg  = shift;
    $self->{_boxserial}{$msg};
}

#
# Method: getBoxCount
# Argument: none
# Returns: the total number of messages in the email box
#
sub getBoxCount() {
    my $self = shift;
    $self->{_size};
}

#
# Method: getTimestamp
# Argument: an email message
# Returns: the timestamp of the message as a DateTime object
#
sub getTimestamp($) {
    my $self = shift;
    my $msg  = shift;
    $self->{_timestamp}{$msg};
}

#
# CLASS ACCESSOR
#

#
# Method: getBox
# Arguments: 
# - Mail::Box folder or a Mail::Message
# - locale
# - timezone
# Returns: the Mail::PrettyPrint::Mbox object the folder or message is in
#
sub getBox($$$) {
    my $self = $_[0];
    # allow for invocation with -> as well as with ::
    shift if $self eq 'Mail::PrettyPrint::Box'
        || blessed $self && $self->isa('Mail::PrettyPrint::Box');
    my $box  = shift;
    my $lc   = normLocale(shift);
    my $tz   = normTimezone(shift);
    if ( blessed $box ) {
        if ( $box->isa('Mail::Box::Message') ) {
            $box = $box->folder();
        } elsif ( $box->isa('Mail::Message') ) {
            croak __PACKAGE__,"::getBox: message is not part of a folder\n";
        } elsif ( $box->isa('Mail::PrettyPrint::BoxMessage') ) {
            $box = $box->getFolder();
        } elsif ( ! $box->isa('Mail::Box') ) {
            croak __PACKAGE__,
                "::getBox: first argument is neither a message nor a folder\n";
        }
    } else {
        croak __PACKAGE__,"::getBox: first argument is not an object\n";
    }
    $objects{$tz}{$lc}{$box};
}

#
# GENERAL CACHING
#

#
# Method: isCached
# Returns: if the object has filled its cache
#
sub isCached($) {
    my $self;
    $self->{_cached};
}

#
# Method: cache
# Description:
#   Fill the cache of the object
#
sub cache() {
    my $self = shift;
    return if $self->{_cached};

    my @msgs = sort { $a->timestamp() - $b->timestamp() } 
        $self->{folder}->messages();
    $self->{_msgs} = \@msgs;
    $self->{_size} = @msgs;
    my $msgcnt = 0;
    my $maxdaycnt = 0;
    my %timestamp;
    my %boxserial;
    my %dayserial;
    my %daycnt;
    tie %timestamp,  'Tie::RefHash';
    tie %boxserial, 'Tie::RefHash';
    tie %dayserial,  'Tie::RefHash';
    tie %daycnt,     'Tie::RefHash';
    # temporaries that are only used for computing the %daycnt
    my %daystrcnt; # hash from YYYYMMDD string to number
    my %daystr;    # hash from message to YYYYMMDD string
    tie %daystr, 'Tie::RefHash';
    foreach my $msg ( @msgs ) {
        my $dt = DateTime->from_epoch(
            epoch     => $msg->timestamp()
          , locale    => $self->{locale}
          , time_zone => $self->{timezone}
        );
        $timestamp{$msg}  = $dt;
        $boxserial{$msg} = ++$msgcnt;
        my $thisday = $dt->strftime("%Y%m%d");
        $daystr{$msg} = $thisday;
        if ( ( $dayserial{$msg} = ++$daystrcnt{$thisday} ) > $maxdaycnt ) {
            $maxdaycnt++;
        }
    }
    # and another loop for filling the daycnt
    foreach my $msg ( @msgs ) {
        $daycnt{$msg} = $daystrcnt{$daystr{$msg}};
    }
    $self->{_maxdaycnt}  = $maxdaycnt;
    $self->{_timestamp}  = \%timestamp;
    $self->{_boxserial} = \%boxserial;
    $self->{_dayserial}  = \%dayserial;
    $self->{_daycnt}     = \%daycnt;
    my %format;
    tie %format, 'Tie::RefHash::Nestable';
    $self->{_format} = \%format;
    $self->{_cached} = 1;
    $self;
}

#
# Method: _emptyCache
# Description:
#   Delete the cached information and set the 'cached' flag to false
#
sub _emptyCache() {
    my $self = shift;
    delete ${$self}{qw/_msgs _size _maxdaycnt _daycnt
                       _timestamp _boxserial _dayserial _format/};
    $self->{_cached} = 0;
}

#
# FORMAT CACHING
#

#
# Method: cacheFormat
# Arguments:
# - fmt: a Mail::PP::Format object
# Returns: none
# Description:
#   Caches the evaluation of the Format for all messages in the mail box. 
#   In case the Format contains page numbers, the values '998' resp. '999'
#   are used, so that e.g. uniqueness of the evaluated strings can still be
#   established.
# TODO:
#   extend to caching only a subset of the mail box
#   then rethink the 'stat' key in the caching
#
sub cacheFormat($) {
    my $self = shift;
    my $fmt  = shift;
    print STDERR "Box cacheFormat entered\n" if $main::debug & 32;
    return if exists $self->{_format}{$fmt};
    my $lc = $self->getLocale();
    my $tz = $self->getTimezone();
    my @msgs = $self->getMessages();
    my %str;
    my %msg;
    my %dbls;
    tie %str,  'Tie::RefHash';
    tie %dbls, 'Tie::RefHash';
    my $has_pagenr = $fmt->hasPagenr();
    foreach my $msg ( @msgs ) {
        my $cacmsg = Mail::PrettyPrint::_CachingMessage->new(
            msg => $msg, locale => $lc, timezone => $tz
        );
        my $str = $fmt->format($cacmsg);
        print STDERR "Box cacheFormat: string is $str\n" if $main::debug & 32;
        $str{$msg} = $str;
        if ( exists $msg{$str} ) {
            print STDERR "Box cacheFormat: string is double\n"
                if $main::debug & 32;
            $dbls{$str}++;
            if ( ref $msg{$str} ne 'ARRAY' ) {
                my $org = $msg{$str};
                $msg{$str} = [ $org ];
            }
            push @{$msg{$str}}, $msg;
        } else {
            $msg{$str} = $msg;
        }
        print STDERR "Box cacheFormat: num double strings is "
            . (keys %dbls) . "\n" if $main::debug & 32;
        $self->{_format}{$fmt} = {
            str  => \%str
          , stat => 1 - $has_pagenr
          , msg  => \%msg
          , dbls => \%dbls
        };
    }
}

#
# Method: formatInCache
# Arguments:
# - fmt: a Mail::PP:Format object
# - msg: a Mail::Message object or Mail::PrettyPrint::Message object
# Returns: the cached value of the evaluated format, if it exists
#   and the format does not contain page numbers
#
sub formatInCache($$) {
    my $self = shift;
    my ($fmt, $msg) = @_;
    if ( $msg->isa('Mail::PrettyPrint::Message') ) {
        $msg = $msg->getMessage();
    }
    $self->{_format}{$fmt}{stat}
    ? $self->{_format}{$fmt}{str}{$msg}
    : undef;
}

#
#
#

#
# Method: isUnique
# Arguments:
# - fmt: a Mail::PP::Format object
# Returns: whether all strings the Format evaluates to are unique within
#   the whole mail box
# TODO:
#   extend to a subset of the mail box
#
sub isUnique($) {
    my $self = shift;
    my $fmt  = shift;
    if ( not exists $self->{_format}{$fmt} ) {
        $self->cacheFormat($fmt);
    }
    keys %{$self->{_format}{$fmt}{dbls}} == 0;
}

#
# AUXILIARY MESSAGE CLASS for CACHING
#
package Mail::PrettyPrint::_CachingMessage;

use base 'Mail::PrettyPrint::BoxMessage';

sub init(@) {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{_caching} = 1;
    $self;
}

sub getPageNumber() { 998; }
sub getPageCount() { 999; }

1;

