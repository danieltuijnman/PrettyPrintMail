#!/usr/bin/perl
use strict;
use warnings;

#
# (c) 2015, Daniel Tuijnman, Netherlands
#
# $Id: prettyprintmail.pl,v 1.19 2016/10/03 16:21:58 daniel Exp daniel $
#
# Script for pretty printing emails
# converts emails into PS and/or PDF files, ready for printing
#
### TODO LIST:
# 18. support other paper sizes (here with an option, plus in the modules)
# 28. implement the selection of a layout,
#     specifically the page headers and footers
# 29. parse the HTML portion of an email if present
# 31. check uniqueness over all mailboxes (so first read them all in before
#     processing them)
# 33. clean up handling of email headers, especially ALL which now only
#     includes the headers known to the script.
# 35. 
#

=head1 NAME

prettyprintmail.pl - pretty print emails into PDF files

=head1 SYNOPSIS

    prettyprintmail.pl [OPTIONS]... FOLDER...

=head1 OPTIONS AND ARGUMENTS

=over

=item B<-a> I<filename>, B<--alias> I<filename>:

Use the file as an alias file for use in the B<-B> and B<-b> options.

=item B<-A> I<[NUM]>, B<--Attachments> I<[NUM]>:

Include printing the names of attachments. If the number is absent or 1,
they are printed after the header, otherwise after the body.

=item B<-B> I<[ADDRESS...]>, B<--Bcc> I<[ADDRESS...]>

Include the Bcc header in the output for the named adresses,
right below the Cc: line.
See the section I<BCC ADDRESSES> for details.

=item B<-d> I<level>, B<--debug> I<level>

Give debugging output on stderr. See I<DEBUG OUTPUT> below for the
meaning of the level parameter.

=item B<-f>, B<--force>

Force the script to produce output files even if they will overwrite
previous files.

=item B<-F> I<FORMAT>, B<--Format> I<FORMAT>

Format of the filenames of the generated PDF and/or text files.
See the section I<FILENAME FORMAT> below for details.

=item B<-h>, B<--help>

Print short help and exit.

=item B<-H> I<header>, B<--Header> I<header>

Include the named email header in the output.
The name of the header is case insensitive.
The special name I<ALL> includes all headers known to the script, in
alphabetical order.

=item B<-i>, B<--interactive>

Ask for confirmation before overwriting a file.

=item B<-l> LOCALE, B<--locale> LOCALE

Use the specified locale. Default is the local locale.

=item B<-L> I<LAYOUTARG>, B<--Layout> I<LAYOUTARG>

Use the given layout arguments for generating the PDF files.
See the section I<LAYOUT> below for details.
B<Not yet implemented.>

=item B<-m>, B<--man>

Print complete documentation and exit.

=item B<-M>, B<--MessageID>

Include the MessageId header in the output, right below the Date: line.

=item B<-o>, B<--outputdir>

Directory to put the output files into. Default is the directory containing
the mailbox.

=item B<-p>, B<--papersize>

The papersize for the generated PDF files. Default is A4.

=item B<-q>, B<--quiet>

Suppress warnings. One instance of B<-q> on the command line will suppress
all warnings except those about overwriting files. Two instances of B<-q>
will suppress all warnings.

=item B<-S> I<SELECTION>, B<--Select> I<SELECTION>

Process only the emails that satisfy the selection criterion.
See I<EMAIL SELECTION> below for an explanation of the possible criteria.

=item B<-t>, B<--text>

Generate separate text files for each email, as well as PDF files.

=item B<-T>, B<--Textonly>

Generate only text files for each email, and no PDF files.

=item B<-v>, B<--verbose>

Increase the verbosity level of the script.

=item B<-x>, B<--xhtml>, B<--xml>

Process the HTML part of the email. Default is to process the plain text
part.
B<Not yet implemented.>

=item B<-z> TIMEZONE, B<--zone> TIMEZONE, B<--timezone> TIMEZONE

Use the specified timezone. Default is the local timezone.

=back

=head1 DESCRIPTION

This script pretty prints the emails from an email folder into separate PDF
files. The script prints the email headers in the following order:

=over

=item B<From:> always

=item B<To:> always

=item B<Cc:> always

=item B<Bcc:> if selected with the B<-B> or B<-H> options

=item B<Date:> always

=item B<Message-ID:> if selected with the B<-M> or B<-H> options

=item B<other> headers as selected with the B<-H> option

=back

The headers are default printed in a slightly larger font than the body,
with the names of the headers printed in bold. The lists of addresses in the
B<From:>, B<To:>, B<Cc:> and B<Bcc:> headers are printed without repeating
the header name; with other headers, the name of the header is repeated.

