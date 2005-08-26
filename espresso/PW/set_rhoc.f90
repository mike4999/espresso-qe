!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!-----------------------------------------------------------------------
subroutine set_rhoc
  !-----------------------------------------------------------------------
  !
  !    This routine computes the core charge on the real space 3D mesh
  !
  !
  USE io_global, ONLY : stdout
  USE kinds,     ONLY : DP
  USE atom,      ONLY : rho_atc, numeric, msh, r, rab, nlcc
  USE ions_base, ONLY : ntyp => nsp
  USE cell_base, ONLY : omega, tpiba2
  USE ener,      ONLY : etxcc
  USE gvect,     ONLY : ngm, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
                        nrxx, nl, nlm, ngl, gl, igtongl
  USE pseud,     ONLY : a_nlcc, b_nlcc, alpha_nlcc
  USE scf,       ONLY : rho_core
  USE vlocal,    ONLY : strf
  USE wvfct,     ONLY : gamma_only
  !
  implicit none
  !
  real(kind=DP), parameter :: eps = 1.d-10

  complex(kind=DP) , allocatable :: aux (:)
  ! used for the fft of the core charge

  real(kind=DP) , allocatable ::  rhocg(:)
  ! the radial fourier trasform
  real(kind=DP) ::  rhoima, rhoneg, rhorea
  ! used to check the core charge
  real(kind=DP) ::  vtxcc
  ! dummy xc energy term
  real(kind=DP) , allocatable ::  dum(:,:)
  ! dummy array containing rho=0

  integer :: ir, nt, ng
  ! counter on mesh points
  ! counter on atomic types
  ! counter on g vectors

  etxcc = 0.d0
  do nt = 1, ntyp
     if (nlcc (nt) ) goto 10
  enddo
  rho_core(:) = 0.d0

  return

10 continue
  allocate (aux( nrxx))    
  allocate (rhocg( ngl))    
  aux (:) = 0.d0
  !
  !    the sum is on atom types
  !
  do nt = 1, ntyp
     if (nlcc (nt) ) then
        !
        !     drhoc compute the radial fourier transform for each shell of g vec
        !
        call drhoc (ngl, gl, omega, tpiba2, numeric (nt), a_nlcc (nt), &
             b_nlcc (nt), alpha_nlcc (nt), msh (nt), r (1, nt), rab (1, nt), &
             rho_atc (1, nt), rhocg)
        !
        !     multiply by the structure factor and sum
        !
        do ng = 1, ngm
           aux(nl(ng)) = aux(nl(ng)) + strf(ng,nt) * rhocg(igtongl(ng))
        enddo
     endif
  enddo
  if (gamma_only) then
     do ng = 1, ngm
        aux(nlm(ng)) = CONJG(aux(nl (ng)))
     end do
  end if
  !
  !   the core charge in real space
  !
  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
  !
  !    test on the charge and computation of the core energy
  !
  rhoneg = 0.d0
  rhoima = 0.d0
  do ir = 1, nrxx
     rhoneg = rhoneg + min (0.d0,  DBLE (aux (ir) ) )
     rhoima = rhoima + abs (AIMAG (aux (ir) ) )
     rho_core(ir) =  DBLE (aux(ir))
     !
     ! NOTE: Core charge is computed in reciprocal space and brought to real
     ! space by FFT. For non smooth core charges (or insufficient cut-off)
     ! this may result in negative values in some grid points.
     ! Up to October 1999 the core charge was forced to be positive definite.
     ! This induces an error in the force, and probably stress, calculation if
     ! the number of grid points where the core charge would be otherwise neg
     ! is large. The error disappears for sufficiently high cut-off, but may be
     ! rather large and it is better to leave the core charge as it is.
     ! If you insist to have it positive definite (with the possible problems
     ! mentioned above) uncomment the following lines.  SdG, Oct 15 1999
     !
     !         rhorea = max ( DBLE (aux (ir) ), eps)
     !         rho_core(ir) = rhorea
     !
  enddo
  rhoneg = rhoneg / (nr1 * nr2 * nr3)
  rhoima = rhoima / (nr1 * nr2 * nr3)
#ifdef __PARA
  call reduce (1, rhoneg)
  call reduce (1, rhoima)
#endif
  IF (rhoneg < -1.0d-6 .OR. rhoima > 1.0d-6) &
       WRITE( stdout, '(/5x,"warning: negative or imaginary core charge ",2f12.6)')&
       rhoneg, rhoima
  !
  ! calculate core_only exch-corr energy etxcc=E_xc[rho_core] if required
  ! The term was present in previous versions of the code but it shouldn't
  !
  !   allocate (dum(nrxx , nspin))    
  !   dum(:,:) = 0.d0
  !   call v_xc (dum, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
  !        nrxx, nl, ngm, g, nspin, alat, omega, etxcc, vtxcc, aux)
  !
  !   deallocate(dum)
  !   WRITE( stdout, 9000) etxcc
  !   WRITE( stdout,  * ) 'BEWARE it will be subtracted from total energy !'
  !
  deallocate (rhocg)
  deallocate (aux)
  !
  return

9000 format (5x,'core-only xc energy         = ',f15.8,' ryd')

end subroutine set_rhoc

