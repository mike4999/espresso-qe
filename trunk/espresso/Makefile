include make.sys

default :
	@echo 'to install, type at the shell prompt:'
	@echo '  ./configure'
	@echo '  make target'
	@echo 'where target is one of the following:'
	@echo '  pw           basic code for scf, structure optimization, MD'
	@echo '  ph           phonon code, Gamma-only version and third-order derivatives'
	@echo '  pwcond       ballistic conductance'
	@echo '  neb          code for Nudged Elastic Band method'
	@echo '  pp           postprocessing programs'
	@echo '  cp           CP code: CP MD with ultrasoft pseudopotentials'
	@echo '  ld1          utilities for pseudopotential generation'
	@echo '  upf          utilities for pseudopotential conversion'
	@echo '  tddfpt       time dependent dft code'
	@echo '  gui          Graphical User Interface '
	@echo '  gwl          GW with Lanczos chains '
	@echo '  pwall        same as "make pw ph pp pwcond neb"'
	@echo '  all          same as "make pwall cp ld1 upf tddfpt gwl"'
	@echo '  xspectra     X-ray core-hole spectroscopy calculations '
	@echo '  gipaw        NMR and EPR spectra'
	@echo '  w90          Maximally localised Wannier Functions'
	@echo '  want         Quantum Transport with Wannier functions'
	@echo '  yambo        electronic excitations with plane waves'
	@echo '  plumed       Metadynamics plugin for pw or cp'
	@echo '  epw          Electron-Phonon Coupling with wannier functions, EPW package' 
	@echo '  gpu          Download the latest QE-GPU package'
	@echo '  couple       Library interface for coupling to external codes'
	@echo '  clean        remove executables and objects'
	@echo '  veryclean    revert distribution to the original status'
	@echo '  tar          create a tarball of the source tree'
	@if test -d GUI/; then \
	 echo '  tar-gui      create a standalone PWgui tarball from the GUI sources'; fi
	@echo '  doc          build documentation'
	@echo '  links        create links to all executables in bin/'

