#!/bin/sh -x

# BEWARE: 
# in order to build the GUI tarball from CVS sources the following
# software is needed:
#   1. pdflatex
#   2. convert (from Image-Magick)
#   3. latex2html

dir=pw-2-0
cd $HOME
if test -d $dir.save; then /bin/rm -r $dir.save; fi
if test -d $dir; then mv $dir $dir.save; fi
mkdir $dir

if test -d O-sesame ; then
    cd O-sesame
else
    echo "
   Ups. O-sesame/ does not exists. Aborting ...
"
    exit 1
fi

GUI_VERSION=`cat GUI/TkPWscf/VERSION`
GUI=TkPWscf-$GUI_VERSION
make veryclean
find . -type f -name *~ -exec /bin/rm {} \;
find . -type f -name .#* -exec /bin/rm {} \;
if test -f pw.tar.gz ; then /bin/rm pw.tar.gz ; fi
make tar tar-gui
cd  ../$dir

mkdir bin
tar -xzf ../O-sesame/pw.tar.gz
tar -xzf ../O-sesame/$GUI.tgz
find $GUI -name CVS -exec /bin/rm -r {} \;

tar -czf ../cp.tar.gz bin/ config* INSTALL README* Make* make*           \
                      install-sh install/ moduledep.sh License upftools/ \
                      include/ cpdocs/ cp_examples/ Modules/ clib/ flib/ CPV/

tar -czf ../fpmd.tar.gz bin/ config*  INSTALL README* Make* make*        \
                      install-sh install/ moduledep.sh License upftools/ \
                      include/ cpdocs/ cp_examples/ Modules/ clib/ flib/ FPMD/

tar -czf ../$GUI.tar.gz $GUI

tar -czf ../pw.tar.gz bin/ config*  flib/ INSTALL README* Make* make* \
                      install-sh install/ moduledep.sh License upftools/ \
                      include/ pwdocs/ Modules/ clib/ flib/ \
                      PW/ PP/ PH/ Gamma/ PWNC/ PWCOND/ D3/ pwtools/

tar -czf ../pw_examples.tar.gz pw_examples/

tar -czf ../ps_examples.tar.gz pseudo/

tar -czf ../allpw.tar.gz bin/ config* INSTALL README* Make* make* \
                      install-sh install/ moduledep.sh License upftools/ \
                      include/ pwdocs/ Modules/ PW/ PP/     \
                      PH/ Gamma/ PWNC/ PWCOND/ D3/ pwtools/ clib/ flib/  \
		      pw_examples/ pseudo/ $GUI

scp pwdocs/README pwdocs/ChangeLog pwdocs/BUGS pwdocs/manual.tex \
    pwdocs/*.png  pwdocs/manual.pdf ../*.tar.gz cibs:public_html/pw

