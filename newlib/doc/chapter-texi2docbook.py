#!/usr/bin/env python
#
# python script to convert the handwritten chapter .texi files which include
# the generated files for each function to equivalent DocBook XML
#
# This has very a simple, fixed idea about how those chapter .texi files will be
# structured
#

from __future__ import print_function
from enum import Enum
import sys
import re

class State(Enum):
    normal = 0
    para = 1
    table = 2
    enumerate = 3
    skip = 4

def main():
    state = State.normal
    first_row = True
    first_node = True

    print ('<?xml version="1.0" encoding="UTF-8"?>')
    print ('<!DOCTYPE chapter PUBLIC "-//OASIS//DTD DocBook V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd">')

    for l in sys.stdin.readlines():
	l = l.rstrip()

	# transform < and >
	l = l.replace("<", "&lt;")
	l = l.replace(">", "&gt;")

	# transform @file{foo} to <filename>foo</filename>
	l = re.sub("@file{(.*?)}", "<filename>\\1</filename>", l)
	# ditto code
	l = re.sub("@code{(.*?)}", "<code>\\1</code>", l)
	# ditto dfn
	l = re.sub("@dfn{(.*?)}", "<firstterm>\\1</firstterm>", l)
	# ditto emph
	l = re.sub("@emph{(.*?)}", "<emphasis>\\1</emphasis>", l)
	# ditto samp
	l = re.sub("@samp{(.*?)}", "<literal>\\1</literal>", l)
	# ditto var
	l = re.sub("@var{(.*?)}", "<varname>\\1</varname>", l)

	# handle @*
	l = l.replace("@*", "</para><para>", 1)

	# remove @exdent
	l = l.replace("@exdent", "", 1)
	# remove @noindent
	l = l.replace("@noindent", "", 1)

	if l.startswith("@node"):
	    l = l.replace("@node", "", 1)
	    l = l.strip()
	    l = l.lower()
	    if first_node:
		print ('<chapter id="%s" xmlns:xi="http://www.w3.org/2001/XInclude">' % l.replace(' ', '_'))
		first_node = False
	    continue
	elif l.startswith("@chapter "):
	    l = l.replace("@chapter ", "", 1)
	    print ('<title>%s</title>' % l)
	    print ('<para>')
	    state = State.para
	    continue
	elif not l:
	    if state == State.para:
		print ('</para>')
		print ('<para>')
	    continue
	elif l.startswith("@table"):
	    # table introduces a 2-column table
	    l = l.replace("@table @code", "<informaltable><tgroup cols='2'><tbody>")
	    state = State.table
	    first_row = True
	elif l.startswith("@item"):
	    if state == State.table:
		if not first_row:
		    l = "</entry></row>" + l
		first_row = False
		l = l.replace("@item", "<row><entry><code>")
		l = l + "</code></entry><entry>"
	    elif state == State.enumerate:
		if not first_row:
		    l = "</para></listitem>" + l
		first_row = False
		l = l.replace("@item", "<listitem><para>")
	elif l.startswith("@end table"):
	    l = l.replace("@end table", "</entry></row></tbody></tgroup></informaltable>")
	    state = State.para
	elif l.startswith("@enumerate"):
	    if state == State.para:
		l = "</para>" + l
	    state = State.enumerate
	    l = l.replace("@enumerate", "<orderedlist>")
	    first_row = True
	elif l.startswith("@end enumerate"):
	    if state == State.enumerate:
		l = l.replace("@end enumerate", "</para></listitem></orderedlist><para>")
		state = State.para
	elif l.startswith("@menu"):
	    if state == State.para:
		print("</para>")
	    state = State.skip
	    continue
	elif l.startswith("@endmenu"):
	    state = State.normal
	    continue
	elif  l.startswith("@cindex") or l.startswith("@findex"):
	    l = l.split(None, 1)[1]
	    l = "<indexterm><primary>" + l + "</primary></indexterm>"
	elif (l.startswith("@page") or l.startswith("@example") or
	      l.startswith("@end example") or l.startswith("@ifset") or
	      l.startswith("@end ifset")):
	    continue
	elif l.startswith("@include "):
	    l = l.replace("@include ", "", 1)
	    l = l.replace(".def", ".xml", 1)
	    print ('<xi:include href="%s"/>' % l.strip())

	# we can skip over everything between @menu and @endmenu
	if state == State.skip:
	    continue

	match = re.match('@[a-z]+', l)
	if match:
	    print ("texinfo command %s ?" % match.group(), file=sys.stderr)

	print (l)

    if state == State.para:
	print ('</para>')
    print ('</chapter>')

if __name__ == "__main__" :
    main()
