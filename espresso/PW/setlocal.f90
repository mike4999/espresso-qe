!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine setlocal
  !----------------------------------------------------------------------
  !
  !    This routine computes the local potential in real space vltot(ir)
  !
#include "machine.h"
  use pwcom

  implicit none
  complex(kind=DP), allocatable :: aux (:)
  ! auxiliary variable
  integer :: nt, ng, ir
  ! counter on atom types
  ! counter on g vectors
  ! counter on r vectors
  !
  
  allocate (aux( nrxx))    
  !
  aux(:)=(0.d0,0.d0)
  do nt = 1, ntyp
     do ng = 1, ngm
        aux (nl(ng))=aux(nl(ng)) + vloc (igtongl (ng), nt) * strf (ng, nt)
     enddo
  enddo
  !
  ! aux = potential in G-space . FFT to real space
  !
  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
  !
  do ir = 1, nrxx
     vltot (ir) = DREAL (aux (ir) )
  enddo
!
!  If required add an electric field to the local potential 
!

  if (tefield.and.(.not.dipfield)) call add_efield(vltot)
  endif

  deallocate(aux)
  return
end subroutine setlocal

