! Copyright (C) 2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine plugin_clean(lflag)
!
! This routine is used for cleaning calls
! from plugins
! DO NOT REMOVE THE TAGS ! ***ADDSON_NAME KIND_OF_PATCH***
!
USE plugin_flags
!
! ***Environ MODULES BEGIN***
! ***Environ MODULES END***
!
implicit none
!
LOGICAL, INTENT(IN) :: lflag
!
! ***Environ VARIABLES BEGIN***
! ***Environ VARIABLES END***
!
! ***Environ CALLS BEGIN***
! ***Environ CALLS END***
!
end subroutine plugin_clean