Additionally, the names of the attachments from the email can be
printed with the option B<-A>, either in between the headers and the body,
or at the end after the body. These are printed in the same fashion as the
email headers, with as "header name" the word B<Attachments>.

When there are multiple variants of the email body, the script always
selects the plain text variant.

With the B<-S> option, only a selection of emails is pretty printed. See the
section B<EMAIL SELECTION> below for details.

When the B<-t> option is provided, the script will print the selected emails
as-is in textfiles. When the B<-T> option is provided, the script will print
the selected emails I<only> as textfiles and will not produce PDF files.

The names of the generated files are determined from a format string
provided with the B<-F> option.

=head2 BCC ADDRESSES

The option B<-B> allows to selectively print the Bcc recipients of
the email(s). The Bcc header will be printed immediately after the Cc
header.

Default behaviour is not to print a Bcc header. The B<-B> option is
optionally followed by a comma-separated list of addresses or aliases to
include in the output. Alternatively, the option may be used repeatedly on
the command line; in both cases, the list of addressess is processed from
left to right.

The B<-a> option can be used to specify an I<alias file> which contains
alias statements like those in a I<.muttrc> file, so aliases can be used
instead of actual email addresses in the B<-B> options.

The arguments B<-b> option can have the following forms:

=over

=item B<empty>

An empty string means to include I<all> Bcc addresses.

=item B<ALL>

The keyword ALL also means to include I<all> Bcc addresses.

=item B<NONE>

The keyword NONE means to include I<no> Bcc addresses. This is the default.

=item B<address>

The argument must be the actual email address, not the phrase preceding it
in the email.

=item B<alias>

An alias from an alias file specified with the B<-a>; this stands for all
actual email addresses associated with the alias.

=item B<~address>

Preceding an email address or an alias with a tilde means that
this address should be I<excluded> from the output.

=back

The option B<-H bcc> has the same effect as B<-B ALL>, i.e., it will
include all Bcc headers. However, if B<-B> options are present on the
commandline, an option B<-H bcc> will be ignored.

=head2 FILENAME FORMAT

The names of the generated files can be specified with a format string which
can contain escape sequences to include date/time elements as well as
various elements from the email. For a description of these format strings,
see the documentation of the module I<Mail::PrettyPrint::Format>.

The filename extension may not be specified in the format string supplied
to the B<-f> option. Generated PDF files get an extension I<.pdf>, generated
text files get an extension I<.txt> appended to the filename specified with
the format.

The default filename format is '%Y-%m-%d_@3n_@F_mail'.

=head2 EMAIL SELECTION

With the option B<-S> you can select a subset of the emails from the mail
box(es) that have to be processed. The option B<-S> is followed by an
argument of the form I<key>=I<value>. 

Emails can be selected on basis of their timestamp with the following keys:

=over

=item I<date> selects all emails on that date.

=item I<before> selects all emails on or before that date.

=item I<after> selects all emails on or before that date.

=back

Only the date portion of the timestamp is used, and it is interpreted
in the used timezone. The values of these keys must be a date in
ISO8601 format; see the B<DateTime::Format::ISO8601> module for the
recognized formats.

Emails can further be selected on basis of their sender and/or receiver(s):

=over

=item I<from> selects all emails from that sender.

=item I<to> selects all emails with the address in the B<To:> field.

=item I<cc> selects all emails with the address in the B<Cc:> field.

=item I<bcc> selects all emails with the address in the B<Bcc:> field.

=item I<dest> selects all emails with the address in either the B<To:> or in
the B<Cc:> field, i.e., as a publicly known recipient.

=item I<bdest> selects all emails with the address in either the B<To:>,
B<Cc:> or B<Bcc:> field, i.e., as a recipient.

=back

The value of these keys must be either an email address or an alias from the
alias file. In case of an alias, it expands to the list of email addresses
and all emails are selected where any one of those addresses matches.

The option B<-S> can be repeated, with different keys. In that case, those
emails are selected that match I<all> selection criteria, i.e., a logical
AND of the selection criteria is performed. Combining a I<dest> or I<bdest>
selection with a I<to>, I<cc> and/or I<bcc> selection may therefore give an
unexpected result.
If the B<-S> option is repeated with the same key, the last specified
value overrides the earlier one(s).

=head2 LAYOUT

TODO

=head2 DEBUG OUTPUT

The argument for the debug flag B<-d> is a bitwise OR of the following
values:

=over

=item 1
Not assigned

=item 2
Debug output about format strings

=item 4
Debug output about finding the various parts of an email

=item 8
Debug output about line wrapping

=item 16
Debug output about Bcc addresses and alias files

=item 32
Debug output about selection of emails from an Mbox

=item 64
Debug output about PDF file generation

