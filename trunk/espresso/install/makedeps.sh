#!/bin/sh
# compute dependencies for the PWscf directory tree

# run from directory where this script is
cd `echo $0 | sed 's/\(.*\)\/.*/\1/'` # extract pathname
TOPDIR=`pwd`

for DIR in Modules PW CPV flib pwtools upftools PP PWCOND \
           Gamma PH D3 Raman atomic Nmr
do
    # set inter-directory dependencies
    case $DIR in
	Modules )         DEPENDS="../include"                        ;;
	PW | CPV | flib | pwtools | upftools | atomic )
	                  DEPENDS="../include ../Modules"             ;;
	PP | PWCOND | Gamma | PH )
                          DEPENDS="../include ../Modules ../PW"       ;;
	D3 | Raman | Nmr) DEPENDS="../include ../Modules ../PW ../PH" ;;
    esac

    # generate dependencies file
    if test -d $TOPDIR/$DIR
    then
	cd $TOPDIR/$DIR
	$TOPDIR/moduledep.sh $DEPENDS > make.depend
	$TOPDIR/includedep.sh $DEPENDS >> make.depend
    fi

    # handle special case
    mv make.depend make.depend.tmp
    sed '/@\/cineca\/prod\/hpm\/include\/f_hpm.h@/d' \
        make.depend.tmp > make.depend
    rm -f make.depend.tmp

    # check for missing dependencies
    if grep @ make.depend
    then
	echo WARNING: dependencies not found in directory $DIR
    fi
done
