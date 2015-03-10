#!/usr/bin/perl
use Time::localtime;

my @month = qw'January February March April May June July August September October November December';
my $year = localtime->year + 1900;
my $mon = $month[localtime->mon];

my $date = "$mon $year";

warn "usage: utils2man /path/to/utils.xml\n" unless @ARGV;

foreach (@ARGV)
{
    open INF, '<', $_;
    $sect = 0;
    while (<INF>) {
    s/\\/\\\\/g;
    chomp (); # I hate newlines!!
           if (/<sect1/) {
        $_ = <INF>;
        while (! /sect2/) {
        $_ = <INF>;
        }
    }
    if (/sect2/) {
        @line = split (/</);
        foreach (@line) {
        my ($type) = split (/>/);
        if ($type =~ "^sect2.*") {
            $_ = <INF>;
            ($content) = ($_ =~ /<title>(.*)<\/title>/);
            print "Generating $content.1\n";
            open OUTF, '>', "$content.1";
            $page = $content;
            # upper case for title header
            $CONTENT = uc $content;
            print OUTF ".TH $CONTENT 1 \"$date\" ";
            print OUTF "\"\" \"CYGWIN\"\n";
            # grab the "Usage" output for the help2man function
            $_ = <INF>;
            $_ = <INF>;
            $_ = <INF>;
            $help_text = '';
            while (! /\/screen/) {
            $help_text .= $_;
            $_ = <INF>;
            }
            help2man ();
            print OUTF "\n.SH DESCRIPTION\n";
        } elsif ($type eq "/sect2") {
            print_footer ();
            close OUTF;
        }
        }
    } else {
        # Now look for tags; basically, the translation works
        # by taking a specific action based on the tag found. This
        # would be in a case statement, but this is perl :)
        @line = split (/</);
        foreach (@line) {
        if (/>/) {
            (my $type, $content) = split (/>/);
            $content =~ s/&gt;/>/g;
            if ($type eq "para") {
            print OUTF "$content ";
            } elsif ($type eq "/para") {
            print OUTF "\n.PP\n";
            } elsif ($type eq "command") {
            print OUTF "\\fB$content\\fP";
            } elsif ($type eq "/command") {
            print OUTF "$content ";
            } elsif ($type eq "literal") {
            $content =~ s/&lt;/</g;
            $content =~ s/&gt;/>/g;
            print OUTF "\\fB$content\\fP";
            } elsif ($type eq "/literal") {
            print OUTF "$content ";
            } elsif ($type eq "filename") {
            print OUTF "\\fB$content\\fP";
            } elsif ($type eq "/filename") {
            print OUTF "$content ";
            } elsif ($type eq "emphasis") {
            print OUTF "\\fI$content\\fP";
            } elsif ($type eq "/emphasis") {
            print OUTF "$content ";
            } elsif ($type eq "userinput") {
            print OUTF "$content ";
            } elsif ($type eq "/userinput") {
            print OUTF "$content\n";
            } elsif ($type eq "prompt") {
            print OUTF "$content ";
            } elsif ($type eq "/prompt") {
            print OUTF "$content ";
            } elsif ($type eq "screen") {
            $screen = 1;
            print OUTF "\n.PP\n";
            } elsif ($type eq "/screen") {
            $screen = 0;
            print OUTF "\n.PP\n";
            } elsif ($type eq "example") {
            print OUTF "\n.PP\n";
            } elsif ($type eq "/example") {
            print OUTF "\n.PP\n";
            } elsif ($type eq "sect3") {
            print OUTF "\n.PP\n";
            } elsif ($type eq "/sect3") {
            print OUTF "\n.PP\n";
            } elsif ($type eq "title") {
            } elsif ($type eq "/title") {
            print OUTF "$content";
            } elsif ($type eq "/sect1") {
            0 while <INF>;
            } else {
            if (/xref/) {
                $type =~ s/.*"(.*)"/$1/;
                print OUTF "\\fB$type\\fP";
                print OUTF "$content ";
            } else {
                print "type: $type\n" if $debug;
            }
            }
        } else {
            if ($screen) {
            s/!\[CDATA\[//g;
            s/\]\]>//g;
            s/&amp;/\&/g;
            s/&lt;/</g;
            s/&gt;/>/g;
            print OUTF "\n.br\n";
            }
            if ($_) {
            print OUTF "$_ ";
            }
        }
        }
    }
    }
    close INF;
}


# Here is how the only parts of the man pages that look right are produced
sub print_footer
{
    print OUTF <<'EOF';

.SH COPYRIGHT
.B Cygwin
is Copyright (C) 1995-2015 Red Hat, Inc.
.PP
\fBCygwin\fP is Free software; for complete licensing
information, refer to:

.B http://cygwin.com/licensing.html
.SH SEE ALSO

The full documentation to the Cygwin API is maintained
on the web at:

.B http://cygwin.com/cygwin-api/cygwin-api.html

The website is updated more frequently than the
man pages and should be considered the authoritative
source of information.
EOF
}