=item 128
Debug output about PDF file layout

=back

=head1 EXIT CODE

The exit code is the number of failures to (a) open a mailbox or (b) write
an output file.

=head1 BUGS

Undoubtedly.

=head1 AUTHOR

(c) 2015 Daniel Tuijnman

=cut


use POSIX qw/setlocale LC_ALL LC_TIME/;
use Cwd qw/cwd getcwd realpath/;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::TimeZone;
use File::Spec;
use Getopt::Long qw/:config
    no_getopt_compat gnu_compat no_ignore_case require_order/;
use Pod::Usage;
use Encode;
use Mail::Box;
use Mail::Box::Manager;
use Mail::Box::Mbox;
use Mail::Box::Mbox::Message;
use Mail::Message;
use Mail::Address;
use Mail::PrettyPrint::Localization
    qw/getDefaultLocale getDefaultTimezone
       setDefaultLocale setDefaultTimezone/;
use Mail::PrettyPrint::Format;
use Mail::PrettyPrint::PdfFile;

#
# FORWARD DECLARATIONS
# the bodies of the subroutines are at the end of the script
#
sub readAliasFile($);
sub expandAlias($);
sub findMainAndAttachments($$@);
sub askConfirmation($);

our $VERSION = v1.1.2;
my %options = (
    alias       => undef
  , Attachments => undef
  , Bcc         => undef
  , debug       => 0
  , force       => 0
  , Format      => '%Y-%m-%d_@3n_@F_mail'
  , help        => 0
  , Header      => []
  , interactive => 0
  , locale      => undef
  , Layout      => undef
  , man         => 0
  , MessageID   => 0
  , outputdir   => ""
  , papersize   => 'A4'
  , quiet       => 0
  , Select      => {}
  , text        => 0
  , Textonly    => 0
  , verbose     => 0
  , xhtml       => 0
  , zone        => undef
);
# in order to make the debug value visible to the modules
our $debug = 0;

#
# alle bekende headers
# de keys in de hash zijn genormaliseerd op lower case
# de values in de hash zijn de standaard tekst die afgedrukt wordt
#
my %knownHeaders = (
    'archived-at'               => 'Archived-At'
  , 'authentication-results'    => 'Authentication-Results'
  , 'auto-submitted'            => 'Auto-Submitted'
  , 'bcc'                       => 'Bcc'
  , 'cc'                        => 'Cc'
  , 'content-disposition'       => 'Content-Disposition'
  , 'content-language'          => 'Content-Language'
  , 'content-length'            => 'Content-Length'
  , 'content-transfer-encoding' => 'Content-Transfer-Encoding'
  , 'content-type'              => 'Content-Type'
  , 'date'                      => 'Date'
  , 'dkim-signature'            => 'DKIM-Signature'
  , 'domainkey-signature'       => 'DomainKey-Signature'
  , 'from'                      => 'From'
  , 'importance'                => 'Importance'
  , 'in-reply-to'               => 'In-Reply-To'
  , 'lines'                     => 'Lines'
  , 'message-id'                => 'Message-ID'
  , 'mime-version'              => 'MIME-Version'
  , 'organization'              => 'Organization'
  , 'precedence'                => 'Precedence'
  , 'received'                  => 'Received'
  , 'received-spf'              => 'Received-SPF'
  , 'references'                => 'References'
  , 'reply-to'                  => 'Reply-To'
  , 'return-path'               => 'Return-Path'
  , 'sender'                    => 'Sender'
  , 'status'                    => 'Status'
  , 'subject'                   => 'Subject'
  , 'thread-index'              => 'Thread-Index'
  , 'to'                        => 'To'
  , 'user-agent'                => 'User-Agent'
  , 'x-mailer'                  => 'X-Mailer'
  , 'x-mimeole'                 => 'X-MimeOLE'
  , 'x-ms-tnef-correlator'      => 'X-MS-TNEF-Correlator'
  , 'x-originalarrivaltime'     => 'X-OriginalArrivalTime'
  , 'x-original-to'             => 'X-Original-To'
  , 'x-originating-ip'          => 'X-Originating-IP'
  , 'x-priority'                => 'X-Priority'
  , 'x-sourceip'                => 'X-SourceIP'
  , 'x-spam-level'              => 'X-Spam-Level'
  , 'x-spam-score'              => 'X-Spam-Score'
  , 'x-spam-status'             => 'X-Spam-Status'
  , 'x-status'                  => 'X-Status'
  , 'x-ziggosmtp-mailscanner'               => 'X-ZiggoSMTP-MailScanner'
  , 'x-ziggosmtp-mailscanner-from'          => 'X-ZiggoSMTP-MailScanner-From'
  , 'x-ziggosmtp-mailscanner-id'            => 'X-ZiggoSMTP-MailScanner-ID'
  , 'x-ziggosmtp-mailscanner-information'   =>
                            'X-ZiggoSMTP-MailScanner-Information'
  , 'x-ziggosmtp-mailscanner-spamcheck'     =>
                            'X-ZiggoSMTP-MailScanner-SpamCheck'
);

