package Mail::PrettyPrint::PdfFile;

use strict;
use warnings;

#
# (c) 2015, Daniel Tuijnman, Netherlands
#
# $Id: PdfFile.pm,v 1.21 2016/10/10 16:12:39 daniel Exp daniel $
#
# Module that generates PDF for pretty printing emails
#
### TODO LIST:
#  5. support other font sizes, also in the constructor
#  8. check on encoding errors
#  9. implement other character encodings (???)
# 11. implement mirroring even/odd pages
# 21. check minimal margin values
# 22. refine font height calculations. For all these calculations,
#     we now approximate the max height of a glyph to be the pointsize above
#     the baseline, and none below.
# 23. OPTION: intelligent line wrapping with multiple lines:
#     collapse multiple lines with identical quoting and fill them out
#     see Damian Conways module Text::Autoformat?
# 28. split off all layout issues into a separate module Layout:
#     the fonts and font sizes and the appearance of the head/foot texts
# 29. check what goes into the PDF properties
# 32. make an option for repeating quotes
# 34. create a separate class for defining the selection and order of
#     headers and place of attachments, let's say ContentSelection
# 35. combine ideas (28) and (34) so that the interface shrinks
#     to just a constructor which gets a Mail::Message, a Layout and a
#     ContentSelection, and a method print() which actually produces the
#     output.
# 37. support generation from the HTML body
# 38. treat 'filename' and footer/header text arguments equally?
# 39. 
#

=head1 NAME

Mail::PrettyPrint::PdfFile - pretty printing email to PDF

=head1 SYNOPSIS

    use Mail::PrettyPrint::PdfFile;

    $pdf = Mail::PrettyPrint::PdfFile->new(
        filename    => 'email.pdf',
        message     => $msg,
        head_left   => '25-07-2014',
        head_center => 'Subject: birthday',
        papersize   => 'A4',
        encoding    => 'latin-9',
    );
    $pdf->printHeader( 'To', 'John', 'Paul', 'George', 'Ringo' );
    $pdf->printAttachments( 'revenue.xls', 'balance.xls' );
    $pdf->printLine("Dear Sirs");
    $pdf->printLines("Yours truly,", "", "John Smith");
    $pdf->close();

    my $p = $pdf->getPageNumber()
    my $q = $pdf->getPageCount()

=head1 DESCRIPTION

This module supports pretty printing an email message into a PDF file.
The pretty printed message may contain a header with up to three boxes,
as well as a footer with up to three boxes. If none of the content values of
the boxes of the header is defined, the header is left out completely; ditto
for the footer. The default value for the right-hand-side box of the header
is the page number enclosed in parentheses.

The text of the left and center boxes is free and can be chosen by the user.
It is, however, identical for all pages of the email.

The text of the email headers is printed in a bigger font than
the email body, and the names of the header lines are printed in bold.
Headers which contain multiple lines, e.g., the B<To:> and B<Cc:> headers,
are printed one item per line, and the subsequent items indented to the same
position as the content on the first line.

Furthermore, a list of the attachments to the email can be printed. This can
be done either after the headers but before the body, or after the body. An
attempt to print the attachments a second time will be ignored.

The various print functions must be called in order, i.e., first the
headers, then optionally the attachments, then the body, and then optionally
the attachments. An attempt to print a part of the message out of order will
result in an abort of the script.

=head1 CONSTRUCTOR

The constructor takes a number of number of named arguments. 
The constructor automatically opens the file. 
Required arguments for the constructor are:

=over

=item B<filename>

Name of the PDF file to generate. If the filename does not end in
".pdf", it is automatically appended to the filename.

The argument may also be a B<Mail::PrettyPrint::Format> object, in which
case it is evaluated to give the filename, and also ".pdf" appended at the
end if applicable.

=item B<message>

The mail message this PDF file is constructed for.

=back

Optional arguments to the constructor are:

=over

=item B<encoding>

Encoding to be used in the PDF file. Default is WinAnsiEncoding, also known
as Windows CP 1252. This is a superset of Latin-1 and contains all
characters from Latin-15.
B<Not yet implemented, ignored>

=item B<papersize>

Size of the paper. Default is A4.

=item B<mirror>

Do the even and odd pages have to be mirrored. Default is no.
B<Not yet implemented, ignored>

=item B<repeatquotes>

Repeat the leading quotes when wrapping a line. Default is no.

=item B<head_left>, B<head_center>, B<head_right>:

Texts to be printed in three boxes in the page header.
The value can be either a B<Mail::PrettyPrint::Format> object or a string.
If the value is a string, it is interpreted as a format string.

When mirroring is set, the directions I<left> and I<right> apply to the
odd-numbered pages. On the even numbered pages, the I<head_left> text will
be printed top right, etc.

=item B<foot_left>, B<foot_center>, B<foot_right>:

Texts to be printed in three boxes in the page footer. 
The same applies as to the header texts above.

=back

=head1 METHODS

=head2 ACCESSOR METHODS

=over

=item B<getPageNumber>()

Returns the current page number in the PDF file.

=item B<getPageCount>()

Returns the total number of pages in the PDF file.

=back

=head2 PRINTING METHODS

=over

=item B<printHeader>( HEADER, TEXT... )

Print an email header. The name of the header is printed in bold, followed
by a colon. The content of the header is a list, e.g., a list of addresses
in case of the B<To:> header. These items are printed one at a line,
separated by commas, and each subsequent line is indented to the start of
the first text.

=item B<printAttachments>( NAME... )

Prints a list of attachment names in the same fashion as a header is
printed, with the word B<Attachments> as the "header name". This method may
be called after the headers but before the email body, in which case the
method produces a blank lined above and below the attachment line(s);
or it may be called after the body, in which case it produces a blank
line between the body and the attachment line(s).

=item B<printLine>( LINE )

Prints one line of the body of the email.

=item B<printLines>( LINE... )

Prints a list of lines of the body of the email.

=item B<close>()

Closes the object and writes the PDF file.

=back