sub help2man
{
# The rest of the code is this file was copied from GNU help2man:
# Written by Brendan O'Dea <bod@debian.org>
# Available from ftp://ftp.gnu.org/gnu/help2man/

# Generate a short man page from --help and --version output.
# Copyright © 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# Extract usage clause(s) [if any] for SYNOPSIS.

$help_text =~ s/&lt;/</g;
$help_text =~ s/&gt;/>/g;

if ($help_text =~ s/^Usage:( +(\S+))(.*)((?:\n(?: {6}\1| *or: +\S).*)*)//m)
{
my @syn = $2 . $3;

if ($_ = $4)
{
    s/^\n//;
    for (split /\n/) { s/^ *(or: +)?//; push @syn, $_ }
}

my $synopsis = '';
for (@syn)
{
    $synopsis .= ".br\n" if $synopsis;
    s!^\S*/!!;
    s/^(\S+) *//;
    $synopsis .= ".B $1\n";
    s/\s+$//;
    s/(([][]|\.\.+)+)/\\fR$1\\fI/g;
    s/^/\\fI/ unless s/^\\fR//;
    $_ .= '\fR';
    s/(\\fI)( *)/$2$1/g;
    s/\\fI\\fR//g;
    s/^\\fR//;
    s/\\fI$//;
    s/^\./\\&./;

    $synopsis .= "$_\n";
}

$include{SYNOPSIS} ||= $synopsis;
}
# Copy of this for 'Usage' instead of 'Usage:'
if ($help_text =~ s/^Usage( +(\S+))(.*)((?:\n(?: {6}\1| *or: +\S).*)*)//m)
{
my @syn = $2 . $3;

if ($_ = $4)
{
    s/^\n//;
    for (split /\n/) { s/^ *(or: +)?//; push @syn, $_ }
}

my $synopsis = '';
for (@syn)
{
    $synopsis .= ".br\n" if $synopsis;
    s!^\S*/!!;
    s/^(\S+) *//;
    $synopsis .= ".B $1\n";
    s/\s+$//;
    s/(([][]|\.\.+)+)/\\fR$1\\fI/g;
    s/^/\\fI/ unless s/^\\fR//;
    $_ .= '\fR';
    s/(\\fI)( *)/$2$1/g;
    s/\\fI\\fR//g;
    s/^\\fR//;
    s/\\fI$//;
    s/^\./\\&./;

    $synopsis .= "$_\n";
}

$include{SYNOPSIS} ||= $synopsis;
}

# Get the first non-blank line (one-line description) for .SH NAME
$help_text =~ s/\n(.+)\n//;
$name_text = $content . " \- " . $1 . "\n";
$include{NAME} ||= $name_text;

# Process text, initial section is DESCRIPTION.
my $sect = 'OPTIONS';
$_ = "$help_text\n\n$version_text";

# Normalise paragraph breaks.
s/^\n+//;
s/\n*$/\n/;
s/\n\n+/\n\n/g;

# Temporarily exchange leading dots, apostrophes and backslashes for
# tokens.
s/^\./\x80/mg;
s/^'/\x81/mg;
s/\\/\x82/g;

# Start a new paragraph (if required) for these.
s/([^\n])\n(Report +bugs|Email +bug +reports +to|Written +by)/$1\n\n$2/g;

sub convert_option;

while (length)
{
# Convert some standard paragraph names.
if (s/^(Options|Examples): *\n//)
{
    $sect = uc $1;
    next;
}

# Copyright section
if (/^Copyright +[(\xa9]/)
{
    $sect = 'COPYRIGHT';
    $include{$sect} ||= '';
    $include{$sect} .= ".PP\n" if $include{$sect};

    my $copy;
    ($copy, $_) = split /\n\n/, $_, 2;

    for ($copy)
    {
    # Add back newline
    s/\n*$/\n/;

    # Convert iso9959-1 copyright symbol or (c) to nroff
    # character.
    s/^Copyright +(?:\xa9|\([Cc]\))/Copyright \\(co/mg;

    # Insert line breaks before additional copyright messages
    # and the disclaimer.
    s/(.)\n(Copyright |This +is +free +software)/$1\n.br\n$2/g;

    # Join hyphenated lines.
    s/([A-Za-z])-\n */$1/g;
    }

    $include{$sect} .= $copy;
    $_ ||= '';
    next;
}

# Catch bug report text.
if (/^(Report +bugs|Email +bug +reports +to) /)
{
    $sect = 'REPORTING BUGS';
}

# Author section.
elsif (/^Written +by/)
{
    $sect = 'AUTHOR';
}

# Examples, indicated by an indented leading $, % or > are
# rendered in a constant width font.
if (/^( +)([\$\%>] )\S/)
{
    my $indent = $1;
    my $prefix = $2;
    my $break = '.IP';
    $include{$sect} ||= '';
    while (s/^$indent\Q$prefix\E(\S.*)\n*//)
    {
    $include{$sect} .= "$break\n\\f(CW$prefix$1\\fR\n";
    $break = '.br';
    }

    next;
}

my $matched = '';
$include{$sect} ||= '';

# Sub-sections have a trailing colon and the next non-blank line indented.
if (s/^(\S.*:) *\n+ / /)
{
    $matched .= $& if %append;
    $include{$sect} .= qq(.SS "$1"\n);
}

my $indent = 0;
my $content = '';

# Option with description.
if (s/^( {1,10}([+-]\S.*?))(?:(  +)|\n( {20,}))(\S.*)\n//)
{
    $matched .= $& if %append;
    $indent = length ($4 || "$1$3");
    $content = ".TP\n\x83$2\n\x83$5\n";
    unless ($4)
    {
    # Indent may be different on second line.
    $indent = length $& if /^ {20,}/;
    }
}

# Option without description.
elsif (s/^ {1,10}([+-]\S.*)\n//)
{
    $matched .= $& if %append;
    $content = ".HP\n\x83$1\n";
    $indent = 80; # not continued
}

# Indented paragraph with tag.
elsif (s/^( +(\S.*?)  +)(\S.*)\n//)
{
    $matched .= $& if %append;
    $indent = length $1;
    $content = ".TP\n\x83$2\n\x83$3\n";
}

# Indented paragraph.
elsif (s/^( +)(\S.*)\n//)
{
    $matched .= $& if %append;
    $indent = length $1;
    $content = ".IP\n\x83$2\n";
}

# Left justified paragraph.
else
{
    s/(.*)\n//;
    $matched .= $& if %append;
    $content = ".PP\n" if $include{$sect};
    $content .= "$1\n";
}

# Append continuations.
while (s/^ {$indent}(\S.*)\n//)
{
    $matched .= $& if %append;
    $content .= "\x83$1\n"
}

# Move to next paragraph.
s/^\n+//;

for ($content)
{
    # Leading dot and apostrophe protection.
    s/\x83\./\x80/g;
    s/\x83'/\x81/g;
    s/\x83//g;

    # Convert options.
    s/(^| )(-[][\w=-]+)/$1 . convert_option $2/mge;
}

# Check if matched paragraph contains /pat/.
if (%append)
{
    for my $pat (keys %append)
    {
    if ($matched =~ $pat)
    {
        $content .= ".PP\n" unless $append{$pat} =~ /^\./;
        $content .= $append{$pat};
    }
    }
}

$include{$sect} .= $content;
}

# Section ordering.
my @pre = qw(NAME SYNOPSIS DESCRIPTION OPTIONS EXAMPLES);
my @post = ('AUTHOR', 'REPORTING BUGS', 'COPYRIGHT', 'SEE ALSO');
my $filter = join '|', @pre, @post;

# Output content.
for (@pre, (grep ! /^($filter)$/o, @include), @post)
{
if ($include{$_})
{
    my $quote = /\W/ ? '"' : '';
    print OUTF ".SH $quote$_$quote\n";

    for ($include{$_})
    {
    # Replace leading dot, apostrophe and backslash tokens.
    s/\x80/\\&./g;
    s/\x81/\\&'/g;
    s/\x82/\\e/g;
    # JDF
    # HORRIBLE kludge to get strace presentable...still not good
    if (/0x/)
        {
        ($foo, $bar) = split (/Mnemonic Hex/);
        print OUTF $foo;
        $bar =~ s/Corres/Mnemonic Hex Corres/;
        $bar =~ s/\n/\n.br\n/g;
        $bar =~ s/IP/PP/g;
        print OUTF $bar;
        }
    else
        {
        print OUTF;
        }
    }
}
# JDF
# help2man is designed for one-run-per-file, so I need to reset this
$include{$_} = '';
}
}

# Convert option dashes to \- to stop nroff from hyphenating 'em, and
# embolden.  Option arguments get italicised.
sub convert_option
{
local $_ = '\fB' . shift;

s/-/\\-/g;
unless (s/\[=(.*)\]$/\\fR[=\\fI$1\\fR]/)
{
    s/=(.)/\\fR=\\fI$1/;
    s/ (.)/ \\fI$1/;
    $_ .= '\fR';
}

$_;
}
