!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine stres_har (sigmahar)
  !----------------------------------------------------------------------
  !
#include "machine.h"
  USE parameters, ONLY : DP
  USE constants, ONLY : e2, fpi
  USE brilz, ONLY: omega, tpiba2
  USE ener, ONLY: ehart
  USE gvect, ONLY: ngm, gstart, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
       nrxx , nl, g, gg
  USE lsda_mod, ONLY: nspin
  USE scf, ONLY: rho
  USE wvfct, ONLY: gamma_only
  USE wavefunctions_module,    ONLY : psic
  implicit none
  !
  real(kind=DP) :: sigmahar (3, 3), shart, g2
  real(kind=DP), parameter :: eps = 1.d-8
  integer :: is, ig, igl0, l, m

  sigmahar(:,:) = 0.d0
  psic (:) = (0.d0, 0.d0)
  do is = 1, nspin
     call DAXPY (nrxx, 1.d0, rho (1, is), 1, psic, 2)
  enddo

  call cft3 (psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
  ! psic contains now the charge density in G space
  ! the  G=0 component is not computed
  do ig = gstart, ngm
     g2 = gg (ig) * tpiba2
     shart = psic (nl (ig) ) * conjg (psic (nl (ig) ) ) / g2
     do l = 1, 3
        do m = 1, l
           sigmahar (l, m) = sigmahar (l, m) + shart * tpiba2 * 2 * &
                g (l, ig) * g (m, ig) / g2
        enddo
     enddo
  enddo
#ifdef __PARA
  call reduce (9, sigmahar)
#endif
  if (gamma_only) then
     sigmahar(:,:) =       fpi * e2 * sigmahar(:,:)
  else
     sigmahar(:,:) = 0.5 * fpi * e2 * sigmahar(:,:)
  end if
  do l = 1, 3
     sigmahar (l, l) = sigmahar (l, l) - ehart / omega
  enddo
  do l = 1, 3
     do m = 1, l - 1
        sigmahar (m, l) = sigmahar (l, m)
     enddo
  enddo

  sigmahar(:,:) = -sigmahar(:,:)

  return
end subroutine stres_har