=head2 CLASS METHODS

=over

=item B<checkPapersize>( SIZE )

Checks if the argument is a valid papersize and if successful, returns a
canonical version. Valid papersizes can be:

=over

=item B<*> a symbolic name of a papersize, e.g., "A4" or "Letter" as
recognized by B<PDF::API2> are supported.

=item B<*> the symbolic name "A4L" for A4 landscape.

=item B<*> a reference to an array with the width and the height in points.

=item B<*> a string with the width and height, e.g., "7in,25.4cm".
Recognized units are: "in" for inches, "pt" for points, "cm" and "mm". The
separator between the two measurements may be a comma or a 'x'.

=back

The symbolic names are case insensitive. The canonical version returned is
either a symbolic name recognized by B<PDF::API2> or an array with width and
height.

=back

=head1 LIMITATIONS AND BUGS

=over

=item B<fonts>

The current implementation does not allow to choose other fonts.

=item B<font encoding>

The PDF fonts are loaded with the default encoding used in the B<PDF::API2>
modules, i.e., with CP1252 alias WinAnsiEncoding. This excludes some code
points which are present in the core fonts. See Appendix D1 from the PDF
reference which lists the code points in the AdobeStandardEncoding and
PDFDocEncoding.

There is the wider issue that the module does not check whether the printed
strings can be encoded in the font at all.

=item B<footer and header>

The implementation cannot cope with most format strings for footer and
header texts as it has no access to the email message.

=back


=head1 AUTHOR

(c) 2015-2016 Daniel Tuijnman

=cut

use Carp;
use IO::File;
use File::Spec;
use File::Which;
use Scalar::Util qw/blessed/;
# TODO: eventually remove including Encode - not actually used at the moment
use Encode;
use Mail::PrettyPrint::Localization;
use Mail::PrettyPrint::Format;
use Mail::PrettyPrint::BoxMessage;
use PDF::API2;
use PDF::API2::Resource::PaperSizes;

use base 'Mail::PrettyPrint::BoxMessage';

our $VERSION = v1.2.1;

#
# The PDF file is made in three phases.
#
# Phase 1 occurs during 'new' and possible future methods to set various
# layout parameters.
# In this phase, only the layout is calculated.
#
# Phase 2 is the actual insertion of the text of the email by the execution
# of the 'print' methods.
#
# Phase 3 occurs during 'close'.
# In this phase, the headers and footers are added to all the pages.
#
# In the stages below, 'start' refers to phase 1, and 'end' refers to
# phase 3. The other stages refer to various sub-stages of phase2.
# These stages prohibit the user from calling methods out of order,
# e.g., trying to print another mail header when part of the body of
# the message has already been printed.
#

my @stage;
my %stage;
BEGIN {
    @stage = qw/start headers attachm1 body attachm2 end/;
    for my $i ( 0 .. $#stage ) {
        $stage{$stage[$i]} = $i;
    }
}

#
# A Mail::PP::PdfFile object has the following attributes:
# Inherited:
# - msg         a Mail::Message object
# - locale      a DateTime::Locale object
# - timezone    a DateTime::TimeZone object
# - box         a Mail::PrettyPrint::Box
# Required:
# - filename:   the name of the file
# Optional header/footer texts:
#               These values in the hash are the functions that are the
#               result of calling format() on a Mail::PrettyPrint::Format
#               object
# - head_left:  text to print in a box left in the page header
# - head_center: text to print in a box center of the page header
# - head_right: text to print in a box right of the page header,
#               default this is the page number
# - foot_left:  text to print in a box left in the page footer
# - foot_center: text to print in a box center of the page footer
# - foot_right: text to print in a box right of the page footer.
# Optional other values:
# - papersize:  size of the paper, default A4. This is either a name
#               recognized by PDF::API2 or an array of width x height
# - encoding:   encoding to be used in the PDF document
# - mirror:     mirror odd/even pages
# - repeatquotes:   repeat leading quotes when wrapping a line
# Internal attributes:
# - _pdf:       PDF::API2 object
# - _page:      current page in PDF::API2 object
# - _stage:     internal stage of the object - valid key of %stage.
# - _attachm_printed:   boolean if attachments have been printed
# - _pagenr:    the current page number
# - _numpages:  total number of pages, calculated after end of pass 1
# - _current_y: baseline for the current/next line
#               advanced immediately after printing a line
# - _fonts:     a hash of the different fonts used, with keys:
#               - headfoot:     for the page header and footer texts
#               - header:       for a mail header
#               - headername:   for the title of a mail header
#               - body:         for the body of the mail message
#               For the time being, a font is a hash with keys:
#               - name, size, lead
#               - obj: the PDF::API2 font object
# - _margins:   margins to the edge of the paper, in PostScript points
#               a hash with keys:
#               - margin_left
#               - margin_right
#               - margin_top
#               - margin_bottom
# - _headfoot_margins:  margins around the boxes,
#               and the skips between header resp. footer and the body
#               - box_margin_left
#               - box_margin_right
#               - box_margin_top
#               - box_margin_bottom
#               - head_skip
#               - foot_skip
# - _layout:    calculated page layout, in PostScript points:
#               - mediabox: PDF mediabox
#               - artbox:   PDF artbox (after subtracting margins)
#                       order in boxes: llx, lly, urx, ury
#                       origin is lower-left, X is horizontal, Y is vertical
#               - page_height (i.e., height of the artbox)
#               - page_width  (ditto)
#               - body_top_y: baseline for first line of body text
#               - body_bottom_y: lowest possible baseline for body
#               - box_margin_lr: sum of left and right margins for boxes
#               - box_height: height of boxes
#               - hf_left_text_x: LLX coordinate for header/footer left text
#               - hf_center_text_x: LCX coordinate for header/footer center text
#               - hf_right_text_x: LRX coordinate for header/footer right text
#               - head_text_y: Lower Y coordinate for all header texts
#               - foot_text_y: Lower Y coordinate for all footer texts
#               - hf_left_box_x: LLX coordinate for header left box
#               - hf_right_box_x: LRX coordinate for header right box
#               - head_box_y: Lower Y coordinate for all header boxes
#               - foot_box_y: Lower Y coordinate for all footer boxes
#

