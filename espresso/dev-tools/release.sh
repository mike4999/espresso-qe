#!/bin/sh -x

# Run this as "./dev-tools/release.sh"

# make sure there is no locale setting creating unneeded differences.
LC_ALL=C
export LC_ALL

#
VERSION=4.2
#
ESPRESSO_DIR=espresso-$VERSION
GUI=PWgui-$VERSION

# BEWARE: 
# in order to build the .html and .txt documentation in Doc, 
# "tcl", "tcllib", "xsltproc" are needed
# in order to build the .pdf files in Doc, "pdflatex" is needed
# in order to build html files for user guide and developer manual,
# "latex2html" and "convert" (from Image-Magick) are needed

if test -d $ESPRESSO_DIR; then /bin/rm -rf $ESPRESSO_DIR; fi
if test -d $ESPRESSO_DIR-Save; then /bin/rm -rf $ESPRESSO_DIR-Save; fi
/bin/rm espresso-$VERSION.tar.gz  espresso-$VERSION.lst
/bin/rm espresso-$VERSION-examples.tar.gz  espresso-$VERSION-examples.lst
/bin/rm $GUI.tar.gz  $GUI.lst

# produce updated ChangeLogs

make log
mv ChangeLog Doc/ChangeLog-$VERSION
mv ChangeLog.html Doc/ChangeLog-$VERSION.html

# produce documentation

make doc
cd doc-def/; make clean ; cd ../

# package using Makefile

make tar
make tar-gui PWGUI_VERSION=$VERSION

# unpackage in directory with version

mkdir $ESPRESSO_DIR $ESPRESSO_DIR-Save
cd $ESPRESSO_DIR 
tar -xzf ../espresso.tar.gz
tar -xzf ../$GUI.tgz
/bin/rm ../$GUI.tgz ../espresso.tar.gz
cd ..

mv  $ESPRESSO_DIR/plugins/archive/*.tar.gz $ESPRESSO_DIR-Save/
/bin/rm -r  $ESPRESSO_DIR/TDDFPT

tar -cvzf $GUI.tar.gz $ESPRESSO_DIR/$GUI >  $GUI.lst
mv  $ESPRESSO_DIR/$GUI $ESPRESSO_DIR-Save/
echo "$GUI.tar.gz saved in directory:" `pwd`
echo "List of files in $GUI.lst"

tar -cvzf espresso-$VERSION-examples.tar.gz  $ESPRESSO_DIR/examples \
    $ESPRESSO_DIR/pseudo $ESPRESSO_DIR/tests $ESPRESSO_DIR/cptests  \
    > espresso-$VERSION-examples.lst
mv $ESPRESSO_DIR/examples $ESPRESSO_DIR/pseudo $ESPRESSO_DIR/tests \
   $ESPRESSO_DIR/cptests $ESPRESSO_DIR-Save/
echo "espresso-$VERSION-examples.tar.gz saved in directory:" `pwd`
echo "List of files in espresso-$VERSION-examples.lst"

tar -cvzf espresso-$VERSION.tar.gz  $ESPRESSO_DIR >  espresso-$VERSION.lst
echo "espresso-$VERSION.tar.gz saved in directory:" `pwd`
echo "List of files in espresso-$VERSION.lst"

