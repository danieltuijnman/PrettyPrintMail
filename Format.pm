package Mail::PrettyPrint::Format;

use strict;
use warnings;

#
# (c) 2015, Daniel Tuijnman, Netherlands
#
# $Id: Format.pm,v 1.19 2016/10/10 16:08:58 daniel Exp daniel $
#
# Module that defines format strings for pretty printing email messages
#
### TODO LIST:
# 14. make patterns more flexible, with more freedom in order
# 15. modifiers for Subject (@j) and MessageID (@m), and header (@H)?
# 18. change default of _{} modifier to space instead of underscore ?
# 33. 
#

=head1 NAME

Mail::PrettyPrint::Format - formatting codes for emails

=head1 SYNOPSIS

    use Mail::PrettyPrint::Format;

    eval {
        $fm = Mail::PrettyPrint::Format->new( FORMATSTRING );
    };
    eval {
        $fm2 = Mail::PrettyPrint::Format->new(
            fmtstr   => FORMATSTRING
        );
    };

    if ( $fm->hasPagenr() ) { ... }

    my $msg1 = Mail::PrettyPrint::Message->new( ... );
    my $str1 = $fm->format( $msg );

    my $msg2 = Mail::PrettyPrint::PdfFile->new( ... );
    my $str2 = $msg2->format( $fm2 );

=head1 DESCRIPTION

This module defines formatting codes for the generation of strings based on
various parts of an email message, analogous to the formatting codes used in
B<strftime> for formatting dates and times. An object represents a format
string containing formatting codes, and can be evaluated with the method
B<format> for a specific email message to an actual string.

The formatting codes primarily are used to select various headers from an
email, such as the sender, the addressee(s) and the subject. The email's
date - and parts of it - can be selected with the various B<strftime>
formatting codes.

Furthermore, there are a few formatting codes that give serial numbers
of an email within a email folder, and which can only be evaluated within a
suitable subclass.

=head1 CONSTRUCTORS

The constructor B<new> has one required argument, a format string.
If the string is incorrect, the constructor dies with an error message.
Alternatively, the argument may be named I<fmtstr>.

Furthermore, the module provides two copy constructors:

=over

=item B<clone>()
makes a shallow copy of the object and returns this.

=item B<copy>(SRC)
makes a shallow copy of SRC into $self.

=back

=head1 METHODS

=head2 ACCESSOR METHODS

=over

=item B<hasDatetime>()

returns whether the format string contains timestamp dependent codes,
i.e., all B<strftime> codes.

=item B<hasMsgCode>()

returns whether the format string contains message dependent codes, i.e.,
about any code except I<@p> or I<@P>.

=item B<hasPagenr>()

returns whether the format string contains page number codes (I<@p> or I<@P>).

=item B<hasSerial>()

returns whether the format string contains codes which give a
serial number within an email folder (I<@n>, I<@N>, I<@o> or I<@O>).

=item B<formatString>()

returns the format string of the object.

=back

=head2 CLASS METHODS

=over

=item B<checkFormat> ( STRING )

check if the string is a valid format string without making an object.

=back

=head2 FORMATTING METHODS

=over

=item B<format>( MSG )

This method evaluates the format string for a given email message.
If the argument is an object of class B<Mail::PrettyPrint::Message>, the
method forwards the work to the B<format> method of that class so it can use
a cached result if that exists.

If the argument is an object of class B<Mail::Message>, the message is
assumed to "live" in the default locale from
B<Mail::PrettyPrint::Localization>. If the argument is an object of the
class B<Mail::Box::Message>, the email folder it belongs to will be taken
into account.

=item B<basicFormat>( MSG )

This method does the actual formatting. Its argument must be an object of
class B<Mail::PrettyPrint::Message>.

=back

If a formatting code cannot be evaluated for a given argument,
the formatting method will die. See B<IMPLEMENTATION> below for details.

=head1 FORMAT STRINGS

The filename format recognizes all escape sequences from Perl's
implementation of B<strftime>; see the documentation of the B<DateTime>
module for details.

Additionally, it recognizes escape sequences starting with a I<@> to include
information from the email headers. These escape sequences are:

=over

=item B<@>[MODS][INDEX]B<b>