# aid for indexing in PDF boxes
my ($llx_idx, $lly_idx, $urx_idx, $ury_idx) = 0..3;

my @_req_args = qw/filename/;
my %_headfoot_args = (
    head_left   => undef
  , head_center => undef
  , head_right  => '(@p)'
  , foot_left   => undef
  , foot_center => undef
  , foot_right  => undef
);
my @_headfoot_args = keys %_headfoot_args;
my %_opt_args = (
    papersize   => 'A4'
  , encoding    => 'cp1252'
  , mirror      => 0
  , repeatquotes    => 0
);
my @_opt_args  = keys %_opt_args;

#
# 24 pt is a safe margin for any laser printer
#
my %_min_margins = (
    margin_left     => 24
  , margin_right    => 24
  , margin_top      => 24
  , margin_bottom   => 24
);
my %_default_margins = (
    margin_left     => 36
  , margin_right    => 30
  , margin_top      => 30
  , margin_bottom   => 30
);

my %_default_headfoot_margins = (
    box_margin_left     => 6
  , box_margin_right    => 6
  , box_margin_top      => 3
  , box_margin_bottom   => 6
  , head_skip   => 16
  , foot_skip   => 16
);

my %_default_fonts = (
    headfoot    => { name => 'Helvetica', size => 14, lead => 16.8 }
  , header      => { name => 'Courier', size => 12, lead => 14.4 }
  , headername  => { name => 'Courier-Bold', size => 12, lead => 14.4 }
  , body        => { name => 'Courier', size => 10, lead => 12 }
);

sub init() {
    my $self = shift;
    my %args = @_;
    print STDERR "PdfFile::init called\n" if $main::debug & 1;
    $self->SUPER::init(@_);
    # argument parsing

    # required arguments: filename
    if ( exists $args{filename} ) {
        my $filename = $args{filename};
        if ( blessed $filename ) {
            if ( $filename->isa('Mail::PrettyPrint::Format') ) {
                if ( $filename->hasPagenr() ) {
                    croak __PACKAGE__,
                        "::init: attribute filename contains page number\n";
                }
                $filename = $filename->format($self);
            } else {
                croak __PACKAGE__,
                    "::init: attribute filename has wrong type\n";
            }
        }
        if ( $filename !~ /\.pdf$/ ) {
            warn "Appending .pdf to filename\n";
            $filename .= ".pdf";
        }
        $self->{filename} = $filename;
    } else {
        croak __PACKAGE__, "::init: attribute filename missing\n";
    }
    # optional arguments: header and footer strings
    foreach my $arg ( @_headfoot_args ) {
        my $val = exists $args{$arg} ? $args{$arg} : $_headfoot_args{$arg};
        print STDERR "PdfFile init: $arg has input value ", ($val||""),
            " with ref ", ref $val, "\n" if $main::debug & 64;
        # if the value is not defined, we skip this one
        if ( not defined $val ) {
            $self->{$arg} = undef;
            next;
        }

        # the argument can either be a literal string or a format object
        # in case it is a string, we first make a format object out of it
        if ( not ref $val ) {
            print STDERR "PdfFile init: making Format object for $val\n"
                if $main::debug & 64;
            $val = Mail::PrettyPrint::Format->new($val);
        }
        $self->{$arg} = $val;
    }
    # other optional arguments
    foreach my $arg ( @_opt_args ) {
        if ( exists $args{$arg} ) {
            $self->{$arg} = $args{$arg};
        } else {
            $self->{$arg} = $_opt_args{$arg};
        }
    }
    if ( my $ps = $self->checkPapersize($self->{papersize}) ) {
        $self->{papersize} = $ps;
    } else {
        croak "Papersize $args{papersize} not recognized\n";
    }
    if ( $self->{encoding} ne 'cp1252' ) {
        carp "Encoding $args{encoding} ignored, only CP1252 supported\n";
        $self->{encoding} = 'cp1252';
    }
    if ( $self->{mirror} ) {
        carp "Mirroring not yet supported\n";
    }
#    # warnings about non-existing arguments
#    foreach my $arg ( keys %args ) {
#        warn "Argument $arg with value $args{$arg} ignored\n";
#    }
    $self->{_stage} = $stage{start};
    $self->{_attachm_printed} = 0;
    # initialize margin sizes
    # TODO: make these into parameters as well
    $self->{_margins} = { %_default_margins };
    $self->{_headfoot_margins} = { %_default_headfoot_margins };
    # initialize fonts
    # TODO: make these into parameters as well
    $self->{_fonts} = { %_default_fonts };

    # try to open the file just to see if we can write it at the end
    # with the 'saveas' method
    if ( not my $fh = IO::File->new($self->{filename}, ">") ) {
        croak "Cannot open file ", $self->{filename}, "\n";
    } else {
        $fh->close();
    }
    
    #$self->{_stage} = $stage{new};
    # initialize the PDF::API2 object
    $self->_initPdf();
    # initialize the fonts
    $self->_initFonts();
    # make first page and determine page layout
    $self->_firstPage();
    $self->_calcLayout();

    $self;
}

#
# ACCESSOR METHODS for Format
#

#
# The page number format methods evaluate to 998 resp. 999 if called before
# the PDF file is generated. This gives an overestimate of their size
# needed in a first calculation of the space needed for the header and
# footer texts.
# The headers and footers are actually written after the full body has been
# generated, and then these methods are called again to give the actual
# values.
#
sub getPageNumber() {
    my $self = shift;
    $self->{_stage} == $stage{start} ? 998 : $self->{_pagenr};
}

sub getPageCount() {
    my $self = shift;
    $self->{_stage} == $stage{start} ? 999 : $self->{_numpages};
}

#
# AUXILIARY METHODS: INITIALIZATION
#

