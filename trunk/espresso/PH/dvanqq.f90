!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------
subroutine dvanqq
  !----------------------------------------------------------------------
  !
  ! This routine calculates four integrals of the Q functions and
  ! its derivatives with c V_loc and V_eff which are used
  ! to compute term dV_bare/dtau * psi  in addusdvqpsi and in addusdynmat.
  ! The result is stored in int1,int2,int4,int5. The routine is called
  ! only once. int4 and int5 are deallocated after use in
  ! addusdynmat, and int1 and int2 saved on disk by that routine.
  !
#include "machine.h"

  use pwcom
  USE kinds, only : DP
  use phcom
  USE uspp_param, ONLY: lmaxq, nh, tvanp
  implicit none
  !
  !   And the local variables
  !

  integer :: na, nb, ig, nta, ntb, ir, ih, jh, ijh, ipol, jpol, is
  ! counters

  real(kind=DP), allocatable :: qmod (:), qmodg (:), qpg (:,:), &
       ylmkq (:,:), ylmk0 (:,:)
  ! the modulus of q+G
  ! the modulus of G
  ! the  q+G vectors
  ! the spherical harmonics

  complex(kind=DP) :: fact, fact1, ZDOTC
  complex(kind=DP), allocatable :: sk (:), aux1 (:), aux2 (:),&
       aux3 (:), aux5 (:,:,:), veff (:,:)
  ! work space
  complex(kind=DP), allocatable, target :: qgm(:)
  ! the augmentation function at G
  complex(kind=DP), pointer :: qgmq (:)
  ! the augmentation function at q+G

  if (recover) return

  if (.not.okvan) return

  call start_clock ('dvanqq')
  int1(:,:,:,:,:) = (0.d0, 0.d0)
  int2(:,:,:,:,:) = (0.d0, 0.d0)
  int4(:,:,:,:,:) = (0.d0, 0.d0)
  int5(:,:,:,:,:) = (0.d0, 0.d0)
  allocate (sk  (  ngm))    
  allocate (aux1(  ngm))    
  allocate (aux2(  ngm))    
  allocate (aux3(  ngm))    
  allocate (aux5(  ngm ,nat,  3 ))    
  allocate (qmodg( ngm))    
  allocate (veff ( nrxx , nspin))    
  allocate (ylmk0( ngm , lmaxq * lmaxq))    
  allocate (qgm  ( ngm))    
  if (.not.lgamma) then
     allocate (ylmkq(ngm , lmaxq * lmaxq))    
     allocate (qpg (3, ngm))    
     allocate (qmod( ngm))    
     allocate (qgmq( ngm))    
  else
     qgmq =>qgm
  endif
  !
  !     compute spherical harmonics
  !
  call ylmr2 (lmaxq * lmaxq, ngm, g, gg, ylmk0)
  do ig = 1, ngm
     qmodg (ig) = sqrt (gg (ig) )
  enddo
  if (.not.lgamma) then
     call setqmod (ngm, xq, g, qmod, qpg)
     call ylmr2 (lmaxq * lmaxq, ngm, qpg, qmod, ylmkq)
     do ig = 1, ngm
        qmod (ig) = sqrt (qmod (ig) )
     enddo
  endif
  !
  !   we start by computing the FT of the effective potential
  !
  do is = 1, nspin
     do ir = 1, nrxx
        veff (ir, is) = DCMPLX (vltot (ir) + vr (ir, is), 0.d0)
     enddo
     call cft3 (veff (1, is), nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
  enddo
  !
  !
  !     We compute here four of the five integrals needed in the phonon
  !
  fact1 = DCMPLX (0.d0, - tpiba * omega)
  do na = 1, nat
     nta = ityp (na)
     do ig = 1, ngm
        sk (ig) = vlocq (ig, nta) * eigts1 (ig1 (ig), na) &
                                  * eigts2 (ig2 (ig), na) &
                                  * eigts3 (ig3 (ig), na)
     enddo
     do ipol = 1, 3
        do ig = 1, ngm
           aux5 (ig, na, ipol) = sk (ig) * (g (ipol, ig) + xq (ipol) )
        enddo
     enddo
  enddo
  do ntb = 1, ntyp
     if (tvanp (ntb) ) then
        ijh = 0
        do ih = 1, nh (ntb)
           do jh = ih, nh (ntb)
              ijh = ijh + 1
              !
              !    compute the augmentation function
              !
              call qvan2 (ngm, ih, jh, ntb, qmodg, qgm, ylmk0)

              if (.not.lgamma) call qvan2 (ngm, ih, jh, ntb, qmod, qgmq, ylmkq)
              !
              !     NB: for this integral the moving atom and the atom of Q
              !     do not necessarily coincide
              !
              !
              do nb = 1, nat
                 if (ityp (nb) == ntb) then
                    do ig = 1, ngm
                       aux1 (ig) = qgmq (ig) * eigts1 (ig1 (ig), nb) &
                                             * eigts2 (ig2 (ig), nb) &
                                             * eigts3 (ig3 (ig), nb)
                    enddo
                    do na = 1, nat
                       fact = eigqts (na) * conjg (eigqts (nb) )
                       !
                       !    nb is the atom of the augmentation function
                       !
                       do ipol = 1, 3
                          int2 (ih, jh, ipol, na, nb) = fact * fact1 * &
                                ZDOTC (ngm, aux1, 1, aux5(1,na,ipol), 1)
                          do jpol = 1, 3
                             if (jpol >= ipol) then
                                do ig = 1, ngm
                                   aux3 (ig) = aux5 (ig, na, ipol) * &
                                               (g (jpol, ig) + xq (jpol) )
                                enddo
                                int5 (ijh, ipol, jpol, na, nb) = &
                                     conjg(fact) * tpiba2 * omega * &
                                     ZDOTC (ngm, aux3, 1, aux1, 1)
                             else
                                int5 (ijh, ipol, jpol, na, nb) = &
                                     int5 (ijh, jpol, ipol, na, nb)
                             endif
                          enddo
                       enddo
                    enddo
                    if (.not.lgamma) then
                       do ig = 1, ngm
                          aux1 (ig) = qgm (ig) * eigts1 (ig1 (ig), nb) &
                                               * eigts2 (ig2 (ig), nb) &
                                               * eigts3 (ig3 (ig), nb)
                       enddo
                    endif
                    do is = 1, nspin
                       do ipol = 1, 3
                          do ig = 1, ngm
                             aux2 (ig) = veff (nl (ig), is) * g (ipol, ig)
                          enddo
                          int1 (ih, jh, ipol, nb, is) = - fact1 * &
                               ZDOTC (ngm, aux1, 1, aux2, 1)
                          do jpol = 1, 3
                             if (jpol >= ipol) then
                                do ig = 1, ngm
                                   aux3 (ig) = aux2 (ig) * g (jpol, ig)
                                enddo
                                int4 (ijh, ipol, jpol, nb, is) = - tpiba2 * &
                                     omega * ZDOTC (ngm, aux3, 1, aux1, 1)
                             else
                                int4 (ijh, ipol, jpol, nb, is) = &
                                     int4 (ijh, jpol, ipol, nb, is)
                             endif
                          enddo
                       enddo
                    enddo
                 endif
              enddo
           enddo
        enddo
        do ih = 1, nh (ntb)
           do jh = ih + 1, nh (ntb)
              !
              !    We use the symmetry properties of the integral factor
              !
              do nb = 1, nat
                 if (ityp (nb) == ntb) then
                    do ipol = 1, 3
                       do is = 1, nspin
                          int1(jh,ih,ipol,nb,is) = int1(ih,jh,ipol,nb,is)
                       enddo
                       do na = 1, nat
                          int2(jh,ih,ipol,na,nb) = int2(ih,jh,ipol,na,nb)
                       enddo
                    enddo
                 endif
              enddo
           enddo
        enddo
     endif
  enddo
#ifdef __PARA
  call reduce (2 * SIZE( int1 ), int1)
  call reduce (2 * SIZE( int2 ), int2)
  call reduce (2 * SIZE( int4 ), int4)
  call reduce (2 * SIZE( int5 ), int5)
#endif
  !      do ih=1,nh(1)
  !         do jh=1,nh(1)
  !            do ipol=1,3
  !            WRITE( stdout,'(3i5,2f20.10)') ipol,ih,jh,int2(ih,jh,ipol,1,1)
  !            enddo
  !         enddo
  !      enddo
  !      call stop_ph(.true.)
  if (.not.lgamma) then
     deallocate(qgmq)
     deallocate (qmod)
     deallocate (qpg)
     deallocate (ylmkq)
  endif
  deallocate (qgm)
  deallocate (ylmk0)
  deallocate (veff)
  deallocate (qmodg)
  deallocate (aux5)
  deallocate (aux3)
  deallocate (aux2)
  deallocate (aux1)
  deallocate (sk)

  call stop_clock ('dvanqq')
  return
end subroutine dvanqq