The Bcc: email addresses.

=item B<@>[MODS][INDEX]B<B>

The phrases associated with the Bcc: email addresses.

=item B<@>[MODS][INDEX]B<c>

The list of Cc: email addresses.

=item B<@>[MODS][INDEX]B<C>

The phrase associated with the Cc: email addresses.

=item B<@>[MODS]B<D>

Prints nothing, but sets default values for modifiers.

=item B<@>[MODS][INDEX]B<f>

The From: email addresses.

=item B<@>[MODS][INDEX]B<F>

The phrase associated with the From: email addresses.

=item B<@H{>HEADERB<}>

The named header. In case the header appears multiple times, a comma
separated list is produced.

=item B<@j>

The subject of the email.

=item B<@m>

The message-ID.

=item B<@>[FORMAT]B<n>

The serial number of the email within the day.

=item B<@>[FORMAT]B<N>

The total number of emails within the same day.

=item B<@>[FORMAT]B<o>

The serial number of the email within the whole email bo.

=item B<@>[FORMAT]B<O>

The total number of emails within the whole email bo.

=item B<@>[FORMAT]B<p>

The current page number of a printout.
This formatting code can only be evaluated if I<format> is given an
I<Mail::PrettyPrint::PdfFile> object as second argument.

=item B<@>[FORMAT]B<P>

The total number of pages of a printout.
This formatting code can only be evaluated if I<format> is given an
I<Mail::PrettyPrint::PdfFile> object as second argument.

=item B<@>[MODS]B<s>

The Sender: email address.

=item B<@>[MODS]B<S>

The phrase associated with the Sender: email address, with spaces
replaced by underscores.

=item B<@>[MODS][RANGE]B<t>

The To: email addresses.

=item B<@>[MODS][RANGE]B<T>

The phrases associated with the To: email addresses.

=back

=head2 MODIFIERS

The following modifiers can be applied to formatting codes resulting in
lists of addresses. They must be supplied in the order listed:

=over

=item B<,{> STRING B<}>

The separator string between two items in a list of phrases, or a list of
email addresses. Standard behaviour is to separate two items with a comma.

=item B<_{> STRING B<}>

Only applies to phrases: A string to replace a space in phrases.
Standard behaviour is to replace spaces with underscores. So, I<_{ }>
prints the phrase "as-is".  The string may not contain braces.

=item B<">

Only applies to phrases: Retain the (double or single) quotes around a phrase.
Standard behaviour is to delete these quotes.

=item B<L>, B<U>

Only applies to phrases: Convert the whole string to lowercase resp. to
uppercase.

=item B<u>, B<h>

Only applies to email addresses: Select only the user resp. host portion of
the email address(es).

=back

=head2 INDEX LIST

The formatting codes yielding lists of email addresses can be prefixed
with an index list. An index list consists of a sequence consisting
of either individual numbers, e.g., I<3>, or a range, e.g., I<5-7>,
separated by commas. Thus, the formatting code I<@5-7,3t> will select
only the fifth, sixth, seventh and third email addresses from the To:
list, in that order. The indices start at 1.

=head2 NUMBER FORMATS

The formatting codes yielding a number can be prefixed by a format how to
print the number. The possible formatting codes are:

=over

=item B<_{> STRING B<}>

A character to replace spaces with. Standard behaviour is to replace spaces
with underscores. In particular,  B<_{0}> is equivalent to the B<0> flag of
I<printf> when the number is right adjusted.

=item B<->

Left adjust the number.

=item  NUMBER

The minimum field with for printing the number. If the number does not fit, 
the number is printed in the minimum width needed.

=item  B<*>

The field width is taken to be the minimum field width needed to print any
number in its category; e.g., for B<n>, the field width is determined by the
total number of emails within the same day in the email bo. This format
is mutually exclusive with a NUMBER fieldwidth format.

=back

=head1 IMPLEMENTATION

On construction of a B<Mail::PrettyPrint::Format> object, the format
string is compiled into a list of functions which are evaluated when
B<format> is called. These functions use various methods from the
B<Mail::PrettyPrint::Message> clas hierarchy to extract information from
the message object, as well as methods from B<Mail::Message>.

The relevant methods in B<Mail::PrettyPrint::Message> are:

=over

=item B<getTimestamp>

This method gives the timestamp of the message as a B<DateTime> object.
It is used for the evaluation of all the B<strftime> formatting codes.
It is properly implemented in B<Mail::PrettyPrint::Message> itself.

=item B<getDaySerial>, B<getDayCount>, B<getBoxSerial>, B<getBoxCount>

These methods are used for evaluating the formatting codes I<@n>, I<@N>,
I<@o> and I<@O> respectively. They are properly implemented in the class
B<Mail::PrettyPrint::BoxMessage>.

=item B<getPageNumber>, B<getPageCount>

These methods are used for evaluating the formatting codes I<@p> and I<@P>.
They are properly implemented in the class B<Mail::PrettyPrint::PdfFile>.

=back

For the latter two categories, the class B<Mail::PrettyPrint::Message>
gives basic implementations that die. Any subclass that wants to implement
the respective formatting codes, must give proper implementations of these
methods.

When called with a vanilla B<Mail::Message> object,
the method B<format> creates a B<Mail::PrettyPrint::Message> wrapper around
it that lives in the default timezone. When the argument belongs to an email
folder, i.e., it is of class B<Mail::Box::Message>, it creates a
B<Mail::PrettyPrint::BoxMessage> wrapper so that the I<@n> etc. formatting
codes can be evaluted as well.

=head1 BUGS

Undoubtedly.

=head1 AUTHOR

(c) 2015-2016 Daniël Tuijnman

=cut

use Carp;
use Tie::RefHash;
use Mail::Box;
use Mail::Box::Mbox;
use Mail::Box::Mbox::Message;
use Mail::Message;
use Mail::Address;
use Mail::PrettyPrint::Localization;

our $VERSION = v1.2.1;

#
# A Mail::PrettyPrint::Format object has the following attributes:
# Required arguments:
# - fmtstr:         the format string
# Internal attributes:
# - _cached:        reserved, not used
# - _compiled:      the list of strings/functions for quick evaluation
# - _has_msg:       boolean if the format string needs a message
# - _has_datetime:  boolean if the format string needs a timezone&locale
# - _has_pagenr:    boolean if the format string contains @p/@P
# - _has_serial:    boolean if the format string contains @n/@N/@o/@O
#                   (actually, both keep a count)
#
# A compiled format is a list consisting of
# (1) literal strings, and 
# (2) functions which can be evaluated in
#     Mail::PrettyPrint::FormatMbox::format()
#     These functions take two arguments:
#     1. a Mail::PrettyPrint::FormatMbox object
#     2. a Mail::Message object
#     Most of these functions simply return a string, with two exceptions:
#     the functions for @p and for @P. These functions return again a
#     function which takes a Mail::PrettyPrint::PdfFile object as argument.
#


#
# CONSTRUCTORS
#

# Description:
#   Standard definition of new(), moves all actual work to init() which then
#   can be overridden in a derived class
#
sub new() {
    my $class = shift;
    my $self  = bless {}, $class;
    # simple sanity check
    die __PACKAGE__, "::new: no arguments given\n" if ! @_;
    # and so we can call new() with just a format string and nothing else:
    unshift @_, 'fmtstr' if @_ == 1;
    $self->init(@_);
}

#
# Initializer
# Arguments:
#   fmtstr      format string, required
# Description:
#   Initializes the object with its basic attributes and then compiles the
#   format.
#
sub init(@) {
    my $self = shift;
    my %args = @_;
    if ( ! exists $args{fmtstr} ) {
        croak __PACKAGE__, "::init: no format string given\n";
    }
    $self->{fmtstr} = $args{fmtstr};
    # now compile the format string
    $self->_bareCheckFormat(1);
    $self;
}

#
# Method: clone
# Description:
#   Makes a new object, which is a shallow copy of $self
#
sub clone() {
    my $self = shift;
    my $copy = bless {}, ref $self;
    foreach my $key ( keys %$self ) {
        $copy->{$key} = $self->{$key};
    }
    $copy;
}