#
# initialize the PDF::API2 object
# makes a first page and sets the mediabox and artbox sizes
# TODO: put all kind of meta info into the PDF object
#
sub _initPdf() {
    my $self = shift;
    my $pdf  = PDF::API2->new();
    # TODO: stuff meta info into PDF object
    $self->{_pdf} = $pdf;
    $self;
}


#
# initialize the PDF fonts
# TODO: this function croaks if it can't find the font
# TODO: the function only can initialize core fonts
#
sub _initFonts() {
    my $self = shift;
    my $enc  = $self->{encoding};
    foreach my $f ( keys %{$self->{_fonts}} ) {
        my $pf = $self->{_pdf}->corefont(
            $self->{_fonts}{$f}{name}
#            , -encode => $enc
        );
        $self->{_fonts}{$f}{obj} = $pf;
    }
}

#
# Method: _calcLayout
# Description:
#   Calculates various layout parameters for use in other methods
#   and checks if the various header/footer fields actually fit within the
#   page width.
# Arguments: none
# Return: none
#
# TODO: consider newlines in header/footer fields
# TODO: refine calculation methods.
#       Currently acts as if the height of a font is its fontsize
#       which is not totally accurate
#
sub _calcLayout() {
    my $self = shift;
    my $font = $self->{_fonts}{headfoot}{obj};
    my $fontsize = $self->{_fonts}{headfoot}{size};
    my @mediabox = @{ $self->{_layout}{mediabox} };
    print STDERR "_calcLayout: mediabox @mediabox\n" if $main::debug & 128;
    my @artbox = @{ $self->{_layout}{artbox} };
    my $page_width  = $artbox[2] - $artbox[0];
    my $page_height = $artbox[3] - $artbox[1];

    my $box_margin_lr = $self->{_headfoot_margins}{box_margin_left} +
                        $self->{_headfoot_margins}{box_margin_right};
    my $box_margin_tb = $self->{_headfoot_margins}{box_margin_top} +
                        $self->{_headfoot_margins}{box_margin_bottom};
    my $box_height = $box_margin_tb + $fontsize;

    my %has    = ( head => 0, foot => 0 );
    my %skip   = ( head => 0, foot => 0 );
    my %height = ( head => 0, foot => 0 );

    my %strs;
    my %twids;
    my %bwids;
    # determine the widths of the various headers/footers
    # these are only upper estimates and won't be used when actually
    # printing them
    foreach my $hf ( qw/head foot/ ) {
        foreach my $lcr ( qw/left center right/ ) {
            my $field = $hf . "_" . $lcr;
            if ( defined $self->{$field} ) {
                my $str = $self->format($self->{$field});
                $strs{$field} = $str;
                $twids{$field} = $font->width($str) * $fontsize;
                $bwids{$field} = $twids{$field} + $box_margin_lr;
                $has{$hf}  = 1;
                $skip{$hf} = $self->{_headfoot_margins}{"${hf}_skip"};
                $height{$hf} = $box_height;
            } else {
                $strs{$field} = '';
                $twids{$field} = 0;
                $bwids{$field} = 0;
            }
        }
    }
    # check if they don't collide
    # actually, we check they should be 10pts apart
    # left/right headers may not cross the half of the page
    # and the center headers are centered on the page
    foreach my $hf ( qw/head foot/ ) {
        foreach my $lr ( qw/left right/ ) {
            my $lr_field = $hf . "_" . $lr;
            my $ct_field = $hf . "_center";
            if ( 2 * $bwids{$lr_field} + $bwids{$ct_field} + 20
                > $page_width ) {
                croak "_calcLayout: \l${hf}er fields $lr and center collide:",
                    "#$strs{$lr_field}# and #$strs{$ct_field}#\n";
            }
        }
    }
    # calculate the various Y coordinates
    my $bodyfont = $self->{_fonts}{body}{obj};
    my $bodyfontsize = $self->{_fonts}{body}{size};
    my $body_top_y = $artbox[3] - $height{head} - $skip{head}
        - $bodyfontsize;
    my $body_bottom_y = $artbox[1] + $height{foot} + $skip{foot};
    if ( $body_bottom_y > $body_top_y ) {
        croak "_calcLayout: no room for body text\n";
    }
    # finally, fill the _layout hash
    $self->{_layout} = {
        mediabox        => \@mediabox
      , artbox          => \@artbox
      , page_height     => $page_height
      , page_width      => $page_width
      , body_top_y      => $body_top_y
      , body_bottom_y   => $body_bottom_y
      , box_margin_lr   => $box_margin_lr
      , box_height      => $box_height
      , hf_left_text_x  => $artbox[0]
            + $self->{_headfoot_margins}{box_margin_left}
      , hf_center_text_x  =>  ($artbox[0] + $artbox[2]) / 2
            + ( $self->{_headfoot_margins}{box_margin_left}
                - $self->{_headfoot_margins}{box_margin_right} ) / 2
      , hf_right_text_x => $artbox[2]
            - $self->{_headfoot_margins}{box_margin_right}
      , head_text_y     => $artbox[3]
            - $self->{_headfoot_margins}{box_margin_top} - $fontsize
      , foot_text_y     => $artbox[1]
            + $self->{_headfoot_margins}{box_margin_bottom}
      , hf_left_box_x   => $artbox[0]
      , hf_right_box_x  => $artbox[2]
      , head_box_y      => $artbox[3] - $box_height
      , foot_box_y      => $artbox[1]
      , has_head        => $has{head}
      , has_foot        => $has{foot}
    };
    # set initial current_y, as in _firstPage this happens too early
    $self->{_current_y} = $self->{_layout}{body_top_y};
    #print STDERR "_calcLayout: top_y: $body_top_y, bot_y: $body_bottom_y\n";
}

#
# USER METHODS
#