# TODO: bovenstaande hash vervangen door:
#my @knownheaders = (...);
#my %knownheaders = map { lc $_, $_ } @knownheaders;

GetOptions \%options,
    "alias=s", "Attachments:i", "Bcc:s@", "debug:i", "Format=s", "help",
    "Header=s@", "interactive", "locale=s", "Layout=s%", "man", "MessageID",
    "outputdir=s", "papersize=s", "quiet+", "Select=s%",
    "text", "Textonly", "verbose+", "xhtml|xml", "zone|timezone=s"
    or pod2usage { -exitval => 1, -verbose => 0 };
pod2usage { -exitval => 1, -verbose => 2 } if $options{man};
pod2usage { -exitval => 1, -verbose => 1 } if $options{help};

# check if there are filenames left
if ( ! @ARGV ) {
    print STDERR "No filenames given\n";
    pod2usage { -exitval => 1, -verbose => 1 };
}

#
# CHECK and PROCESS the OPTIONS
#

# OPTION debug: put the debug value in the global variable to make it
# visible to modules
$debug = $options{debug};

# OPTION locale
my $lc;
if ($options{locale} ) {
    $lc = setDefaultLocale($options{locale});
} else {
    $lc = getDefaultLocale();
}
# OPTION (time)zone
my $tz;
if ( $options{zone} ) {
    $tz = setDefaultTimezone($options{zone});
} else {
    $tz = getDefaultTimezone();
}
 
# OPTION outputdir
if ( $options{outputdir} && ! -d $options{outputdir} ) {
    print STDERR "No valid directory: $options{outputdir}\n";
    exit 2;
}
# OPTION Attachments: it sometimes has wrong values
# 0 (no argument) and 1 (argument 1) mean the same
if ( defined $options{Attachments} ) {
    $options{Attachments} = 1 if $options{Attachments} == 0;
} else {
    $options{Attachments} = 0;
}

# OPTION papersize
if ( ! Mail::PrettyPrint::PdfFile->checkPapersize($options{papersize}) ) {
    die "Unrecognized papersize: $options{papersize}\n";
}

# OPTION alias
#
my %aliases;
if ( $options{alias} ) {
    my $aliasfn = $options{alias};
    if ( ! -f $aliasfn ) {
        die "Alias file $aliasfn does not exist";
    } elsif ( ! -r _ ) {
        die "Alias file $aliasfn not readable";
    }
    readAliasFile($aliasfn);
}

# OPTIONS Bcc, MessageId, Header
#
# Headers From, To and Cc are treated separately in the body of the script
# Header Bcc also has a special treatment
# The array @headers contains the list of headers that must be printed,
# with the names normalized in lower case.
# The hash %headers contains the values to be printed
#
my %headeropts = map { lc $_, 1 } @{$options{Header}};
my @headers;
# include the standard headers
my %headers = ( from => 'From', to => 'To', cc => 'Cc' );
my $printbcc = 0;

