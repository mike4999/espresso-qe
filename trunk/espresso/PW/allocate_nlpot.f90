!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
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
  USE parameters, ONLY : nbrx, nchix
  USE pseud,      ONLY : lmax, lloc
  USE ions_base,  ONLY : nat, ntyp => nsp, ityp
  USE cell_base,  ONLY : tpiba2
  USE cellmd,     ONLY : cell_factor
  USE gvect,      ONLY : ngm, gcutm, ecutwfc, g
  USE klist,      ONLY : xk, wk, ngk, nks, nkstot, xqq
  USE lsda_mod,   ONLY : nspin
  USE ldaU,       ONLY : Hubbard_lmax, ns, nsnew
  USE noncollin_module,  ONLY : noncolin
  USE wvfct,      ONLY : npwx, npw, igk, igk_l2g, g2kin
  USE us,         ONLY : qrad, tab, tab_at, dq, nqx, nqxq
  USE uspp,       ONLY : indv, nhtol, nhtolm, qq, dvan, deeq, vkb, nkb, &
                         nkbus, nhtoj, becsum, qq_so, dvan_so, deeq_nc
  USE uspp_param, ONLY : lmaxq, lmaxkb, lll, nbeta, nh, nhm, tvanp
  USE spin_orb,   ONLY : lspinorb, fcoef
  !
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
     nh (nt) = 0
     do nb = 1, nbeta (nt)
        nh (nt) = nh (nt) + 2 * lll (nb, nt) + 1
        lmaxkb = max (lmaxkb, lll (nb, nt) )
     enddo
  enddo
  !
  ! calculate the maximum number of beta functions
  !
  nhm = MAXVAL (nh (1:ntyp))
  !
  ! calculate the number of beta functions of the solid
  !
  nkb = 0
  nkbus = 0
  do na = 1, nat
     nt = ityp(na)
     nkb = nkb + nh (nt)
     if (tvanp(nt)) nkbus = nkbus + nh (nt)
  enddo
  !
  allocate (indv( nhm, ntyp))    
  allocate (nhtol(nhm, ntyp))    
  allocate (nhtolm(nhm, ntyp))    
  allocate (nhtoj(nhm, ntyp))    
  allocate (deeq( nhm, nhm, nat, nspin))    
  if (noncolin) then
     allocate (deeq_nc( nhm, nhm, nat, nspin))    
  endif
  if (lspinorb) then
    allocate (qq_so(nhm, nhm, 4, ntyp))    
    allocate (dvan_so( nhm, nhm, nspin, ntyp))    
    allocate (fcoef(nhm,nhm,2,2,ntyp))
  else
    allocate (qq(   nhm, nhm, ntyp))    
    allocate (dvan( nhm, nhm, nspin, ntyp))    
  endif
  !
  nqxq = ( (sqrt(gcutm) + sqrt(xqq(1)**2 + xqq(2)**2 + xqq(3)**2) ) &
          / dq + 4) * cell_factor
  lmaxq = 2*lmaxkb+1
  !
  if (lmaxq > 0) allocate (qrad( nqxq, nbrx*(nbrx+1)/2, lmaxq, ntyp))    
  if (nkb > 0) allocate (vkb( npwx,  nkb))    
  allocate (becsum( nhm * (nhm + 1)/2, nat, nspin))    
  !
  ! ... Allocate space for Hubbard potential
  ! ... These arrays are allocated ALWAYS even if lda_plus_u = .FALSE.
  ! ... This is needed since they are passed as arguments of mix_rho
  ! ... no matter lda_plus_u is .TRUE. or .FALSE.   ( 23/10/2003 C.S. )
  !
  ! if (lda_plus_u) then  
  !
  ldim = 2 * Hubbard_lmax + 1
  ALLOCATE( ns( ldim, ldim, nspin, nat ) )
  ALLOCATE( nsnew( ldim, ldim, nspin, nat ) ) 
  !
  ! endif
  !
  !     Calculate dimensions for array tab (including a possible factor
  !     coming from cell contraction during variable cell relaxation/MD)
  !
  nqx = (sqrt (ecutwfc) / dq + 4) * cell_factor

  allocate (tab( nqx , nbrx , ntyp))    

  allocate (tab_at( nqx , nchix , ntyp))

  return
end subroutine allocate_nlpot