#
# Method: printHeader
# Description:
#   print a mail header
# Arguments:
# - header name
# - list of header contents (list for list of addresses with To, Cc etc.)
# Returns: $self
#
sub printHeader($@) {
    my $self = shift;
    if ( $self->{_stage} > $stage{headers} ) {
        croak "printHeader: called in wrong sequence\n";
    }
    $self->{_stage} = $stage{headers};
    if ( @_ < 1 ) {
        croak "printHeader: too few arguments\n";
    } elsif ( @_ == 1 ) {
        # in case of no texts, print nothing
        return;
    }
    $self->_printHeaderOrAttachments(@_);
    $self;
}

#
# Method: printAttachments
# Description:
#   print a line listing the attachments to the mail
# Arguments:
# - list of names of attachments
# Returns: $self
#
sub printAttachments(@) {
    my $self  = shift;
    # check if we're called at the right stage
    if ( $self->{_stage} == $stage{headers} ) {
        $self->{_stage} = $stage{attachm1};
    } elsif ( $self->{_stage} == $stage{body} ) {
        $self->{_stage} = $stage{attachm2};
    } elsif ( $self->{_attachm_printed} ) {
        warn "printAttachments: can only print them once, ignored\n";
        return;
    } else {
        croak "printAttachments: called in wrong sequence\n";
    }
    # just do nothing if there are no arguments
    return if ! @_;
    $self->_printBlankLine();
    $self->_printHeaderOrAttachments('Attachments', @_);
    $self->{_attachm_printed} = 1;
    $self;
}

#
# Method: printLine
# Description:
#   print one line of the mail body
# Arguments:
#   - one line
# Returns: $self
#
sub printLine($) {
    my $self = shift;
    my $line = shift;
    $self->_checkBodyStatus();
    my $text = $self->_newBodyText();
    $self->_printBodyLine($text, $line);
    $self;
}

#
# Method: printLines
# Description:
#   print a list of lines of the mail body
# Arguments:
#   - list of lines
# Returns: $self
#
# TODO: implement optional intelligent wrapping of lines
#
sub printLines(@) {
    my $self  = shift;
    my @lines = @_;
    $self->_checkBodyStatus();
    my $text = $self->_newBodyText();
    foreach my $line ( @lines ) {
        $text = $self->_printBodyLine($text, $line);
    }
    $self;
}

#
# Method: close
# Description:
#   Write the various headers and footers, and save the PDF file
# Arguments: none
#
sub close() {
    my $self = shift;
    my $pdf  = $self->{_pdf};
    $self->{_numpages} = $self->{_pagenr};
    print STDERR "close called ,number pages $self->{_numpages}\n"
        if $main::debug & 64;
    warn "File ", $self->{filename}, " closed before writing body\n"
        if $self->{_stage} < $stage{body};
    foreach my $pagenr ( 1 .. $self->{_numpages} ) {
        print STDERR "close: writing header/footer on page $pagenr\n"
            if $main::debug & 64;
        $self->{_pagenr} = $pagenr;
        my $page = $pdf->openpage($pagenr);
        $self->_printPageHeaderFooter($page, $pagenr);
    }
    $pdf->saveas( $self->{filename} );
    $self->{_stage} = $stage{end};
}

#
# AUXILIARY METHODS: PDF PAGES and LINES
#

#
# Method: _firstPage
# Description:
#   make the first page of the PDF document
#   and store the mediabox and artbox for the rest of the pages
#
sub _firstPage() {
    my $self = shift;
    my $page = $self->{_pdf}->page();
    my $ps = $self->{papersize};
    #$page->mediabox(ref $ps ? @$ps : $ps);
    if ( ref $ps ) {
        print STDERR "_firstPage: mediabox @$ps\n" if $main::debug & 128;
        $page->mediabox(@$ps);
    } else {
        $page->mediabox($ps);
    }
    my @mediabox = $page->get_mediabox();
    $page->artbox(
        $mediabox[0] + $self->{_margins}{margin_left},
        $mediabox[1] + $self->{_margins}{margin_bottom},
        $mediabox[2] - $self->{_margins}{margin_right},
        $mediabox[3] - $self->{_margins}{margin_top} );
    my @artbox = $page->get_artbox();
    # and stuff it all into $self
    $self->{_page} = $page;
    $self->{_pagenr} = 1;
    $self->{_numpages} = 1;
    $self->{_layout}{mediabox} = \@mediabox;
    $self->{_layout}{artbox}   = \@artbox;
    $self->{_current_y} = $self->{_layout}{body_top_y};
    $self;
}

#
# Method: _newPage
# Description:
#   make a new PDF page and initialize it with the right size
#
sub _newPage() {
    my $self = shift;
    my $page = $self->{_pdf}->page();
    $page->mediabox( @{$self->{_layout}{mediabox}} );
    $page->artbox( @{$self->{_layout}{artbox}} );
    $self->{_page} = $page;
    $self->{_pagenr}++;
    $self->{_numpages}++;
    $self->{_current_y} = $self->{_layout}{body_top_y};
    $self;
}

#
# Method: _newLine
# Description:
#   Go to a new line. Make a new page and a new text object if needed
# Arguments:
#   - text object in "old" page
# Return: new current text object
#
sub _newLine($) {
    my $self = shift;
    my $text = shift;
    # waarom de lead meegeven?
    my %state = $text->textstate();
    my $lead = $state{lead};
    my $current_y = $self->{_current_y};
    $current_y -= $lead;
    if ( $current_y < $self->{_layout}{body_bottom_y} ) {
        $self->_newPage();
        # make a new text object
        # in rare cases, this may turn out not to be needed
        my $newt = $self->{_page}->text();
        $newt->font($state{font}, $state{fontsize});
        $newt->lead($state{lead});
        $current_y = $self->{_layout}{body_top_y};
        $newt->translate( $state{translate}[0], $current_y );
        $text = $newt;
    } else {
        $text->nl();
        $self->{_current_y} = $current_y;
    }
    $text;
}

#
# Method: _newBodyText
# Description:
#   make a new text object and give it the font attributes for the body text
# Arguments: none
# Returns: a new text object
#
sub _newBodyText() {
    my $self = shift;
    my $text = $self->{_page}->text();
    $text->font( $self->{_fonts}{body}{obj}, $self->{_fonts}{body}{size} );
    $text->lead( $self->{_fonts}{body}{lead} );
    $text->translate( $self->{_margins}{margin_left}, $self->{_current_y} );
    $text;
}

