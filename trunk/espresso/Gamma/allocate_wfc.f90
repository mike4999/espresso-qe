!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine allocate_wfc
  !-----------------------------------------------------------------------
  !
  ! dynamical allocation of arrays: wavefunctions and eigenvectors
  !
#include "machine.h"
  use pwcom
  use rbecmod
  implicit none
  !
  ! Allocate memory
  !
  allocate (et( nbndx, nkstot))    
  allocate (wg( nbnd,  nkstot))    
  allocate (evc(  npwx, nbndx))    
  allocate(becp(nkb, nbndx))
  ! Needed with LDA+U

  if (lda_plus_u) allocate (swfcatom( npwx, natomwfc))    

  call setv (nbndx * nkstot, 0.d0, et, 1)
  write (6, 100) nbndx, nbnd, natomwfc, npwx, nelec, nkb, ngl

100 format (/5x,'nbndx  = ',i5,'  nbnd   = ',i5,'  natomwfc = ',i5, &
       &     '  npwx   = ',i7, &
       &     /5x,'nelec  = ',f7.2,' nkb   = ',i5,'  ngl    = ',i7)
  return
end subroutine allocate_wfc