###########################################################
# Main targets
###########################################################
pw : bindir mods liblapack libblas libs libiotk libenviron
	if test -d PW ; then \
	( cd PW ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

cp : bindir mods liblapack libblas libs libiotk
	if test -d CPV ; then \
	( cd CPV ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

ph : bindir mods libs pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile phonon

neb : bindir mods libs pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

tddfpt : bindir mods libs pw ph
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

pp : bindir mods libs pw
	if test -d PP ; then \
	( cd PP ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

pwcond : bindir mods libs pw pp
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

acfdt : bindir mods libs pw ph
	if test -d ACFDT ; then \
	( cd ACFDT ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

gwl : ph
	if test -d GWW ; then \
	( cd GWW ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

gipaw : pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

ld1 : bindir liblapack libblas mods libs
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

upf : mods libs
	if test -d upftools ; then \
	( cd upftools ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

pw_export : libiotk bindir mods libs pw
	if test -d PP ; then \
	( cd PP ; $(MAKE) $(MFLAGS) TLDEPS= pw_export.x ) ; fi

xspectra : bindir mods libs pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

couple : pw cp
	if test -d COUPLE ; then \
	( cd COUPLE ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi

gui : touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

pwall : pw neb ph pp pwcond acfdt
all   : pwall cp ld1 upf tddfpt gwl

###########################################################
# Auxiliary targets used by main targets:
# compile modules, libraries, directory for binaries, etc
###########################################################
mods : libiotk 
	( cd Modules ; $(MAKE) $(MFLAGS) TLDEPS= all )
libs : mods
	( cd clib ; $(MAKE) $(MFLAGS) TLDEPS= all )
	( cd flib ; $(MAKE) $(MFLAGS) TLDEPS= $(FLIB_TARGETS) )

libenviron :  mods
	( if test -d Environ ; then \
	( cd Environ ; $(MAKE) $(MFLAGS) TLDEPS= all ) fi )

bindir :
	test -d bin || mkdir bin

#############################################################
# Targets for external libraries
############################################################
libblas : touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile $@

liblapack: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile $@

libelpa: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile $@

libiotk: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile $@

# In case of trouble with iotk and compilers, add
# FFLAGS="$(FFLAGS_NOOPT)" after $(MFLAGS)

#########################################################
# plugins
#########################################################

w90: bindir libblas liblapack
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

want : touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

yambo: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

plumed: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

epw: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

gpu: touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

touch-dummy :
	$(dummy-variable)

#########################################################
# "make links" produces links to all executables in bin/
# while "make inst" INSTALLDIR=/some/place" links all
# available executables to /some/place/ (must exist and
# be writable), prepending "qe_" to all executables (e.g.:
# /some/place/qe_pw.x). This allows installation of QE
# into system directories with no danger of name conflicts
#########################################################
inst : 
	( for exe in */*/*.x */bin/* ; do \
	   file=`basename $$exe`; if test "$(INSTALLDIR)" != ""; then \
		if test ! -L $(PWD)/$$exe; then ln -fs $(PWD)/$$exe $(INSTALLDIR)/qe_$$file ; fi ; \
		fi ; \
	done )

links : bindir
	( cd bin/ ; \
	rm -f *.x ; \
	for exe in ../*/*/*.x ../*/bin/* ; do \
	    if test ! -L $$exe ; then ln -fs $$exe . ; fi \
	done \
	)


#########################################################
# Other targets: clean up
#########################################################

# remove object files and executables
clean :
	touch make.sys 
	for dir in \
		CPV Modules PP PW \
		ACFDT \
		clib flib pwtools upftools \
		dev-tools extlibs Environ \
	; do \
	    if test -d $$dir ; then \
		( cd $$dir ; \
		$(MAKE) $(MFLAGS) TLDEPS= clean ) \
	    fi \
	done
	- @(cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile clean)
	- @(cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile clean)
	- /bin/rm -rf bin/*.x tmp
	- cd PW/tests; /bin/rm -rf CRASH *.out *.out? ; cd -
	- cd CPV/tests; /bin/rm -rf CRASH *.out *.out? 

# remove configuration files too
distclean veryclean : clean
	- @(cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile veryclean)
	- @(cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile veryclean)
	- rm -rf install/patch-plumed
	- cd install ; rm -f config.log configure.msg config.status \
	CPV/version.h ChangeLog* intel.pcl */intel.pcl
	- cd install ; rm -fr autom4te.cache
	- cd pseudo; ./clean_ps ; cd -
	- cd install; ./clean.sh ; cd -
	- cd include; ./clean.sh ; cd -
	- rm -f espresso.tar.gz
	- for dir in Doc; do \
	    test -d $$dir && ( cd $$dir ; $(MAKE) $(MFLAGS) TLDEPS= clean ) \
	done
	- rm -rf make.sys

tar :
	@if test -f espresso.tar.gz ; then /bin/rm espresso.tar.gz ; fi
	# do not include unneeded stuff 
	find ./ -type f | grep -v -e /.svn/ -e'/\.' -e'\.o$$' \
             -e'\.mod$$' -e'\.a$$' -e'\.d$$' -e'\.i$$' -e'\.F90$$' -e'\.x$$' \
	     -e'~$$' -e'\./GUI' | xargs tar rvf espresso.tar
	gzip espresso.tar

#########################################################
# Tools for the developers
#########################################################
tar-gui :
	@if test -d GUI/PWgui ; then \
	    cd GUI/PWgui ; \
	    $(MAKE) $(MFLAGS) TLDEPS= clean svninit pwgui-source; \
	    mv PWgui-*.tgz ../.. ; \
	else \
	    echo ; \
	    echo "  Sorry, tar-gui works only for svn sources !!!" ; \
	    echo ; \
	fi

# NOTICE about "make doc": in order to build the .html and .txt
# documentation in Doc, "tcl", "tcllib", "xsltproc" are needed;
# in order to build the .pdf files in Doc, "pdflatex" is needed;
# in order to build html files for user guide and developer manual,
# "latex2html" and "convert" (from Image-Magick) are needed.
doc : touch-dummy
	if test -d Doc ; then \
	( cd Doc ; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi
	for dir in */Doc; do \
	( if test -f $$dir/Makefile ; then \
	( cd $$dir; $(MAKE) $(MFLAGS) TLDEPS= all ) ; fi ) ;  done

depend:
	@echo 'Checking dependencies...'
	- ( if test -x install/makedeps.sh ; then install/makedeps.sh ; fi)