# First treat the special case of the Bcc header
my $bccfilter = sub { 0 };
if ( $options{Bcc} ) {
    my $bccdefault = 0;
    my %bcchash;
    my @bcclist = map { split /,/ } @{$options{Bcc}};
    foreach my $item ( @bcclist ) {
        if ( $item eq '' or $item eq 'ALL' ) {
            %bcchash = ();
            $bccdefault = 1;
        } elsif ( $item eq 'NONE' ) {
            %bcchash = ();
            $bccdefault = 0;
        } else {
            my $add = 1;
            if ( $item =~ /^\~/ ) {
                $add  = 0;
                $item =~ s/\~//;
            }
            my @addrs = expandAlias($item);
            foreach my $addr ( @addrs ) {
                $bcchash{$addr} = $add;
            }
        }
    }
    if ( $options{debug} & 16 ) {
        print STDERR "bccdefault = $bccdefault\n";
        print STDERR "bcchash contains:\n";
        foreach my $key ( keys %bcchash ) {
            print STDERR "  $key => $bcchash{$key}\n";
        }
    }
    $bccfilter = sub {
        my $addr = shift;
        my $res = exists $bcchash{$addr} ? $bcchash{$addr} : $bccdefault;
        if ( $options{debug} & 16 ) {
            print "bccfilter called with $addr, result is $res\n";
        }
        $res;
    };
    $printbcc = 1;
} elsif ( $headeropts{bcc} || $headeropts{all} ) {
    $bccfilter = sub { 1 };
    $printbcc = 1;
}
# Second, push the subject and date on the list of to-be-printed headers
foreach my $head ( qw/subject date/ ) {
    push @headers, $head;
    $headers{$head} = $knownHeaders{$head};
}
# Third, process options to include the message-ID
if ( $options{MessageID} || $headeropts{"message-id"} || $headeropts{all} ) {
    push @headers, 'message-id';
    $headers{'message-id'} = $knownHeaders{'message-id'};
}
# Fourth, treat the remaining header options
foreach my $head ( @{$options{Header}} ) {
    my $lchead = lc $head;
    next if $lchead eq 'bcc' or $lchead eq 'message-id';
    if ( $headers{$lchead} ) {
        warn "Header $lchead already included, ignored\n"
            if $options{quiet} < 1;
        next;
    }
    if ( $lchead eq 'all' ) {
        foreach my $khk ( sort keys %knownHeaders ) {
            if ( not exists $headers{$khk} ) {
                push @headers, $khk;
                $headers{$khk} = $knownHeaders{$khk};
            }
        }
        # process further -H options for warnings
        next;
    }
    if ( my $knownHeader = $knownHeaders{$lchead} ) {
        # als het cmdline argument geheel lower case is, gebruik de
        # standaard schrijfwijze, anders neem die over van de cmdline
        push @headers, $lchead;
        if ( $head eq $lchead ) {
            $headers{$lchead} = $knownHeader;
        } else {
            if ( $head ne $knownHeader && ! $options{quiet}) {
                warn "Header $head overrides standard spelling $knownHeader\n"
                    if $options{quiet} < 1;
            }
            $headers{$lchead} = $head;
        }
    } else {
        warn "Unknown header: $lchead\n"
            if $options{quiet} < 1;
        push @headers, $lchead;
        $headers{$lchead} = $head;
    }
}
if ( $options{debug} & 16 ) {
    print "headers: @headers\n";
}

# OPTION Select
my @select_date_keys = qw/date before after/;
my %select_date_comp = ( date => 'eq', before => 'le', after => 'ge' );
my @select_addr_keys = qw/from to cc bcc dest bdest/;
my %select_keys = (
    (map { $_, 1 } @select_date_keys),
    (map { $_, 2 } @select_addr_keys)
);
# $select_fun is a function which takes two arguments:
# 1) a Mail::Message 
# 2) a Mail::PrettyPrint::Box object
# and returns a boolean
# default, we select all emails
my $select_fun  = sub { 1 };
my %select_funs;
foreach my $key ( keys %{$options{Select}} ) {
    if ( ! exists $select_keys{$key} ) {
        warn "Option --Select: key $key not recognized, ignored\n"
            if $options{quiet} < 1;
        next;
    }
    if ( $select_keys{$key} == 1 ) {
        # now process the given date
        my $sd = DateTime::Format::ISO8601->parse_datetime(
            $options{Select}{$key}
        );
        $sd->set_time_zone($tz);
        $select_funs{$key} = eval 'sub { my ($msg, $box) = @_; '
            . '$box->getTimestamp($msg)->ymd() '
            . $select_date_comp{$key}
            . ' $sd->ymd() }';
    } else {
        my @addrs = expandAlias $options{Select}{$key};
        my %addrs = map { $_, 1 } @addrs;
        if ( $key eq 'dest' ) {
            $select_funs{$key} = sub {
                # Mail::Message does not have a single method to select the
                # combination of To: and Cc: addresses
                my $msg = shift;
                foreach my $from ( map { $_->address() }
                                       $msg->to(), $msg->cc() ) {
                    return 1 if $addrs{$from};
                }
                0;
            };
        } else {
            my $msgfun = $key;
            $msgfun = 'destinations' if $key eq 'bdest';
            $select_funs{$key} = sub {
                my $msg = shift;
                foreach my $from ( map { $_->address() } $msg->$msgfun() ) {
                    return 1 if $addrs{$from};
                }
                0;
            };
        }

    }
}
if ( keys %select_funs ) {
    $select_fun = sub {
        foreach my $key ( keys %select_funs ) {
            return 0 if ! $select_funs{$key}->(@_);
        }
        1;
    };
}



# OPTION Format
my $fn_fmt;
eval {
    $fn_fmt = Mail::PrettyPrint::Format->new($options{Format});
};
if ( $@ ) {
    die "Filename format $options{Format} is not correct", $@;
} elsif ( $fn_fmt->hasPagenr() ) {
    die "Filename format $options{Format} contains page numbers\n";
}

#
# MAIN SCRIPT
#

