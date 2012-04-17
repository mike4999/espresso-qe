include make.sys

default :
	@echo 'to install, type at the shell prompt:'
	@echo '  ./configure'
	@echo '  make target'
	@echo 'where target is one of the following:'
	@echo '  pw           basic code for scf, structure optimization, MD'
	@echo '  cp           CP code: CP MD with ultrasoft pseudopotentials'
	@echo '  ph           phonon code, Gamma-only version and third-order derivatives'
	@echo '  neb          code for Nudged Elastic Band method'
	@echo '  tddfpt       time dependent dft code'
	@echo '  pp           postprocessing programs'
	@echo '  pwcond       ballistic conductance'
	@echo '  vdw          vdW calculation'
	@echo '  w90          Maximally localised Wannier Functions'
	@echo '  want         Quantum Transport with Wannier functions'
	@echo '  plumed       Patch for calculating free-energy paths with pw or cp'
	@echo '  gww          GW with Wannier Functions'
	@echo '  gipaw        NMR and EPR spectra'
	@echo '  epw          Electron-Phonon Coupling'
	@echo '  yambo        electronic excitations with plane waves'
	@echo '  ld1          utilities for pseudopotential generation'
	@echo '  upf          utilities for pseudopotential conversion'
	@echo '  xspectra     X-ray core-hole spectroscopy calculations '
	@echo '  pwall        same as "make pw ph pp pwcond neb"'
	@echo '  all          same as "make pwall cp ld1 upf gww tddfpt"'
	@echo '  clean        remove executables and objects'
	@echo '  veryclean    revert distribution to the original status'
	@echo '  tar          create a tarball of the source tree'
	@echo '  tar-gui      create a tarball of the GUI sources'
	@echo '  doc          build documentation'
	@echo '  links        create links to all executables in bin/'

###########################################################
# Main targets
###########################################################
pw : bindir mods liblapack libblas libs libiotk libenviron
	if test -d PW ; then \
	( cd PW ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

cp : bindir mods liblapack libblas libs libiotk
	if test -d CPV ; then \
	( cd CPV ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

ph : bindir mods libs pw
	if test -d PHonon ; then \
	( cd PHonon ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

neb : bindir mods libs pw
	if test -d NEB ; then \
	( cd NEB ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

tddfpt : bindir mods libs pw ph
	if test -d TDDFPT ; then \
	( cd TDDFPT ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

pp : bindir mods libs pw
	if test -d PP ; then \
	( cd PP ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

pwcond : bindir mods libs pw pp
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

vdw : bindir mods libs pw ph pp
	if test -d VdW ; then \
	( cd VdW ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

acfdt : bindir mods libs pw ph
	if test -d ACFDT ; then \
	( cd ACFDT ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

gipaw : pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

epw : pw ph
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

gww   : bindir pw ph
	if test -d GWW ; then \
	( cd GWW ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

ld1 : bindir liblapack libblas mods libs
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

upf : mods libs
	if test -d upftools ; then \
	( cd upftools ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi

pw_export : libiotk bindir mods libs pw
	if test -d PP ; then \
	( cd PP ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= pw_export.x ; \
	else $(MAKE) $(MFLAGS) TLDEPS= pw_export.x ; fi ) ; fi

xspectra : bindir mods libs pw
	cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile $@

pwall : pw neb ph pp pwcond vdw acfdt
all   : pwall cp ld1 upf gww tddfpt

###########################################################
# Auxiliary targets used by main targets:
# compile modules, libraries, directory for binaries, etc
###########################################################
mods : libiotk
	( cd Modules ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi )
libs : mods
	( cd clib ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi )
	( cd flib ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= $(FLIB_TARGETS) ; \
	else $(MAKE) $(MFLAGS) TLDEPS= $(FLIB_TARGETS) ; fi )

libenviron :  mods
	( if test -d Environ ; then cd Environ ; if test "$(MAKE)" = "" ;  \
	then make $(MFLAGS) TLDEPS= all; else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ; fi )

bindir :
	test -d bin || mkdir bin

#############################################################
# Targets for external libraries
############################################################
libblas : touch-dummy
	cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile $@

liblapack: touch-dummy
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

touch-dummy :
	$(dummy-variable)

#########################################################
# Links and copies. "make links" is likely obsolete.
# "make inst INSTALLDIR=/some/place" will copy all 
# available executables to /some/place/ (must exist and
# be writable), prepending "qe_" to all executables (e.g.:
# /some/place/qe_pw.x). This allows installation of QE
# into system directories with no danger of name conflicts
#########################################################
inst : 
	( for exe in */*.x ../GWW/*.x ; do \
	   file=`basename $$exe`; if test "$(INSTALLDIR)" != ""; then \
		cp $(PWD)/$$exe $(INSTALLDIR)/qe_$$file ; fi ; \
	done )

links : bindir
	( cd bin/ ; \
	rm -f *.x ; \
	for exe in ../*/*.x ; do \
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
		CPV PHonon/D3 PHonon/Gamma Modules PHonon/PH PP PW PWCOND \
		NEB VdW ACFDT EE \
		clib flib pwtools upftools iotk GIPAW XSpectra \
		dev-tools GWW extlibs TDDFPT Environ EPW \
	; do \
	    if test -d $$dir ; then \
		( cd $$dir ; \
		if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= clean ; \
		else $(MAKE) $(MFLAGS) TLDEPS= clean ; fi ) \
	    fi \
	done
	- @(cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile clean)
	- /bin/rm -rf bin/*.x tmp
	- cd tests; /bin/rm -rf CRASH *.out *.out2 

# remove configuration files too
distclean veryclean : clean
	- @(cd install ; $(MAKE) $(MFLAGS) -f plugins_makefile veryclean)
	- @(cd install ; $(MAKE) $(MFLAGS) -f extlibs_makefile veryclean)
	- rm -rf install/patch-plumed
	- cd install ; rm -f config.log configure.msg config.status autom4te.cache \
	CPV/version.h ChangeLog* intel.pcl */intel.pcl
	- rm -f espresso.tar.gz
	- cd examples ; ./make_clean
	- cd PHonon/examples ; ./make_clean
	- cd atomic_doc ; ./make_clean
	- for dir in Doc; do \
	    test -d $$dir && ( cd $$dir ; $(MAKE) $(MFLAGS) TLDEPS= clean ) \
	done
	- test -d GUI && ( cd GUI ;  $(MAKE) $(MFLAGS) TLDEPS= veryclean )
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
	    if test "$(MAKE)" = "" ; then \
		make $(MFLAGS) TLDEPS= clean svninit pwgui-source; \
	    else $(MAKE) $(MFLAGS) TLDEPS= clean svninit pwgui-source; fi; \
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
doc :
	if test -d Doc ; then \
	( cd Doc ; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi ) ; fi
	for dir in */Doc; do \
	( if test -f $$dir/Makefile ; then cd $$dir; if test "$(MAKE)" = "" ; then make $(MFLAGS) TLDEPS= all ; \
	else $(MAKE) $(MFLAGS) TLDEPS= all ; fi  ; fi ); done

depend:
	@echo 'Checking dependencies...'
	- ( if test -x install/makedeps.sh ; then install/makedeps.sh ; fi)