#
# Method: _printBlankLine
# Description:
#   print a blank line with the height of the mail header font
#   is used to separate headers, attachments line and body from each other
#
sub _printBlankLine() {
    my $self = shift;
    my $dummytext = $self->{_page}->text();
    $dummytext->lead( $self->{_fonts}{header}{lead} );
    $self->_newLine( $dummytext );
}

#
# AUXILIARY METHODS: MAIL HEADER PRINTING
#

#
# Method: _printHeaderOrAttachments
# Description:
#   print a mail header or an "Attachments" line
#   this function does the heavy lifting for printHeader and printAttachments
# Arguments:
# - header name (or the word "Attachments"
# - list of header contents
# Returns: $self
#
sub _printHeaderOrAttachments($@) {
    my $self = shift;
    my ($header, @elts) = @_;
    return if ! @elts;
    my $last = pop @elts;
    foreach ( @elts ) {
        $_ = "$_,";
    }
    push @elts, $last;

    my $page = $self->{_page};
    
    # print header name
    my $hnt = $page->text();
    $hnt->font( $self->{_fonts}{headername}{obj},
        $self->{_fonts}{headername}{size} );
    $hnt->lead( $self->{_fonts}{headername}{lead} );
    $hnt->translate( $self->{_margins}{margin_left},
        $self->{_current_y} );
    $hnt->text( $header . ": " );
    my ($tx, $ty) = $hnt->textpos();

    # calculate the width that remains after the header name
    my $eltwidth = $self->{_layout}{page_width}
        + $self->{_margins}{margin_left} - $tx;

    # print header contents
    my $hct = $page->text();
    $hct->font( $self->{_fonts}{header}{obj},
        $self->{_fonts}{header}{size} );
    my $lead = $self->{_fonts}{header}{lead};
    $hct->lead( $lead );
    $hct->translate( $tx, $ty );

    while ( @elts ) {
        my $elt = shift @elts;
        $self->_wrapLine($hct, $eltwidth, '', 0, $elt);
    }
    $self;
}

#
# Auxiliary line printing functions
#

#
# AUXILIARY METHODS: BODY TEXT PRINTING AND LINE WRAPPING
#

#
# Method: _checkBodyStatus
# Description:
#   check if we're in the right stage to call printLine(s)
#
sub _checkBodyStatus() {
    my $self = shift;
    if ( $self->{_stage} > $stage{body} ) {
        croak "printLine: called in wrong sequence\n";
    } elsif ( $self->{_stage} < $stage{body} ) {
        $self->_printBlankLine();
        $self->{_stage} = $stage{body};
    }
}

#
# Method: _breakWord
# Description:
#   Break up a word that is too long for a line
#   Prints as much of the word as fits on the line
#   NOTE: to be used for both header and for body text
# Arguments:
# - text object
# - linewidth (the part available to the word)
# - word to break
# Returns: pair of the fitting part of the word and the rest of the word
#
sub _breakWord($$$) {
    my $self = shift;
    my ($text, $linewidth, $word) = @_;
    print STDERR "_breakWord: called with linewidth=$linewidth, ",
        "word=|$word|\n" if $main::debug & 8;

    # retrieve the various needed values from the text object
    my %textstate = $text->textstate();
    my ($font, $fontsize, $lead) = @textstate{qw/font fontsize lead/};
    print STDERR "_breakWord: fontsize=$fontsize, lead=$lead\n"
        if $main::debug & 8;

    # first estimate based on the number of characters
    # this does work exactly when using a fixed width font
    # variables with 'len' are actual lengths of printed strings,
    # divided by the fontsize so we don't have to multiply each time
    # variables with 'cnt' count characters
    my $wordcnt = length $word;
    my $wordlen = $font->width($word);
    my $linelen = $linewidth / $fontsize;
    # just to be robust, check if the word fits after all
    if ( $wordlen <= $linelen ) {
        $text->text($word);
        return '';
    }
    my $thiscnt = int $wordcnt * $linelen / $wordlen;
    my ($thispart, $nextpart) = $word =~ /(.{$thiscnt})(.*)/;
    my $thislen = $font->width($thispart);
    print STDERR "_breakWord: first guess thispart=|$thispart|\n"
        if $main::debug & 8;
    # now check if this first estimate is too long or not
    if ( $thislen > $linelen ) {
        # peel off one letter at a time until it fits
        print STDERR "_breakWord: first guess is too long\n"
            if $main::debug & 8;
        while ( $thislen > $linelen ) {
            my ($t, $n) = $thispart =~ /(.*)(.)/;
            ($thispart, $nextpart) = ($t, $n . $nextpart);
            $thislen = $font->width($thispart);
        }
    } else {
        # add one letter at a time until it doesn't fit anymore
        # the 'new' variables are the new try
        # as soon as it doesn't fit, $thispart contains the last known fit
        print STDERR "_breakWord: first guess is too short\n"
            if $main::debug & 8;
        my ($newthis, $newnext) = ($thispart, $nextpart);
        my $newlen = $thislen;
        while ( $newlen <= $linelen ) {
            ($thispart, $nextpart) = ($newthis, $newnext);
            my ($t, $n) = $nextpart =~ /(.)(.*)/;
            ($newthis, $newnext) = ($thispart . $t, $n);
            $newlen = $font->width($newthis);
        }
    }
    print STDERR "_breakWord: found a fit: |$thispart|\n" if $main::debug & 8;
    # $text->text($thispart);
    return ($thispart, $nextpart);
}