#
# Method: copy
# Description:
#   Shallow-copy the attributes of the argument into $self
#
sub copy($) {
    my $self = shift;
    my $src  = shift;
    if ( ! blessed $src || ! $src->isa('Mail::PrettyPrint::Format') ) {
        croak __PACKAGE__, "::copy: not a format\n";
    }
    foreach my $key ( keys %$src ) {
        $self->{$key} = $src->{$key};
    }
    $self;
}

#
# class method for just checking if a format string is right,
# not compiling it
#
sub checkFormat($) {
    my $class = shift;
    my $fmt   = shift;
    my $self  = bless { fmtstr => $fmt }, $class;
    eval { $self->_bareCheckFormat(0) } ? 1 : 0;
}

#
# ACCESSOR METHODS
#
sub hasPagenr() {
    my $self = shift;
    $self->{_has_pagenr};
}

sub hasSerial() {
    my $self = shift;
    $self->{_has_serial};
}

sub hasMsgCode() {
    my $self = shift;
    $self->{_has_msg};
}

sub hasDatetime() {
    my $self = shift;
    $self->{_has_datetime};
}

sub formatString() {
    my $self = shift;
    $self->{fmtstr};
}

sub _isCompiled() {
    my $self = shift;
    scalar @{$self->{_compiled}};
}


my $strftime_letters = '\%aAbBcCdDeFgGhHIjklmMnNpPrRsStTuUVwWxXyYzZ';

#
# AUXILIARY FUNCTIONS for HIHGER ORDER FUNCTION MANIPULATION
#

#
# Functions: _identity, _funcomp2, _funcomp
# Arguments: list of functions to compose
# Return: composed function
# Description: good old fashioned function composition
#   undefined items are skipped for efficiency
#   _funcomp2 is the recursive auxiliary function for _funcomp
#
sub _identity (@) { my @res = @_; @res; }

sub _funcomp2(@);

sub _funcomp2(@) {
    my $fun1 = shift;
    if ( @_ == 0 ) {
        $fun1;
    } else {
        my $fun2 = _funcomp2 @_;
        if ( $main::debug & 2 ) {
            sub {
                my @args = @_;
                print STDERR "_funcomp2 generated called with "
                    . @args .  " args: |",
                    join("|", map {ref} @args), "##",
                    join("|", @args), "|\n";
                my @intr = $fun2->(@args);
                print STDERR "_funcomp2 generated with "
                    . @intr . " interm: |",
                    join "|", @intr, "\n";
                $fun1->(@intr);
            }
        } else {
            sub { $fun1->($fun2->(@_)); }
        }
    }
}

sub _funcomp(@) {
    my @args = grep { defined } @_;
    @args ? _funcomp2(@args) : \&_identity;
}

#
# Function: _lift_funcomp
# Description: lifted function composition
#   The rightmost argument of _lift_funcomp is a curried function, i.e.,
#   it is of type X -> Y -> Z. The second rightmost then is a simple
#   function of type Z -> W, the third rightmost of type W -> V, etc.
#   The resultant function is of type X -> Y -> R
#
sub _lift_funcomp(@) {
    print STDERR "_lift_funcomp called with " . @_ . " args\n"
        if $main::debug & 2;
    my $currfun = pop;
    return $currfun if ! @_;
    my @funs = grep { defined } @_;
    sub {
        _funcomp @funs, $currfun->(@_);
    }
}

#
# AUXILIARY FUNCTIONS for MODIFIERS
#

#
# Function: _mk_comma_fun
# Argument: list separator
# Return: curried version of 'join'
# Description: Generate a function that concatenates its arguments with
#   the given list separator. Basically, a curried version of 'join'.
#
sub _mk_comma_fun($) {
    my $listsep = shift;
    if ( $main::debug & 2 ) {
        sub {
            my @args = @_;
            print STDERR "_mk_comma_fun($listsep) with "
                . @args . " arguments: |",
                join "|", @args, "\n";
            my $res = join $listsep, @args;
            print STDERR "_mk_comma_fun result is $res\n";
            $res;
        }
    } else {
        sub { join $listsep, @_; }
    }
}

