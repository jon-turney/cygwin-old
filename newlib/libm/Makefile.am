## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

if NEWLIB_HW_FP
MATHDIR = mathfp
else
MATHDIR = math
endif

SUBDIRS = $(MATHDIR) common complex machine 

libm_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
SUBLIBS = $(MATHDIR)/lib$(MATHDIR).$(aext) common/libcommon.$(aext) complex/libcomplex.$(aext)  $(LIBM_MACHINE_LIB)
noinst_LTLIBRARIES = libm.la
libm_la_SOURCES =
libm_la_LIBADD = $(SUBLIBS)
else
SUBLIBS = $(MATHDIR)/lib.$(aext) common/lib.$(aext) complex/lib.$(aext) $(LIBM_MACHINE_LIB)
noinst_LIBRARIES = libm.a
libm.a: $(SUBLIBS)
	rm -f $@
	rm -rf tmp
	mkdir tmp
	cd tmp; \
	  for i in $(SUBLIBS); do \
	    $(AR) x ../$$i; \
	done; \
	$(AR) $(AR_FLAGS) ../$@ *.o
	$(RANLIB) $@
	rm -rf tmp
endif

$(SUBLIBS):

info_TEXINFOS = libm.texinfo

libm_TEXINFOS = targetdep.tex

libm.dvi: targetdep.tex math/stmp-def complex/stmp-def

stmp-targetdep: force
	rm -f tmp.texi
	targetdoc=`pwd`/tmp.texi; \
	for d in $(SUBDIRS); do \
	  if test "$$d" != "."; then \
	    (cd $$d && $(MAKE) doc) || exit 1; \
	  fi; \
	done
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi targetdep.tex
	touch $@

targetdep.tex: stmp-targetdep ; @true

math/stmp-def: stmp-targetdep ; @true

complex/stmp-def: stmp-targetdep ; @true

docbook: math/stmp-def complex/stmp-def libm.in.xml
	xsltproc --xinclude --path ${builddir} --nonet ${srcdir}/../refcontainers.xslt ${srcdir}/libm.in.xml >libm.xml
	-xmllint --xinclude -path ${builddir} --postvalid --noent --nonet --noout libm.xml
	xmlto --skip-validation --searchpath ${builddir} html-nochunks --stringparam funcsynopsis.style=ansi libm.xml
	xmlto --skip-validation --searchpath ${builddir} pdf --with-dblatex --stringparam funcsynopsis.style=ansi libm.xml
	xmlto --skip-validation --searchpath ${builddir} man -m ${srcdir}/../man.xsl libm.xml

doc: docbook

install-data-local:
	mkdir -p $(DESTDIR)$(htmldir)
	$(INSTALL_DATA) libm.html $(DESTDIR)$(htmldir)/
	mkdir -p $(DESTDIR)$(docdir)
	$(INSTALL_DATA) libm.pdf $(DESTDIR)$(docdir)/
	mkdir -p $(DESTDIR)$(mandir)/man3
	$(INSTALL_DATA) *.3 $(DESTDIR)$(mandir)/man3/

.PHONY: force
force:

CLEANFILES = tmp.texi targetdep.tex stmp-targetdep *.xml libm.hml libm.pdf *.3

ACLOCAL_AMFLAGS = -I .. -I ../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host