#
# Method: _wrapLine
# Description:
#   print a line of text and wrap it if needed
#   repeat quotes if a non-empty "indent text" is provided
#   NOTE: to be used for both header and for body text
# Arguments:
# - text object
# - line width (in points): includes the room for the quote
# - quote (for at least initial line)
# - repeat_quote: do the quotes have to be repeated for the next lines
# - line
# Returns: the last PDF::API2::Content text object written to
#
sub _wrapLine($$$$$) {
    my $self = shift;
    my ($text, $linewidth, $quote, $repeat_quote, $line) = @_;
    print STDERR "_wrapLine: called with line width=$linewidth,",
        "quote=$quote, repeat quote=$repeat_quote\n",
        "\tline=|$line|\n" if $main::debug & 8;

    # retrieve the various needed values from the text object
    my %textstate = $text->textstate();
    my ($font, $fontsize, $lead) = @textstate{qw/font fontsize lead/};
    print STDERR "_wrapLine: fontsize=$fontsize, lead=$lead\n"
        if $main::debug & 8;

    my $quotewidth = $font->width($quote) * $fontsize;
    # calculate the text width excluding the width for quoting,
    # based on fontsize 1 (so we don't have to multiply each time)
    my $txtwidth = ($linewidth - $quotewidth) / $fontsize;
    my $firstline = 1;

    if ( $line eq '' ) {
        print STDERR "_wrapLine: empty line\n" if $main::debug & 8;
        if ( $quote ne '' ) {
            $text->text($quote);
        }
        return $text = $self->_newLine($text);
    }

    while ( $line =~ /\S/ ) {
        # first, print the quote or the indent
        # TODO: we assume the quoting at least will fit on the line
        print STDERR "_wrapLine: entering loop with line |$line|\n"
            if $main::debug & 8;
        if ( $quotewidth ) {
            if ( $firstline || $repeat_quote ) {
                print STDERR "_wrapLine: print quote |$quote|\n"
                    if $main::debug & 8;
                $text->text($quote);
                $firstline = 0;
            } else {
                print STDERR "_wrapLine: indent $quotewidth\n"
                    if $main::debug & 8;
                $text->text('', '-indent', $quotewidth);
            }
        }
        # second, treat the first word of the line separately
        # because it might not fit on the line
        # for the first word, we throw away leading whitespace
        my ($word, $rest) = $line =~ /^\s*(\S+)(.*?)$/;
        print STDERR "_wrapLine: first word is |$word|\n",
            "\trest is |$rest|\n" if $main::debug & 8;
        my $remwidth = $txtwidth;
        my $wordwidth;
        if ( ($wordwidth = $font->width($word)) > $remwidth ) {
            # the first word does not fit
            # break it up in a part that fits and the rest
            # and print the part that fits
            my ($firstpart, $nextpart) =
                $self->_breakWord($text, $remwidth, $word);
            $text->text($firstpart);
            $line = $nextpart . $rest;
        } else {
            # the first word fits
            # now print out words as long as it fits
            print STDERR "_wrapLine: first word fits\n" if $main::debug & 8;
            $text->text($word);
            $remwidth -= $wordwidth;
            $line = $rest;
            while ( ($word, $rest) = ($line =~ /^(\s*\S+)(.*)$/)
                and ($wordwidth = $font->width($word)) <= $remwidth ) {
                #
                print STDERR "_wrapLine: writing next word |$word|\n",
                    "\trest: |$rest|\n" if $main::debug & 8;
                $text->text($word);
                $remwidth -= $wordwidth;
                $line = $rest;
            }
        }
        # lastly, print a newline
        $text = $self->_newLine($text);
    }
    $text;
}

#
# Method: _printBodyLine
# Description:
#   print a line of body text and wrap if it needed
#   repeat the quotes if $repeat_quotes is true
# Arguments:
#   - PDF::API2::Content text object
#   - line of text
# Returns:
#   the last PDF::API2::Content text object that has been written to 
#
# TODO: check if all characters are contained within the encoding
#
sub _printBodyLine($$) {
    my $self = shift;
    my ($text, $line) = @_;
    print STDERR "_printBodyLine called with |$line|\n" if $main::debug & 8;
    chomp $line;
    
    # Fix line: remove > from From at start of line
    $line =~ s/^\>From /From /;

    # recognize quoting at the start of the line
    # according to the RFC, quoting can only be done with >
    # we recognize the chars > } and | with trailing whitespace
    # and we also recognize leading spaces and tabs
    my $quote = "";
    my $linenr = 0;
    my $repeat = 0;
    if ( $line =~ /^(([>}|]\s*)+)(.*)/ ) {
        $quote = $1;
        $line  = $3;
        $repeat = $self->{repeatquotes};
        print STDERR "_printBodyLine: quote recognized: |$quote|\n",
            "\trest: $line\n" if $main::debug & 8;
    } elsif ( $line =~ /^(\s+)(.*)/ ) {
        $quote = $1;
        $line  = $2;
        print STDERR "_printBodyLine: leading space recognized: |$quote|\n",
            "\trest: $line\n" if $main::debug & 8;
    }
    # TODO: also recognize numbered lists?
    my $linewidth = $self->{_layout}{page_width};
    $self->_wrapLine($text, $linewidth, $quote, $repeat, $line);
}

#
# AUXILIARY METHODS: PRINTING HEADERS and FOOTERS
#

#
# Method: _printBox
# Description:
#   print a box
# Arguments:
# - page object
# - bottom left x coordinate
# - bottom left y coordinate
# - x length (the height)
# - y length (the width)
#
sub _printBox($$$$$) {
    my $self = shift;
    my ($page, $bx, $by, $dx, $dy) = @_;

    my $box = $page->gfx();
    $box->linewidth(2);
    $box->move($bx, $by);
    $box->line($bx+$dx, $by);
    $box->line($bx+$dx, $by+$dy);
    $box->line($bx, $by+$dy);
    $box->close();
    $box->stroke()
}

