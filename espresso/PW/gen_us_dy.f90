!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------
subroutine gen_us_dy (ik, u, dvkb)
  !----------------------------------------------------------------------
  !
  !  Calculates the kleinman-bylander pseudopotentials with the
  !  derivative of the spherical harmonics projected on vector u
  !
#include "machine.h"
  USE kinds, ONLY: DP
  USE parameters, ONLY: ndm, nbrx
  USE io_global,  ONLY :  stdout
  USE constants, ONLY: tpi
  USE basis, ONLY: nat, ntyp, tau, ityp
  USE cell_base, ONLY: tpiba
  USE klist, ONLY: xk
  USE gvect, ONLY: ig1, ig2, ig3, eigts1, eigts2, eigts3, g
  USE wvfct, ONLY: npw, npwx, igk
  USE us, ONLY: nkb,  lmaxkb, dq, nbeta, nh, indv, nhtol, nhtom, tab
  implicit none
  !
  integer :: ik
  real(kind=DP) :: u (3)

  complex(kind=DP) :: dvkb (npwx, nkb)
  integer :: na, nt, nb, ih, l, m, lm, ikb, iig, ipol, i0, i1, i2, &
       i3, ig
  real(kind=DP), allocatable :: gk(:,:), q (:)
  real(kind=DP) :: px, ux, vx, wx, arg

  real(kind=DP), allocatable :: vkb0 (:,:,:), dylm (:,:), dylm_u (:,:)
  ! dylm = d Y_lm/dr_i in cartesian axes
  ! dylm_u as above projected on u

  complex(kind=DP), allocatable :: sk (:)
  complex(kind=DP) :: phase, pref

  dvkb(:,:) = (0.d0, 0.d0)
  if (lmaxkb.le.0) return

  allocate ( vkb0(npw,nbrx,ntyp), dylm_u(npw,(lmaxkb+1)**2), gk(3,npw) )
  allocate ( q(npw) )

  do ig = 1, npw
     gk (1, ig) = xk (1, ik) + g (1, igk (ig) )
     gk (2, ig) = xk (2, ik) + g (2, igk (ig) )
     gk (3, ig) = xk (3, ik) + g (3, igk (ig) )
     q (ig) = gk(1, ig)**2 +  gk(2, ig)**2 + gk(3, ig)**2
  enddo

  allocate ( dylm(npw,(lmaxkb+1)**2) )
  dylm_u(:,:) = 0.d0
  do ipol = 1, 3
     call dylmr2  ((lmaxkb+1)**2, npw, gk, q, dylm, ipol)
     call DAXPY (npw * (lmaxkb + 1) **2, u (ipol), dylm, 1, dylm_u, 1)
  enddo
  deallocate (dylm)

  do ig = 1, npw
     q (ig) = sqrt ( q(ig) ) * tpiba
  end do
  do nt = 1, ntyp
     do nb = 1, nbeta (nt)
        do ig = 1, npw
           px = q (ig) / dq - int (q (ig) / dq)
           ux = 1.d0 - px
           vx = 2.d0 - px
           wx = 3.d0 - px
           i0 = q (ig) / dq + 1
           i1 = i0 + 1
           i2 = i0 + 2
           i3 = i0 + 3
           vkb0 (ig, nb, nt) = tab (i0, nb, nt) * ux * vx * wx / 6.d0 + &
                               tab (i1, nb, nt) * px * vx * wx / 2.d0 - &
                               tab (i2, nb, nt) * px * ux * wx / 2.d0 + &
                               tab (i3, nb, nt) * px * ux * vx / 6.d0
        enddo
     enddo
  enddo

  deallocate (q)
  allocate ( sk(npw) )

  ikb = 0
  do nt = 1, ntyp
     do na = 1, nat
        if (ityp (na) .eq.nt) then
           arg = (xk (1, ik) * tau (1, na) + xk (2, ik) * tau (2, na) &
                + xk (3, ik) * tau (3, na) ) * tpi
           phase = DCMPLX (cos (arg), - sin (arg) )
           do ig = 1, npw
              iig = igk (ig)
              sk (ig) = eigts1 (ig1 (iig), na) * eigts2 (ig2 (iig), na) &
                   * eigts3 (ig3 (iig), na) * phase
           enddo
           do ih = 1, nh (nt)
              nb = indv (ih, nt)
              l = nhtol (ih, nt)
              m = nhtom (ih, nt)
              lm = l * l + m
              ikb = ikb + 1
              pref = (0.d0, - 1.d0) **l
              !
              do ig = 1, npw
                 dvkb (ig, ikb) = vkb0(ig, nb, nt) * sk(ig) * dylm_u(ig, lm) &
                      * pref / tpiba
              enddo
           enddo
        endif
     enddo
  enddo

  if (ikb.ne.nkb) then
     WRITE( stdout, * ) ikb, nkb
     call errore ('gen_us_dy', 'unexpected error', 1)
  endif

  deallocate ( sk )
  deallocate ( vkb0, dylm_u, gk )

  return
end subroutine gen_us_dy