my $mgr = Mail::Box::Manager->new();
my %gen_filenames;
my %gen_msgid;

# klein experiment met een tekst linksboven
#my $left_fmt = Mail::PrettyPrint::Format->new( fmtstr => '@s' );
my $left_fmt = Mail::PrettyPrint::Format->new( fmtstr => '%d %B %Y, %H:%M:%S' );

my $exitcode = 0;

foreach my $infile ( @ARGV ) {
    if ( ! -f $infile ) {
        print STDERR "No such file: $infile, skipped\n";
        next;
    }
    my $folder = $mgr->open( folder => $infile );
    if ( ! $folder ) {
        warn "Could not open mail folder $infile, skipping\n"
            if $options{quiet} < 2;
        $exitcode++;
        next;
    }
    if ( $debug & 1 ) {
        print STDERR "Class of folder: ", ref $folder, "\n";
        #print STDERR "Attrs of folder: @{[%$folder]}\n";
        print STDERR "Attrs of folder:\n";
        foreach my $k ( keys %$folder ) {
            print STDERR "\t$k => $folder->{$k}\n";
        }
    }
    
    use sigtrap 'handler' => sub { $folder->DESTROY(); die; }, 'normal-signals';
    if ( $options{verbose} ) {
        print STDERR "Processing folder $infile\n";
        print STDERR "Number of messages: ", $folder->nrMessages(), "\n";
        print STDERR "MessageIDs: @{[$folder->messageIds()]}\n";
    }

    my $box = Mail::PrettyPrint::Box->new(
        folder => $folder, locale => $lc, timezone => $tz
    );
    my $outdir;
    if ( $options{outputdir} ) {
        $outdir = $options{outputdir};
    } else {
        my $absinfile = realpath $infile;
        (my $vol, $outdir, my $fil) = File::Spec->splitpath($absinfile);
    }
    print STDERR "Output dir: $outdir\n" if $options{verbose} > 1;

#    # make a formatter
#    my $fn_formatter = Mail::PrettyPrint::FormatMbox->new( 
#        fmt => $fn_fmt , mbox => $mbox
#    );

    # check if the format is unique
    # TODO: extend to checking if the format is unique for the selection
    # of messages
    # TODO: think of a way to check if the format is unique over ALL mboxes
    # on the command line
    if ( not $box->isUnique($fn_fmt) ) {
        my $msg = <<MSG;
Filename format $options{Format} is not unique in folder $infile\n
MSG
        if ( $options{force} ) {
            warn $msg;
        } else {
            die $msg;
        }
    }

    my @msgs = $box->getMessages($select_fun);
    foreach my $msg ( @msgs ) {
        my $head = $msg->head;
        my $body = $msg->body;
        my $msgid = $msg->get('message-id');
        if( ! $select_fun->($msg, $box) ) {
            print STDERR "Message $msgid not selected" if $options{verbose};
            next;
        }
        if ( $options{verbose} ) {
            print STDERR "MessageID ", $msgid,
                "\n\tTimestamp: ", $msg->timestamp(),
                "\n\tTo: ", $head->get('To'),
                "\n\tCc: ", $head->get('Cc'), "\n";
        }
        my $bmsg    = Mail::PrettyPrint::BoxMessage->new(
            msg => $msg, locale => $lc, timezone => $tz
        );
        my $outfile = $fn_fmt->format($bmsg);
        my $outpath = File::Spec->catdir($outdir, $outfile);
        print STDERR "Output file: $outpath\n" if $options{verbose} > 1;
        if ( $gen_msgid{$msgid} ) {
            warn "Duplicate message-ID: $msgid\n"
                if $options{quiet} < 1;
        }
        $gen_msgid{$msgid} = 1;
        if ( $gen_filenames{$outpath} ) {
            if ( $options{quiet} < 2 ) {
                warn "File $outpath has already been generated, skipping\n";
                if ( $gen_filenames{$outpath} ne $msgid ) {
                    warn "   was for a different message\n";
                }
            }
            next;
        }
        $gen_filenames{$outpath} = $msgid;

        # first generate text file if asked
        if ( $options{text} || $options{Textonly} ) {
            my $txtpath = $outpath . ".txt";
            my $write_txt = 1;
            if ( -f $txtpath ) {
                if ( $options{interactive} ) {
                    $write_txt = 0 unless askConfirmation(
                        "Do you want to overwrite the existing file $txtpath? "
                    );

                } elsif ( $options{quiet} < 1 ) {
                    warn "Outputfile $txtpath already exists, overwriting\n";
                }
            } elsif ( -e $txtpath ) {
                warn "Another non-file object $txtpath exists, skipping\n"
                    if $options{quiet} < 2;
                $exitcode++;
                $write_txt = 0;
            }
            if ( $write_txt ) {
                open TXT, ">", $txtpath or die "Cannot open file $txtpath";
                $msg->print(\*TXT);
                close TXT;
            }
        }
        # skip PDF file if Textonly
        next if $options{Textonly};

        # generate PDF file
        my $pdfpath = $outpath . ".pdf";
        if ( -f $pdfpath ) {
            if ( $options{interactive} ) {
                next unless askConfirmation(
                    "Do you want to overwrite the existing file $pdfpath? "
                );

            } elsif ( $options{quiet} < 1 ) {
                warn "Outputfile $pdfpath already exists, overwriting\n";
            }
        } elsif ( -e $pdfpath ) {
            warn "Another non-file object $pdfpath exists, skipping\n"
                if $options{quiet} < 2;
            $exitcode++;
            next;
        }

        my $left_text = $left_fmt->format($bmsg);
        print STDERR "main:: left_text is $left_text\n"
            if $options{debug} & 128;
        # TODO: exception handling
        my $pdf = Mail::PrettyPrint::PdfFile->new(
            filename    => $pdfpath
          , msg         => $bmsg
          , papersize   => $options{papersize}
          , head_left   => $left_text
          , head_right  => '(@p/@P)'
        );
        my $ts = $msg->timestamp();
        my $dt = DateTime->from_epoch(
            epoch => $ts, time_zone => $tz, locale => $lc
        );
         
        # kennelijk kunnen er meer 'From' zijn dus maken we hier een lijstje
        $pdf->printHeader("From", map { $_->format() } $msg->from());
        $pdf->printHeader("To",   map { $_->format() } $msg->to());
        $pdf->printHeader("Cc",   map { $_->format() } $msg->cc());
        if ( $printbcc ) {
            print STDERR "check bcc headers\n" if $options{debug} & 16;
            $pdf->printHeader("Bcc",
                map { $_->format() }
                    grep { $bccfilter->($_->address()) }
                        $msg->bcc());
        }
        foreach my $head ( @headers ) {
            foreach my $cont ( $msg->head()->study($head) ) {
                $pdf->printHeader("$headers{$head}", $cont);
            }
        }

        # ontleed nu de message in de main inhoud en de attachments
        my ($mainMsg, @attachments) = findMainAndAttachments $msg, 0;
        if ( ! defined $mainMsg ) {
            warn "Main message not found, messageId: ", $msg->messageId(), "\n"
                if $options{quiet};
            # close the PDF file
            $pdf->close();
            next;
        }
        my @att_names = map { $_->body()->dispositionFilename() }
            @attachments;
        if ( $options{debug} & 4 ) {
            foreach my $name ( @att_names ) {
                print STDERR "Attachment name: $name\n";
            }
        }
        if ( $options{Attachments} == 1 ) {
            $pdf->printAttachments(@att_names);
        }
        my $decoded = $mainMsg->decoded();
        my @lines   = $decoded->lines();
        
        if ( $options{debug} & 8 ) {
            print STDERR "Lines:\n+ ", join("+ ", @lines), "\n";
        }
#        foreach my $line ( @lines ) {
#            chomp $line;
#            my @wraplines = wrapLine $line;
#            $psf->printLines(@wraplines);
#        }
        # test: call printLine line-per-line instead of the whole batch
#        foreach my $line ( @lines ) {
#            $pdf->printLine($line);
#        }
        $pdf->printLines(@lines);
        if ( $options{Attachments} > 1 ) {
            $pdf->printAttachments(@att_names);
        }
        $pdf->close();
    }
}

