!
! Copyright (C) 2002-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
!
!----------------------------------------------------------------------
subroutine gen_at_dy ( ik, natw, lmax_wfc, u, dwfcat )
   !----------------------------------------------------------------------
   !
   ! This routines calculates the atomic wfc generated by the derivative
   ! (with respect to the q vector) of the spherical harmonic. This quantity
   ! is needed in computing the the internal stress tensor.
   !
   USE kinds,      ONLY : DP
   USE parameters, ONLY : nchix
   USE io_global,  ONLY : stdout
   USE constants,  ONLY : tpi, fpi
   USE atom,       ONLY : msh, r, rab, lchi, nchi, oc, chi
   USE ions_base,  ONLY : nat, ntyp => nsp, ityp, tau
   USE cell_base,  ONLY : omega, at, bg, tpiba
   USE klist,      ONLY : xk
   USE gvect,      ONLY : ig1, ig2, ig3, eigts1, eigts2, eigts3, g
   USE wvfct,      ONLY : npw, npwx, igk
   USE us,         ONLY : tab_at, dq
   !
   implicit none
   !
   !  I/O variables
   !
   integer :: ik, natw, lmax_wfc
   real (kind=DP) :: u(3)
   complex (kind=DP) :: dwfcat(npwx,natw)
   !
   ! local variables
   !
   integer :: ig, na, nt, nb, l, lm, m, i, iig, ipol, iatw, i0, i1, i2, i3
   real (kind=DP) :: arg, vqint, px, ux, vx, wx
   complex (kind=8) :: phase, pref

   real (kind=DP), allocatable :: q(:), gk(:,:), dylm(:,:), dylm_u(:,:), &
                   vchi(:), auxjl(:), chiq(:,:,:)
   !          q(npw), gk(3,npw),
   !          dylm  (npw,(lmax_wfc+1)**2),
   !          dylm_u(npw,(lmax_wfc+1)**2),
   !          vchi(ndm),
   !          auxjl(ndm),
   !          chiq(npwx,nchix,ntyp),
   complex (kind=DP), allocatable :: sk(:)
   !          sk(npw)

   allocate ( q(npw), gk(3,npw), chiq(npwx,nchix,ntyp) )

   dwfcat(:,:) = (0.d0,0.d0)


   do ig = 1,npw
      gk (1, ig) = xk (1, ik) + g (1, igk (ig) )
      gk (2, ig) = xk (2, ik) + g (2, igk (ig) )
      gk (3, ig) = xk (3, ik) + g (3, igk (ig) )
      q (ig) = gk(1, ig)**2 +  gk(2, ig)**2 + gk(3, ig)**2
   end do
   allocate ( dylm_u(npw,(lmax_wfc+1)**2) )
   allocate ( dylm(npw,(lmax_wfc+1)**2) )
   dylm_u(:,:) = 0.d0

   do ipol=1,3
      call dylmr2  ((lmax_wfc+1)**2, npw, gk, q, dylm, ipol)
      call DAXPY(npw*(lmax_wfc+1)**2,u(ipol),dylm,1,dylm_u,1)
   end do

   deallocate (dylm)

   q(:) = sqrt ( q(:) ) * tpiba

   !
   !    here we compute the radial fourier transform of the chi functions
   !
   do nt = 1,ntyp
      do nb = 1,nchi(nt)
         if (oc(nb,nt) >= 0.d0) then
            l = lchi(nb,nt)
            do ig = 1, npw
               px = q (ig) / dq - int (q (ig) / dq)
               ux = 1.d0 - px
               vx = 2.d0 - px
               wx = 3.d0 - px
               i0 = q (ig) / dq + 1
               i1 = i0 + 1
               i2 = i0 + 2
               i3 = i0 + 3
               chiq(ig,nb,nt) = tab_at (i0, nb, nt) * ux * vx * wx / 6.d0 + &
                                tab_at (i1, nb, nt) * px * vx * wx / 2.d0 - &
                                tab_at (i2, nb, nt) * px * ux * wx / 2.d0 + &
                                tab_at (i3, nb, nt) * px * ux * vx / 6.d0
            enddo
         endif
      enddo
   enddo

   allocate ( sk(npw) )

   iatw=0
   do na = 1,nat
      nt = ityp(na)
      arg=(xk(1,ik)*tau(1,na)+xk(2,ik)*tau(2,na)+xk(3,ik)*tau(3,na))*tpi
      phase=DCMPLX(cos(arg),-sin(arg))
      do ig =1,npw
         iig = igk(ig)
         sk(ig) = eigts1(ig1(iig),na) * &
                  eigts2(ig2(iig),na) * &
                  eigts3(ig3(iig),na) * phase
      end do
      do nb = 1,nchi(nt)
         if (oc(nb,nt) >= 0.d0) then
            l  = lchi(nb,nt)
            pref = (1.d0,0.d0)**l
            pref = (0.d0,1.d0)**l
            do m = 1,2*l+1
               lm = l*l+m
               iatw = iatw+1
               do ig=1,npw
                  dwfcat(ig,iatw) = chiq(ig,nb,nt) * sk(ig) * &
                                    dylm_u(ig,lm) * pref / tpiba
               end do
            enddo
         end if
      enddo
   enddo

   if (iatw.ne.natw) then
      WRITE( stdout,*) 'iatw =',iatw,'natw =',natw
      call errore('gen_at_dy','unexpected error',1)
   end if

   deallocate (sk)
   deallocate (dylm_u)
   deallocate ( q, gk, chiq )

   return
end subroutine gen_at_dy
