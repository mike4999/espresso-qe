#!/bin/sh -x
# ------------------------------------------------------------------------
# Purpose: prepares a directory structure for starkit
#
# Usage:   PWGUI_VERSION=value PWGUI_DIRNAME=value \
#   	        GUIB_VERSION=value GUIB_DIRNAME=value $0
# ------------------------------------------------------------------------

usage() {
    echo "Variable $1 is not defined. Aborting ..."
    exit 1
}

if test "$PWGUI_VERSION" = "" ; then usage PWGUI_VERSION; fi
if test "$PWGUI_DIRNAME" = "" ; then usage PWGUI_DIRNAME; fi
if test "$GUIB_VERSION"  = "" ; then usage GUIB_VERSION;  fi
if test "$GUIB_DIRNAME"  = "" ; then usage GUIB_DIRNAME;  fi
if test "$TOPDIR"        = "" ; then TOPDIR=`cd ..; pwd`; fi
if test "$PWGUI_VFS"     = "" ; then PWGUI_VFS=pwgui_vfs; fi

pwgui_vfs=$PWGUI_VFS
PWGUI_VFS=$TOPDIR/$PWGUI_VFS


# ------------------------------------------------------------------------
# $TOPDIR/pwgui.tar file must exist !!!
# ------------------------------------------------------------------------

if test ! -f $TOPDIR/pwgui.tar ; then
    cd $TOPDIR
    make _create_pwgui-notcl_tar _add_guib
    if test ! -f pwgui.tar ; then
	echo "
*** Something weird happened: 
---------------------------- 
    $TOPDIR/pwgui.tar does not exists !!!"
	exit 1
    fi
fi


# ------------------------------------------------------------------------
# create "main.tcl.sh"
# ------------------------------------------------------------------------

cd $PWGUI_VFS
cat > main.tcl.sh <<END
cat > pwgui.vfs/main.tcl <<EOF

# load a starkit ...

package require starkit 
starkit::startup 

# load a Tk and Itcl ...

package require Tk \$TK_VERSION      
package require \$ITCL_EXACT Itcl \$ITCL_VERSION

# manage the PWgui ...

puts " =================================================="
puts "  This is PWgui version: $PWGUI_VERSION"
puts " --------------------------------------------------"
puts " "


set pwgui app-pwgui
set guib  Guib-$GUIB_VERSION
set env(PWGUI) [file join \\\$starkit::topdir lib \\\$pwgui]
set env(GUIB)  [file join \\\$starkit::topdir lib \\\$guib]
source [file join \\\$starkit::topdir lib \\\$pwgui pwgui.tcl]

# not used ...
#set pwgui PWgui-$PWGUI_VERSION
#set guib  Guib-$GUIB_VERSION
#starkit::autoextend [file join \\\$starkit::topdir \\\$pwgui]
EOF
END



# ------------------------------------------------------------------------
# build a VFS directory strutcure and copy PWgui archive accordingly
# ------------------------------------------------------------------------

cd $PWGUI_VFS
if test -d pwgui.vfs ; then rm -rf pwgui.vfs ; fi
mkdir pwgui.vfs
mkdir pwgui.vfs/lib
mkdir pwgui.vfs/lib/app-pwgui

cd pwgui.vfs/lib/app-pwgui
tar xvf $TOPDIR/pwgui.tar; rm -f $TOPDIR/pwgui.tar
mv lib/$GUIB_DIRNAME ../ 


# ------------------------------------------------------------------------
# create a VFS's tarball
# ------------------------------------------------------------------------

cd $TOPDIR
tar zcvf pwgui_vfs-$PWGUI_VERSION.tgz $pwgui_vfs/

exit 0