#
# Method: _printPageHeaderFooter
# Description:
#   print the headers and footers on the given page
#   the actual positions of the headers and footers are now dynamically
#   determined
# Arguments:
#   - PDF::API2::Page object
#   - page number
#
sub _printPageHeaderFooter($$) {
    my $self = shift;
    my ($page, $nr) = @_;
    my $pdf = $self->{_pdf};
    my $font = $self->{_fonts}{headfoot}{obj};
    my $fontsize = $self->{_fonts}{headfoot}{size};
    my $fmt;
    my $str;
    my $txt;
    my $wid;

    # header
    # header left
    $fmt = $self->{head_left};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_left_text_x},
            $self->{_layout}{head_text_y}
        );
        $txt->text( $str );
        $self->_printBox( $page,
            $self->{_layout}{hf_left_box_x},
            $self->{_layout}{head_box_y},
            $wid + $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }
    # header center
    $fmt = $self->{head_center};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_center_text_x},
            $self->{_layout}{head_text_y}
        );
        $txt->text_center( $str );
        my $llx = $self->{_layout}{hf_center_text_x}
            - ($wid + $self->{_layout}{box_margin_lr}) / 2;
        $self->_printBox( $page,
            $llx,
            $self->{_layout}{head_box_y},
            $wid + $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }
    # header right
    $fmt = $self->{head_right};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_right_text_x},
            $self->{_layout}{head_text_y}
        );
        $txt->text_right( $str );
        $self->_printBox( $page,
            $self->{_layout}{hf_right_box_x},
            $self->{_layout}{head_box_y},
            - $wid - $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }

    # footer
    # footer left
    $fmt = $self->{foot_left};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_left_text_x},
            $self->{_layout}{foot_text_y}
        );
        $txt->text( $str );
        $self->_printBox( $page,
            $self->{_layout}{hf_left_box_x},
            $self->{_layout}{foot_box_y},
            $wid + $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }
    # footer center
    $fmt = $self->{foot_center};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_center_text_x},
            $self->{_layout}{foot_text_y}
        );
        $txt->text_center( $str );
        my $llx = $self->{_layout}{hf_center_text_x}
            - ($wid + $self->{_layout}{box_margin_lr}) / 2;
        $self->_printBox( $page,
            $llx,
            $self->{_layout}{foot_box_y},
            $wid + $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }
    # footer right
    $fmt = $self->{foot_right};
    if ( defined $fmt ) {
        $str = $self->format($fmt);
        $wid = $font->width( $str ) * $fontsize;
        $txt = $page->text();
        $txt->font( $font, $fontsize );
        $txt->translate(
            $self->{_layout}{hf_right_text_x},
            $self->{_layout}{foot_text_y}
        );
        $txt->text_right( $str );
        $self->_printBox( $page,
            $self->{_layout}{hf_right_box_x},
            $self->{_layout}{foot_box_y},
            - $wid - $self->{_layout}{box_margin_lr},
            $self->{_layout}{box_height}
        );
    }
}

#
# PAPERSIZE
#
# papersize names recognized by PDF::API2
my %api2_papersizes;
# my own papersize names
my %my_papersizes;
BEGIN {
    %api2_papersizes = PDF::API2::Resource::PaperSizes::get_paper_sizes();
    my @a4l = reverse @{$api2_papersizes{a4}};
    $my_papersizes{a4l} = \@a4l;
}

# convert a number in another unit to points
sub _convertUnit($$) {
    my ($len, $unit) = @_;
    $unit eq '' || $unit eq 'pt' ? $len
    : $unit eq 'in' ? $len * 72
    : $unit eq 'mm' ? $len * 72 / 25.4
    : $unit eq 'cm' ? $len * 72 / 2.54
    : undef;
}

#
# Method: checkPapersize
# Argument: papersize
# Returns: a normalized papersize or 'undef'
# Description:
#   Check if the argument is a valid papersize
#   Valid papersizes come in four flavors:
#   1)  A symbolic name recognized by PDF::API2, such as "A4" or "Letter"
#       these names are case insensitive.
#   2)  A reference to an array containing width and height in points
#   3)  A symbolic name defined in this module
#   4)  A string containing the width and height, separated by a comma
#       or by an 'x'. The width and height may be expressed in as a simple
#       number, which is interpreted as points, or suffixed by a unit of
#       length: 'pt' for points, 'in' for inch, 'cm' or 'mm'
#   Cases (3) and (4) are converted to (2)
#
sub checkPapersize($) {
    my $self = shift;
    my $size = shift;
    if ( ref $size eq 'ARRAY' ) {
        my @arr = @$size;
        return $size if @arr == 2 && $arr[0] > 0 && $arr[1] > 0;
    } elsif ( ref $size eq '' ) {
        if ( exists $api2_papersizes{lc $size} ) {
            return $size;
        } elsif ( exists $my_papersizes{lc $size} ) {
            return $my_papersizes{lc $size};
        }
        if ( my ($w, $wu, $h, $hu) =
                ($size =~ /^([0-9]+(?:\.[0-9]*)?) ((?:in|pt|mm|cm)?) (?:[,x])
                        ([0-9]+(?:\.[0-9]*)?) ((?:in|pt|mm|cm)?)$/x) ) {
            print STDERR "checkPapersize width |$w| unit |$wu|\n";
            my @arr = (_convertUnit($w, $wu), _convertUnit($h, $hu));
            return \@arr;
        }
    }
    undef;
}

#
# DEPRECATED METHODS
#

#
# TODO: method _encodeText is not used anymore
# it is a holdover from writing PostScript directly
# kept it here as a reminder how to use it, and that we still have
# an encoding issue
#

#
# Method: _encodeText
# Description:
#   Encode a Perl string into a string for use in PostScript:
#   1)  encodes the Perl string to the right encoding
#   2)  escapes the right characters for use in PostScript
#       (maybe too many, but that doesn't hurt)
# TODO: support other encodings (???)
# TODO: warn about encoding errors;
#
# This method is not used because PDF::API2 apparently doesn't need it, 
# but we've kept it in here just in case.
#
sub _encodeText($) {
    my $self = shift;
    my $text = shift;
    my $octets = encode("iso-8859-15", $text);
    # TODO: warn about encoding errors
    $octets =~ s#[(){}\[\]\\]#\\$&#g;
    $octets;
}


1;

