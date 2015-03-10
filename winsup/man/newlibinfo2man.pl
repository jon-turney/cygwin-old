#!/usr/bin/perl

use Time::localtime;
sub print_footer($$$);

my @month = qw'January February March April May June July August September October November December';
my $year = localtime->year + 1900;
my $mon = $month[localtime->mon];

my $date = "$mon $year";

$debug=0;

# We decide whether the content of a page should go in a "summary"
# man page or not with a flag; the first page of the info file should
# We know which nodes are summaries from the list
@summary_nodes = qw( Top Math version Reentrancy Index Ctype
Stdio Strings Signals Timefns Locale Misc Syscalls Stubs
ReentrantSyscalls Arglists Stdarg Varargs Stdlib LibraryIndex DocumentIndex );

foreach (@ARGV)
{
  open INF, '<', $_ or die "Can't open $_!\n";
  $first_time = 1;
  $summary_node = 1;

  # Every info file begins with a START-INFO-DIR-ENTRY of the form:
  #'* libm::                   An ANSI-C conforming mathematical library.'
  # which is where we'll get our TITLE, NAME, and SYNOPSIS sections
  $_ = <INF> until (/START-INFO-DIR-ENTRY/);
  $_ = <INF>;
  s/^\* //;
  s/\s\s//g;
  chomp ();
  my ($title, $synopsis) = split (/::/);
  $TITLE = uc ($title);
  $title = lc ($title); # lowercase for non-case-sensitive filesystem
  $title =~ s/\s+/_/g;
  open OUTSUM, '>', "$title.3";
  print OUTSUM ".TH $TITLE 3 \"$date\" \"NEWLIB\" \"NEWLIB\"\n";
  print OUTSUM ".SH NAME\n $title\n";
  print OUTSUM ".SH SYNOPSIS\n $synopsis\n";
  print OUTSUM ".SH DESCRIPTION\n";
  $_ = <INF> until (/END-INFO-DIR-ENTRY/);

  while (<INF>)
  {
    # octal 037 ("^_") marks node breaks in info files
    # header lines that follow the break look like:
    #'File: libm.info,  Node: atan,  Next: atan2,  Prev: asinh,  Up: Math'
    # We want just the "Node: $node" part to play with
    if (/\037/)
    {
      $_ = <INF>;
      if (/Node:/)
      {
        @header_line = split (/,/);
        foreach (@header_line)
        {
          if (/Node/)
          {
            if ($first_time) { $first_time = 0; }
            else { print_footer (OUTF, $title, $node); }
            ($junk, $node) = split (/:/);
            $node =~ s/\W*//;
            $node =~ s/ //;
            if (grep /\Q$node/, @summary_nodes)
            {
              $summary_node = 1;
            }
            else
            {
              $summary_node = 0;
              $node = lc($node);
              print "working on $node of $title\n" if ($debug);
              $node =~ s/\s+/_/g;
              open OUTF, '>', "$node.3";
              $NODE = uc ($node);
              print OUTF ".TH $NODE 3 \"$date\" ";
              print OUTF "\"NEWLIB\" \"NEWLIB\"\n";
              print OUTF ".SH NAME\n";
            }
          } # End if (/Node/)
        } # End of foreach
      } # End if (/Node:/)

      # We don't need the "Tag Table"
      if ((/Tag Table:/) || (/^Indirect:/))
      {
        $_ = <INF> until (/End Tag Table/);
        s/.*//g;
      }
      else
      {
      # Get rid of the line we already processed
      $_ = <INF>;
      }

    } # End if (/\037/)

    s/\s*\*Synopsis\*/.SH SYNOPSIS/;
    s/\s*\*Description\*/.SH DESCRIPTION/;
    s/\s*\*Returns\*/.SH RETURNS/;
    s/\s*\*Portability\*/.SH PORTABILITY/;
    #s/^[ \t]*//;

    # If a line begins with an "*", we need a line break afterward
    if (/^\*/) { $_ .= ".br\n"; }
    if (/^===/) { $_ = ""; }

    # OUTPUT
    if ($summary_node) {
        print OUTSUM;
    } else {
        print OUTF;
    }

    # Some man pages desribe more than one function like:
    #'* acosf:                                 acos.'
    # The Index tells us which links to make
    if ((grep /$node/, "Index") || (grep /$node/, "LibraryIndex") || (grep /$node/, "DocumentIndex"))
    {
      s/.br\n//;
      s/\(.*//;  # Remove (line 6)
      s/\* //;   # Remove asterisks
      s/\.$//;   # Remove trailing dot
      s/\s*//g;  # Remove whitespace
      s/\.$//;   # Remove more trailing dots
      s/<(.)>/-$1/;
      print "$_\n" if $debug;
      ($from, $to) = split(/:/);
      $from = lc($from);
      $to = lc($to);
      if ((!grep /\Q$to/i, @summary_nodes) && ($from ne $to))
      {
        print "linking ${to}.3 to ${from}.3\n" if ($debug);
        open LOUT, '>', "${from}.3";
        print LOUT ".so ${to}.3";
        close LOUT;
      }
    } # End if (grep /$node/, "Index")
  } # End while(<INF>)

  close OUTF;
  print_footer (OUTSUM, $title, $node);
}
exit;

sub print_footer($$$)
{
  my $out_handle = shift;
  my $title = shift;
  my $node = shift;
  print { $out_handle } ".SH \"SEE ALSO\"\n";
  if (defined($node) && (!grep /\Q$node/, @summary_nodes) && ($node ne "Library Index"))
  {
    print { $out_handle } ".B $node\n";
    print { $out_handle } "is part of the\n";
    print { $out_handle } ".B $title\n";
    print { $out_handle } "library.\n";
  }
  print { $out_handle } "The full documentation for\n";
  print { $out_handle } ".B $title\n";
  print { $out_handle } "is maintained as a Texinfo manual.  If \n";
  print { $out_handle } ".B info\n";
  print { $out_handle } "and\n";
  print { $out_handle } ".B $title\n";
  print { $out_handle } "are properly installed at your site, ";
  print { $out_handle } "the command\n";
  print { $out_handle } ".IP\n";
  print { $out_handle } ".B info $title\n";
  print { $out_handle } ".PP\n";
  print { $out_handle } "will give you access to the complete manual.\n";
  print "finished $node of $title\n" if ($debug);
  close ($out_handle);
}
