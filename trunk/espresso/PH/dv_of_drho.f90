!
! Copyright (C) 2001-2008 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine dv_of_drho (mode, dvscf, flag)
  !-----------------------------------------------------------------------
  !
  !     This routine computes the change of the self consistent potential
  !     due to the perturbation.
  !
#include "f_defs.h"
  USE kinds,     ONLY : DP
  USE constants, ONLY : e2, fpi
  USE gvect,     ONLY : nrxx, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
                    nl, ngm, g
  USE cell_base, ONLY : alat, tpiba2
  USE lsda_mod,  ONLY : nspin
  USE noncollin_module, ONLY : nspin_gga, nspin_lsda
  USE funct,     ONLY : dft_is_gradient
  USE scf,       ONLY : rho, rho_core

  USE eqv,       ONLY : dmuxc
  USE nlcc_ph,   ONLY : nlcc_any
  USE qpoint,    ONLY : xq
  USE gc_ph,     ONLY : grho, dvxc_rr,  dvxc_sr,  dvxc_ss, dvxc_s
  USE control_ph, ONLY : lrpa

  implicit none

  integer :: mode
  ! input: the mode to do

  complex(DP) :: dvscf (nrxx, nspin)
  ! input: the change of the charge,
  ! output: change of the potential

  logical :: flag
  ! input: if true add core charge

  integer :: ir, is, is1, ig
  ! counter on r vectors
  ! counter on spin polarizations
  ! counter on g vectors

  real(DP) :: qg2, fac
  ! the modulus of (q+G)^2
  ! the structure factor

  complex(DP), allocatable :: dvaux (:,:), drhoc (:)
  ! auxiliary variable for potential
  !  the change of the core charge

  call start_clock ('dv_of_drho')

  allocate (dvaux( nrxx,  nspin))    
  allocate (drhoc( nrxx))    
  !
  ! the exchange-correlation contribution is computed in real space
  !
  dvaux (:,:) = (0.d0, 0.d0)
  if (lrpa) goto 111

  fac = 1.d0 / DBLE (nspin_lsda)
  if (nlcc_any.and.flag) then
     call addcore (mode, drhoc)
     do is = 1, nspin_lsda
        rho%of_r(:, is) = rho%of_r(:, is) + fac * rho_core (:)
        dvscf(:, is) = dvscf(:, is) + fac * drhoc (:)
     enddo
  endif
  do is = 1, nspin
     do is1 = 1, nspin
        do ir = 1, nrxx
           dvaux(ir,is) = dvaux(ir,is) + dmuxc(ir,is,is1) * dvscf(ir,is1)
        enddo
     enddo
  enddo
  !
  ! add gradient correction to xc, NB: if nlcc is true we need to add here
  ! its contribution. grho contains already the core charge
  !
  if ( dft_is_gradient() ) call dgradcorr &
       (rho%of_r, grho, dvxc_rr, dvxc_sr, dvxc_ss, dvxc_s, xq, &
       dvscf, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, nspin, nspin_gga, &
       nl, ngm, g, alat, dvaux)
  if (nlcc_any.and.flag) then
     do is = 1, nspin_lsda
        rho%of_r(:, is) = rho%of_r(:, is) - fac * rho_core (:)
        dvscf(:, is) = dvscf(:, is) - fac * drhoc (:)
     enddo
  endif
111 continue
  !
  ! copy the total (up+down) delta rho in dvscf(*,1) and go to G-space
  !
  if (nspin == 2) then
     dvscf(:,1) = dvscf(:,1) + dvscf(:,2) 
  end if
  !
  call cft3 (dvscf, nr1, nr2, nr3, nrx1, nrx2, nrx3, -1)
  !
  ! hartree contribution is computed in reciprocal space
  !
  do is = 1, nspin_lsda
     call cft3 (dvaux (1, is), nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
     do ig = 1, ngm
        qg2 = (g(1,ig)+xq(1))**2 + (g(2,ig)+xq(2))**2 + (g(3,ig)+xq(3))**2
        if (qg2 > 1.d-8) then
           dvaux(nl(ig),is) = dvaux(nl(ig),is) + &
                              e2 * fpi * dvscf(nl(ig),1) / (tpiba2 * qg2)
        endif
     enddo
     !
     !  and transformed back to real space
     !
     call cft3 (dvaux (1, is), nr1, nr2, nr3, nrx1, nrx2, nrx3, +1)
  enddo
  !
  ! at the end the two contributes are added
  !
  dvscf (:,:) = dvaux (:,:)
  !
  deallocate (drhoc)
  deallocate (dvaux)

  call stop_clock ('dv_of_drho')
  return
end subroutine dv_of_drho