exit $exitcode;

#
# SUBROUTINES
#

#
# Subroutine: readAliasFile
# Arguments:
#   1) the name of the alias file
# Return value: success
# Description:
#   This subroutine reads in the alias file and expands the aliases into the
#   script-wide variable %aliases. The values in the hash are a list of
#   email addresses.
#   At the moment, this routine can only cope with bare email addresses,
#   not with phrases.
# TODO:
#   The routine can only handle a simple alias file format, with lines
#   of the form
#   alias key address [, address [...] ]
#   where each address is a simple email address, not containing a phrase.
#
sub readAliasFile($) {
    my $fn = shift;
    print STDERR "Reading alias file $fn\n" if $options{debug} & 16;
    open ALIAS, "<", $fn or die "Cannot open alias file $fn";
    my $lines = join '', <ALIAS>;
    close ALIAS;
    $lines =~ s/\\\n//g;
    my @lines = split /\n/, $lines;
    foreach my $line ( @lines ) {
        chomp $line;
        print STDERR "  processing line $line of alias file\n"
            if $options{debug} & 16;
        my ($aword, $key, $addrs) = split ' ', $line, 3;
        print STDERR "  key is $key\n" if $options{debug} & 16;
        next if $aword ne 'alias';
        delete $aliases{$key};  # so we overwrite a previous definition
        my @addrs = split /\s*,\s*/, $addrs;
        print STDERR "  addresses are: ", join('|', @addrs), "\n"
            if $options{debug} & 16;
        $aliases{$key} = \@addrs;
    }
    if ( $options{debug} & 16 ) {
        print STDERR "  Aliases hash:\n";
        foreach my $key ( keys %aliases ) {
            print STDERR "  $key => @{$aliases{$key}}\n";
        }
    }
    # success
    1;
}

