#!/usr/bin/perl
use Time::localtime;

my @month = qw'January February March April May June July August September October November December';
my $year = localtime->year + 1900;
my $mon = $month[localtime->mon];

my $date = "$mon $year";
warn "usage: api2man api-xml-file [api-xml-file2 ...]\n" unless @ARGV;

foreach (@ARGV) {
    open INF, '<', $_;
    $sect = 0;
    my $comma = 0;
    while (<INF>) {
        s/\\/\\\\/g;
        chomp; # I hate newlines!!
        # Check for beginning or end of section (not really necessary, but good to know)
        if (/sect1/) {
            if ($sect == 1) {
                $sect = 0;
            } else {
                s/<.*id="(.*)">/$1/;
                $sect = 1;
                $_ = '';
            }
        }
        # Now look for tags; basically, the translation works
        # by taking a specific action based on the tag found. This
        # would be in a case statement, but this is perl :)
        @line = split /</o;
        foreach (@line) {
            if (/>/) {
                my ($type, $content) = split />/;
                if ($type eq "/funcsynopsis") {
                    if ($comma) {
                        print OUTF ");\n\n.SH DESCRIPTION\n";
                        $comma = 0;
                    }
                } elsif ($type eq "void") {
                    print OUTF ");\n\n.SH DESCRIPTION\n";
                } elsif ($type eq "title") {
                    if (/cygwin_/) {
                        $comma = 0;
                        # The name of each page is dependent on the title, so first
                        #  we need to print a footer for the last page (if any)
                        print_footer ();
                        close (OUTF);
                        # And now, to start a new output file and header
                        print "Generating $content.3\n";
                        open OUTF, '>', "$content.3";
                        # man uses uppercase for titles
                        print OUTF ".TH $content 3 \"$date\" \"Cygwin\" \"Programmer's Manual\"\n";
                        print OUTF ".SH NAME\n$content\n";
                    }
                } elsif ($type eq "funcsynopsis") {
                    print OUTF ".SH SYNOPSIS\n";
                } elsif ($type eq "funcdef") {
                    print OUTF "\\fB$content\\fP \n.br \n.B ";
                } elsif ($type eq "function") {
                    print OUTF "$content (";
                } elsif ($type eq 'paramdef') {
                    if ($comma) {
                        print OUTF ', ';
                        $comma = 0;
                    }
                    print OUTF "$content ";
                } elsif ($type eq 'parameter') {
                    print OUTF "\\fI$content\\fP";
                    $comma = 1;
                } elsif ($type eq 'para') {
                    print OUTF "$content ";
                } elsif ($type eq '/link') {
                    print OUTF "(3)\\fP ";
                }
                # The <example> tag tells us that we need to
                #  1) ignore the secondary <title> tag (by reading two extra lines)
                #  2) switch to outputting preformatted code (until </example>
                elsif ($type eq "example") {
                    print OUTF "\n\n.SH EXAMPLE\n";
                    $_ = <INF>;
                    $_ = <INF>;
                    while (!/example/) {
                        $_ = <INF>;
                        s/\\/\\\\/g;
                        if (! /</) {
                            print OUTF ".br\n";
                            print OUTF;
                        }
                    }
                } elsif ($type eq "/title" || "/parameter") {
                    if ($content) {
                        print OUTF "$content ";
                    }
                } elsif (length $_) {
                    print OUTF "$_ ";
                }
            } else {
                # This is a horrible kludge but it works
                if ($_ eq "link") {
                    print OUTF "\n.br\n\\fB";
                } elsif (length $_) {
                    print OUTF "$_ ";
                }
            }
        }
    }
    print_footer ();
    close (OUTF);
    close (INF);
}

# Here is how the only parts of the man pages that look right are produced
sub print_footer
{
    print OUTF <<'EOF'

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
