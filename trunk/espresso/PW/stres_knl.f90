!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine stres_knl (sigmanlc, sigmakin)
  !-----------------------------------------------------------------------
  !
#include "machine.h"
  USE kinds,           ONLY: DP
  USE constants,            ONLY: pi, e2
  USE brilz,                ONLY: omega, alat, at, bg, tpiba
  USE gvect,                ONLY: qcutz, ecfixed, q2sigma, g
  USE klist,                ONLY: nks, xk
  USE io_files,             ONLY: iunwfc, nwordwfc, iunigk
  USE symme,                ONLY: s, nsym
  USE wvfct,                ONLY: npw, npwx, nbnd, gamma_only, igk, wg
  USE wavefunctions_module, ONLY: evc
  implicit none
  real(kind=DP) :: sigmanlc (3, 3), sigmakin (3, 3)
  real(kind=DP), allocatable :: gk (:,:), kfac (:)
  real(kind=DP) :: twobysqrtpi, gk2, arg
  integer :: kpoint, l, m, i, ibnd

  allocate (gk(  3, npwx))    
  allocate (kfac(   npwx))    

  sigmanlc(:,:) =0.d0
  sigmakin(:,:) =0.d0
  twobysqrtpi = 2.d0 / sqrt (pi)

  kfac(:) = 1.d0

  if (nks.gt.1) rewind (iunigk)
  do kpoint = 1, nks
     if (nks.gt.1) then
        read (iunigk) npw, igk
        call davcio (evc, nwordwfc, iunwfc, kpoint, - 1)
     endif
     do i = 1, npw
        gk (1, i) = (xk (1, kpoint) + g (1, igk (i) ) ) * tpiba
        gk (2, i) = (xk (2, kpoint) + g (2, igk (i) ) ) * tpiba
        gk (3, i) = (xk (3, kpoint) + g (3, igk (i) ) ) * tpiba
        if (qcutz.gt.0.d0) then
           gk2 = gk (1, i) **2 + gk (2, i) **2 + gk (3, i) **2
           arg = ( (gk2 - ecfixed) / q2sigma) **2
           kfac (i) = 1.d0 + qcutz / q2sigma * twobysqrtpi * exp ( - arg)
        endif
     enddo
     !
     !   kinetic contribution
     !
     do l = 1, 3
        do m = 1, l
           do ibnd = 1, nbnd
              do i = 1, npw
                 sigmakin (l, m) = sigmakin (l, m) + wg (ibnd, kpoint) * &
                      gk (l, i) * gk (m, i) * kfac (i) * &
                      DREAL (conjg (evc (i, ibnd) ) * evc (i, ibnd) )
              enddo
           enddo
        enddo

     enddo
     !
     !  contribution from the  nonlocal part
     !
     call stres_us (kpoint, gk, sigmanlc)

  enddo
  !
  ! add the US term from augmentation charge derivatves
  !

  call addusstres (sigmanlc)
#ifdef __PARA
  call reduce (9, sigmakin)
  call poolreduce (9, sigmakin)
  call reduce (9, sigmanlc)
  call poolreduce (9, sigmanlc)
#endif
  !
  ! symmetrize stress
  !
  do l = 1, 3
     do m = 1, l - 1
        sigmanlc (m, l) = sigmanlc (l, m)
        sigmakin (m, l) = sigmakin (l, m)
     enddo
  enddo
  !
  if (gamma_only) then
     sigmakin(:,:) = 2.d0 * e2 / omega * sigmakin(:,:)
  else
     sigmakin(:,:) = e2 / omega * sigmakin(:,:)
  end if
  call trntns (sigmakin, at, bg, - 1)
  call symtns (sigmakin, nsym, s)
  call trntns (sigmakin, at, bg, 1)
  !
  sigmanlc(:,:) = -1.d0 / omega * sigmanlc(:,:)
  call trntns (sigmanlc, at, bg, - 1)
  call symtns (sigmanlc, nsym, s)
  call trntns (sigmanlc, at, bg, 1)

  deallocate(kfac)
  deallocate(gk)
  return
end subroutine stres_knl