#
# Subroutine: expandAlias
# Arguments:
#   1) an alias (or not)
# Return value:
#   - the list of email addresses associated with the alias
#   - the argument if it is not an alias
# Description:
#
sub expandAlias($) {
    my $alias = shift;
    $aliases{$alias} ? @{$aliases{$alias}} : $alias;
}

#
# Subroutine: findMainAndAttachments
# Arguments:
#   1) a Mail::Message or Mail::Message::Part object
#   2) the recursion depth
#   3) the partial list of found return values
# Return value: a list of Part's
#   - the first Part from the list is the main message
#   - the other items in the list are the message's attachments
#   If the main message is not found, the return value is undef
# Description:
#   This subroutine descends the tree of message parts and finds the plain
#   text version of the body, along with the attachments.
#
sub findMainAndAttachments($$@) {
    my ($msg, $depth, @ret) = @_;
    if ( $options{debug} & 4 ) {
        print STDERR "  " x $depth, "Entering findMainAndAttachments\n";
        print STDERR "  " x ($depth+1), "Lengte returnlijst: " . @ret . "\n";
        print STDERR "  " x ($depth+1), "Main message undefined\n"
            if @ret && ! defined $ret[0];
    }
    @ret = (undef) if ! @ret;
    my $body = $msg->body();
    if ( $msg->isMultipart() ) {
        if ( $options{debug} & 4 ) {
            print STDERR "  " x ($depth+1), "Message is multipart, mimetype ",
                $body->mimeType(), "\n";
        }
        my @parts = $msg->parts();
        foreach my $part ( @parts ) {
            if ( $options{debug} & 4 ) {
                print STDERR "  " x ($depth+1), "Recursieve aanroep voor part\n";
            }
            @ret = findMainAndAttachments $part, $depth+1, @ret;
        }
    } else {
        if ( $options{debug} & 4 ) {
            print STDERR "  " x ($depth+1), "Message is simple, mimetype ",
                $body->mimeType(), "\n";
        }
        if ( $body->disposition() =~ m#^attachment#i ) {
            push @ret, $msg;
            if ( $options{debug} & 4 ) {
                print STDERR "  " x ($depth+1), "Attachment found\n";
            }
            if ( ! defined $ret[0] && $options{quiet} < 1 ) {
                warn "Attachment found before main message, messageID: ",
                    $msg->messageId(), "\n";
            }
        } else {
            if ( defined $ret[0] ) {
                if ( $options{debug} & 4 ) {
                    print STDERR "  " x ($depth+1), "Message part skipped\n";
                }
            } else {
                my $mime = $body->mimeType();
                if ( $mime eq 'text/plain' ) {
                    $ret[0] = $msg;
                    if ( $options{debug} & 4 ) {
                        print STDERR "  " x ($depth+1), "Main message found\n";
                    }
                } elsif ( $mime eq 'text/html' && $options{quiet} < 1 ) {
                    warn "HTML part found before plain text, messageID ",
                        $msg->messageId(), "\n";
                } elsif ( $mime =~ m#^text/# && $options{quiet} < 1 ) {
                    warn "Unknown text type: ", $mime,
                        " found before plain text, messageID ",
                        $msg->messageId(), "\n";
                } elsif ( $options{quiet} < 1 ) {
                    warn "Strange mime type: ", $mime,
                        " found before plain text, messageID ",
                        $msg->messageId(), "\n";
                }
            }
        }
    }
    if ( $options{debug} & 4 ) {
        print STDERR "  " x $depth, "Exiting findMainAndAttachments met ",
            @ret - 1, " attachments\n";
    }
    @ret;
}

sub askConfirmation($) {
    my $msg = shift;
    my $res = undef;
    select STDERR;
    $| = 1;
    do {
        print $msg;
        my $in = <STDIN>;
        chomp $in;
        my $lin = lc $in;
        $res = 1 if $lin eq 'y' or $lin eq 'yes';
        $res = 0 if $lin eq 'n' or $lin eq 'no';
    } until defined $res;
    select STDOUT;
    $res;
}