#
# Function: _mk_space_fun
# Argument: space replacement string
# Return: a function that replaces all spaces in each of its arguments with
#         the given replacement string
# Description: generate a function that replaces spaces by a given string
#
sub _mk_space_fun($) {
    my $repl = shift;
    if ( $main::debug & 2 ) {
        sub { my @args = @_;
            print STDERR "_mk_space_fun($repl) with " . @args . " arguments: |",
                join "|", @args, "\n";
            my @res = map { s/ /$repl/g; $_ } @args;
            print STDERR "_mk_space_fun result list has "
                . @res . " elements: |", join "|", @res, "\n";
            @res;
        }
    } else {
        sub { map { s/ /$repl/g; $_ } @_; }
    }
}

#
# Function: _remove_quotes
# Arguments: list of strings
# Return: same list but now stripped of surrounding quotes.
# Description: removes the quotes surrounding each string in the list
#   of arguments.
#   Both double and single quotes are removed, but they have to match.
#
sub _remove_quotes(@) {
    map { s/^(["'])(.*)\1$/$2/; $_ } @_;
}

# Mapped versions of lc and uc
sub _mk_lc(@) {
    map { lc } @_;
}
sub _mk_uc(@) {
    map { uc } @_;
}

# in order to not get warnings on the undefined value of $main::debug
# in calling _mk_comma_fun and _mk_space_fun
BEGIN { $main::debug ||= 0; }
# Standard behavior for the various code modifiers
my %standard_funs = (
    comma   => _mk_comma_fun(',')
  , space   => _mk_space_fun('_')
  , quote   => \&_remove_quotes
  , case    => undef
  , range   => undef
);

#
# AUXILIARY FUNCTIONS for INDEX LISTS
#

#
# Function: _mk_range_fun
# Argument: an index list string as in the format string specification
# Return: a function taking a list and returning a sublist
# Description: generates a function that selects a range from a list
#   of addresses.
#
sub _mk_range_fun($) {
    my $str = shift;
    $str =~ s/(\d+)/$1-1/ge;
    $str =~ s/-/../g;
    my @range = eval "$str";
    print "_mk_range_fun: range @range\n" if $main::debug & 2;
    sub {
        my @args = @_;
        # select only those indices that actually exist
        my @actrange = grep { $_ < @args } @range;
        @args[@actrange];
    }
}

#
# AUXILIARY FUNCTIONS for NUMBER FORMATS
#

#
# Function: _mk_num_fun
# Arguments:
# 1. a sprintf formatting code
# 2. a function that runtime computes the number to be printed
# 3. a function that runtime computes the maximum possible value of the
#    number to be printed, in case the formatting code contains a *
# Return: a function taking a Formatter, a Mail::Message and a PdfFile
# Description: generates a function that evaluates a number code
#
sub _mk_num_fun($$$) {
    my ($fmt, $numfun, $maxnumfun) = @_;
    print STDERR "_mk_num_fun generator called with $fmt, ",
        "$numfun, $maxnumfun\n" if $main::debug & 2;
    sub {
        #my $num = $numfun->(@_);
        #my $maxnum = length $maxnumfun->(@_);
        #my $res = sprintf $fmt, $num, $maxnum;
        #$res;
        if ( $main::debug & 2 ) {
            print STDERR "_mk_num_fun generated:\n",
                "\targs: @_\n",
                "\tnum: ", $numfun->(@_), "\n",
                "\tmaxnum: ", $maxnumfun->(@_), "\n";
        }
        sprintf $fmt, $numfun->(@_), length $maxnumfun->(@_);
    }
}

#
# lifted version of _mk_num_fun
# the two functions are now of one level higher
# this one is not actually used at the time
#
sub _mk_lift_num_fun($$$) {
    my ($fmt, $numfunfun, $maxnumfunfun) = @_;
    print STDERR "_mk_lift_num_fun generator called with $fmt, ",
        "$numfunfun, $maxnumfunfun\n" if $main::debug & 2;
    if ( $main::debug & 2 ) {
        sub {
            print STDERR "_mk_lift_num_fun generated level one called\n";
            my $numfun = $numfunfun->(@_);
            my $maxnumfun = $maxnumfunfun->(@_);
            sub {
                print STDERR "_mk_lift_num_fun generated level two called\n";
                my $num = $numfun->(@_);
                my $maxnum = length $maxnumfun->(@_);
                my $res = sprintf $fmt, $num, $maxnum;
                $res;
            }
        }
    } else {
        sub {
            my $numfun = $numfunfun->(@_);
            my $maxnumfun = $maxnumfunfun->(@_);
            sub {
                #my $num = $numfun->(@_);
                #my $maxnum = length $maxnumfun->(@_);
                #my $res = sprintf $fmt, $num, $maxnum;
                #$res;
                sprintf $fmt, $numfun->(@_), length $maxnumfun->(@_);
            }
        }
    }
}


#
# AUXLIARY FUNCTIONS for ADDRESS FORMAT CODES
#

# Names of the address selection methods from Mail::Message
my %addr_method = (
    b => 'bcc', c => 'cc', f => 'from', s => 'sender', t => 'to'
);

#
# Function: Mail::Address::phrase_or_address
# Description:
#   extra accessor for Mail::Address objects that returns the phrase,
#   but if it is empty, returns the address instead
#
sub Mail::Address::phrase_or_address() {
    my $self = shift;
    $self->phrase() || $self->address;
}

#
# Function: _mk_addr_fun
# Arguments:
# 1. name of the method from Mail::Message to apply: to(), cc(), etc.
# 2. name of the method to select a part of each address:
#    phrase(), address(), user() or host()
# Return: a function taking a Formatter, a Mail::Message and a PdfFile
# Description: generates a function that selects a part of an email
#   header containing email addresses.
#
sub _mk_addr_fun($$) {
    my $method = shift; # to/cc/bcc/...
    my $part   = shift; # accessor method of Mail::Address
    if ( $main::debug & 2 ) {
        sub {
            print STDERR "_mk_addr_fun('$method', '$part')\n";
            my @res = map { $_->$part } $_[0]->$method;
            print STDERR "_mk_addr_fun result list has " . @res . " elements\n";
            @res;
        }
    } else {
        sub { map { $_->$part } $_[0]->$method; }
    }
}


#
# Functions for each of the basic numeric codes in the format specification
# The n/N/o/O functions are simply methods from Mail::PrettyPrint::FormatMbox
# which return a simple number
# The p/P functions don't return a number - they can't be evaluated from
# the format and the mbox alone - but they need additionally a
# Mail::PrettyPrint::PdfFile object to tb evaluated. So they return a function
# returning a function. For facilitating their evaluation without a PdfFile
# object they do return a fake result.
#
my %num_fun = (
    n   =>  sub { $_[0]->getDaySerial();  }
  , N   =>  sub { $_[0]->getDayCount();   }
  , o   =>  sub { $_[0]->getBoxSerial(); }
  , O   =>  sub { $_[0]->getBoxCount();  }
  , p   =>  sub {
                print STDERR "__format_fun_\@p called\n" if $main::debug & 2;
                $_[0]->getPageNumber();
            }
  , P   =>  sub { $_[0]->getPageCount(); }
);

#
# PARSING and COMPILING the FORMAT
#

#
# Method: _bareCheckFormat
# Arguments: an optional flag if it must compile the format
# Returns:
#    $self if successful on compilation
#    1 if successful on checking only
#    dies if unsuccessful
# Description: 
#   This routine checks if a format string is correct and compiles
#   it into a list of literals and routines that will be executed upon
#   calling format() from the Mail::PP::FormatMbox class.
#   The check on the strftime pattern is taken straight from the source
#   of the DateTime.pm module.
#
sub _bareCheckFormat(;$) {
    my $self = shift;
    my $fmt  = $self->{fmtstr};
    my $compile = shift || 0;
    print STDERR "_bareCheckFormat called with $fmt\n" if $main::debug & 2;
    if ( $fmt =~ /\n/ ) {
        die "no literal newlines allowed in format";
    }
    my @compiled;
    my $has_msg    = 0;
    my $has_datetime = 0;
    my $has_pagenr = 0;
    my $has_serial = 0;
    my %default_funs = %standard_funs;

    while ( $fmt =~ /[%@]/ ) {
        my $lit = $`;
        if ( $compile and length $lit ) {
            push @compiled, $lit;
        }
        $fmt = $';
        if ( $& eq '%' ) {
            # check strftime pattern
            if ( $fmt =~ /^(\{\w+\}|[$strftime_letters]|\d+N)/ ) {
                my $pat = "%$1";
                push @compiled,
                    sub { $_[0]->getTimestamp($_[1])->strftime($pat); }
                    if $compile;
                $fmt = $';
            } else {
                die "Wrong strftime pattern encountered at %$fmt\n";
            }
            $has_msg = 1;
            $has_datetime = 1;
        } else {
            my %funs = %default_funs;
            # variables for all possible parts of a pattern
            my ($commamod, $commastr, $spacemod, $spacestr, $quotemod,
                $casemod, $domainhost, $range, $rangeext,
                $leftadjust, $fwidthmod, $fwidthnum, $fwidthmax,
                $header,
                $code);
            # various regexes to recognize patterns
            if ( ( $commamod, $commastr, $domainhost,
                   $range, $rangeext, $code ) =
                 $fmt =~ /^ ( \,\{ ( [^{}]* ) \} )?
                            ( [uh] )?
                            ( [1-9]\d* ([,-][1-9]\d*)* )?
                            ( [bcfst] ) /x )
            {
                next if ! $compile;
                # pattern with email addresses
                my $part = 'address';
                if ( $commamod ) {
                    $funs{comma} = _mk_comma_fun $commastr;
                }
                if ( $range ) {
                    if ( $code eq 's' ) {
                        warn "Ignoring range with 's'\n";
                        $funs{range} = undef;
                    } else {
                        $funs{range} = _mk_range_fun $range;
                    }
                }
                if ( $domainhost ) {
                    $part = $domainhost eq 'u' ? 'user' : 'host';
                }
                push @compiled,
                    _funcomp @funs{qw/comma range/},
                        _mk_addr_fun $addr_method{$code}, $part;

                $has_msg = 1;
                $fmt = $';
            } elsif ( ( $commamod, $commastr, $spacemod, $spacestr,
                        $quotemod, $casemod,  $range, $rangeext, $code ) =
                      $fmt =~ /^ ( \,\{ ( [^{}]* ) \} )?
                                 ( \_\{ ( [^{}]* ) \} )?
                                 ( \" )?
                                 ( [LU] )?
                                 ( [1-9]\d* ([,-][1-9]\d*)* )?
                                 ( [BCDFST] ) /x )
            {
                next if ! $compile;
                # pattern with email address phrases
                # or setting of default modifiers
                if ( $commamod ) {
                    $funs{comma} = _mk_comma_fun $commastr;
                }
                if ( $spacemod ) {
                    $funs{space} = _mk_space_fun $spacestr;
                }
                if ( $quotemod ) {
                    $funs{quote} = undef;
                }
                if ( $casemod ) {
                    $funs{case}  = $casemod eq 'L' ? \&_mk_lc : \&_mk_uc;
                }
                if ( $range ) {
                    if ( $code eq 'S' ) {
                        warn "Ignoring range with 'S'\n";
                        $funs{range} = undef;
                    } else {
                        $funs{range} = _mk_range_fun $range;
                    }
                }
                if ( $code eq 'D' ) {
                    %default_funs = %funs;
                } else {
                    my $head = lc $code;
                    push @compiled,
                        _funcomp @funs{qw/comma space quote case range/},
                            #_mk_addr_fun $addr_method{$head}, 'phrase';
                            _mk_addr_fun $addr_method{$head},
                                'phrase_or_address';
                }
                $has_msg = 1;
                $fmt = $';
            } elsif ( ( $spacemod, $spacestr, $leftadjust,
                        $fwidthmod, $fwidthnum, $fwidthmax,
                        $code ) =
                      $fmt =~ /^ ( \_\{ ( [^{}] ) \} )?
                                 ( \- )?
                                 ( ([1-9]\d*) | (\*) )?
                                 ( [nNoOpP] ) /x ) {
                next if ! $compile;
                # pattern with numbers
                if ( $spacemod ) {
                    $funs{space} = _mk_space_fun $spacestr;
                }
                my $printf_fmt = '%';
                $printf_fmt .= '-' if $leftadjust;
                if ( $fwidthnum ) {
                    $printf_fmt .= $fwidthnum;
                } elsif ( $fwidthmax ) {
                    $printf_fmt .= '*2$';
                }
                $printf_fmt .= 'd';
                if ( lc $code eq 'p' ) {
                    print STDERR "_bareCheckFormat: compile pagenr code\n"
                        if $main::debug & 2;
                    my $fun = _funcomp _mk_comma_fun(''), $funs{space},
                                _mk_num_fun $printf_fmt,
                                    $num_fun{$code}, $num_fun{uc $code};
                    push @compiled, $fun;
#                        sub {
#                            print STDERR "__format_fun_\@p level 1 called\n"
#                                if $main::debug & 2;
#                            $fun;
#                        };

                    $has_pagenr++;
                } else {
                    push @compiled,
                        _funcomp _mk_comma_fun(''), $funs{space},
                        _mk_num_fun $printf_fmt,
                            $num_fun{$code}, $num_fun{uc $code};
                    $has_msg = 1;
                    $has_serial++;
                }
                $fmt = $';
                print STDERR "_bareCheckFormat after number: |$fmt|\n"
                    if $main::debug & 2;
            } elsif ( ($code) = $fmt =~ /^([jm])/ ) {
                next if ! $compile;
                # simple standard email header
                my $method = $code eq 'j' ? "subject" : "messageId";
                push @compiled, sub { $_[0]->head->study($method); };
                $has_msg = 1;
                $fmt = $';
            } elsif ( ($header) =
                      $fmt =~ /^ H \{ ( [A-Za-z-]+ ) \} /xi )
            {
                next if ! $compile;
                # custom email header
                my $method = $1;
                push @compiled, sub { join ',', $_[1]->head->study($method); };
                $has_msg = 1;
                $fmt = $';
            } elsif ( $fmt =~ /^\@/ ) {
                next if ! $compile;
                # literal '@'
                push @compiled, '@';
                $fmt = $';
            } else {
                die "Wrong email pattern encountered at \@$fmt";
            }
        }
    }
    return 1 if ! $compile;
    # and the tail part
    if ( $fmt ne '' ) {
        print STDERR "_bareCheckFormat: add tail |$fmt|\n" if $main::debug & 2;
        push @compiled, $fmt;
    }
    $self->{_compiled}   = \@compiled;
    $self->{_has_msg}    = $has_msg;
    $self->{_has_datetime} = $has_datetime;
    $self->{_has_pagenr} = $has_pagenr;
    $self->{_has_serial} = $has_serial;
    $self;
}

#
# USER METHOD format and its auxiliary methods
#

#
# Method: format
# Argument: email message
# Returns: a function that takes an (optional) PdfFile object as argument
# Description:
#   Evaluates the format string for the given email message.
#   The email message may be an object of either
#   1)  Mail::Message class hierarchy, in which case the work is forwarded to 
#       basicFormat which does the real work
#   2)  Mail::PrettyPrint::Message hierarchy, in which case the work is
#       forwarded to the format() method in that hierarchy, which may have
#       cached the result
#
sub format($) {
    my $self = shift;
    if ( ! @_ ) {
        croak __PACKAGE__, "::format: message argument missing\n";
    }
    my $msg  = shift;
    if ( blessed $msg ) {
        if ( $msg->isa('Mail::Message') ) {
            $msg = $msg->isa('Mail::Box::Message')
                ? Mail::PrettyPrint::BoxMessage->new($msg)
                : Mail::PrettyPrint::Message->new($msg);
        } elsif ( not $msg->isa('Mail::PrettyPrint::Message') ) {
            croak __PACKAGE__, "::format: message argument wrong object\n";
        }
    } else {
        croak __PACKAGE__, "::format: message argument no object\n";
    }
    $msg->format($self);
}

#
# Function: basicFormat
# Arguments: email message, of the class Mail::PrettyPrint::Message
# Description:
#   The real formatting work is done here
#
sub basicFormat($) {
    my $self = shift;
    my $msg  = shift;
    my @comp = @{$self->{_compiled}};
    print STDERR "_bareFormat: compiled format has " . @comp .
        " elements: @comp\n" if $main::debug & 2;
    my $res;
    foreach my $c ( @comp ) {
        print STDERR "_bareFormat: loop: ", ref $c, "\n" if $main::debug & 2;
        $res .= ref $c ? $c->($msg) : $c;
    }
    $res;
}

1;

