!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine allocate_nlpot
  !-----------------------------------------------------------------------
  !
  ! This routine computes the dimension of the Hamiltonian matrix and
  ! allocates arrays containing the non-local part of the pseudopotential
  !
  ! It computes the following global quantities:
  !
  !     ngk           !  number of plane waves (for each k point)
  !     npwx          !  maximum number of plane waves
  !     nkb           !  number of beta functions for the solid
  !     nqx           !  number of points of the interpolation table
  !     nh            !  number of beta functions for each atom type
  !     nhm           !  maximum number of beta functions
  !
  !
#include "machine.h"
  use pwcom
  implicit none
  !
  !    a few local variables
  !
  integer :: nt, na, nb, ldim  
  ! counters on atom type, atoms, beta functions
  !
  !   calculate number of PWs for all kpoints
  !
  call n_plane_waves (ecutwfc, tpiba2, nks, nkstot, xk, g, ngm, npwx, ngk)
  !
  !   igk relates the index of PW k+G to index in the list of G vector
  !
  allocate (igk( npwx))    

  allocate (igk_l2g( npwx, nks))    
  igk_l2g = 0

  allocate (g2kin( npwx))    
  !
  !     calculate the number of beta functions for each atomic type
  !
  lmaxkb = - 1
  do nt = 1, ntyp
     if (tvanp (nt).or.newpseudo (nt)) then
        nh (nt) = 0
        do nb = 1, nbeta (nt)
           nh (nt) = nh (nt) + 2 * lll (nb, nt) + 1
           lmaxkb = max (lmaxkb, lll (nb, nt) )
        enddo
     else
        nh (nt) = (lmax(nt) + 1) * (lmax(nt) + 1) - (2 * lloc(nt) + 1)
        if (lloc (nt) .eq.lmax (nt) ) then
           lmaxkb = max (lmaxkb, lmax (nt) - 1)
        else
           lmaxkb = max (lmaxkb, lmax (nt) )
        endif
     endif
  enddo
  lqx = 2*lmaxkb+1
  !
  ! calculate the maximum number of beta functions
  !
  nhm = 0
  do nt = 1, ntyp
     if (nh (nt) .gt.nhm) nhm = nh (nt)
  enddo
  !
  ! calculate the number of beta functions of the solid
  !
  nkb = 0
  do na = 1, nat
     nkb = nkb + nh (ityp(na))
  enddo
  !
  allocate (indv( nhm, ntyp))    
  allocate (nhtol(nhm, ntyp))    
  allocate (nhtom(nhm, ntyp))    
  allocate (qq(   nhm, nhm, ntyp))    
  allocate (dvan( nhm, nhm, ntyp))    
  allocate (deeq( nhm, nhm, nat, nspin))    
  !
  nqxq = ( (sqrt(gcutm) + sqrt(xqq(1)**2 + xqq(2)**2 + xqq(3)**2) ) &
          / dq + 4) * cell_factor
  !
  allocate (qrad( nqxq, nbrx*(nbrx+1)/2, lqx, ntyp))    
  allocate (vkb( npwx,  nkb))    
  allocate (qgm( ngm))    
  allocate (becsum( nhm * (nhm + 1)/2, nat, nspin))    
  !
  !     Allocate space for Hubbard potential
  !
  if (lda_plus_u) then  
     ldim = 2 * Hubbard_lmax + 1
     allocate( ns    (ldim, ldim, nspin, nat) )
     allocate( nsnew (ldim, ldim, nspin, nat) ) 
  endif
  !
  !     Calculate dimensions for array tab (including a possible factor
  !     coming from cell contraction during variable cell relaxation/MD)
  !
  nqx = (sqrt (ecutwfc) / dq + 4) * cell_factor

  allocate (tab( nqx , nbrx , ntyp))    

  return
end subroutine allocate_nlpot

