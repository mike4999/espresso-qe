
!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------------
      subroutine compute_phius(lam,ik,psi_in,phi_out,xc,iflag,els_in)
!--------------------------------------------------------------------------
!
!     This routine computes the phi functions by pseudizing the
!     all_electron chi functions. In input it receives, the point
!     ik where the cut is done, the angular momentum lam,
!     and the correspondence with the all eletron wavefunction
!
!
!
use ld1inc
  implicit none

      real(DP) :: &
             psi_in(ndm), & ! input: the norm conserving wavefunction
             phi_out(ndm)   ! output: the us wavefunction

      character(len=2) :: els_in

      real(DP) :: &
               fae,    & ! the value of the all-electron function
               f1ae,   & ! its first derivative
               xc(8),  & ! the coefficients of the fit
               f2ae      ! the second derivative

      integer :: &
               ik, &     ! the point corresponding to rc
               ns, &     ! the function to pseudize
               iflag, &  ! if 1 print
               iok,   &  ! if 0 there are no problem
               lam       ! the angular momentum


      real(DP) :: &
               f1aep1,f1aem1,jnor, &  ! auxilairy quantities
               bm(2),  &              ! the derivative of the bessel
               fact(2), &             ! factor of normalization
               j1(ndm,8)             ! the bessel functions
     
      real(DP) :: &
            deriv_7pts, deriv2_7pts,  p1aep1,  p1aem1


      integer :: &
               n, &        ! counter on mesh points
               nc         ! counter on bessel

!
!    compute first and second derivative
!
      fae=psi_in(ik)
      f1ae=deriv_7pts(psi_in,ik,r(ik),dx)
      f2ae=deriv2_7pts(psi_in,ik,r(ik),dx)
!
!    find the q_i of the bessel functions
!      
      call find_qi(f1ae/fae,xc(4),ik,lam,2,1,iok)
      if (iok.ne.0) &
             call errore('compute_phius','problems with find_qi',1)
!
!    compute the functions
!
      do nc=1,2
         call sph_bes(ik+5,r,xc(3+nc),lam,j1(1,nc))
         fact(nc)=psi_in(ik)/(j1(ik,nc)*r(ik))
         do n=1,ik+5
            j1(n,nc)=j1(n,nc)*r(n)*fact(nc)
         enddo
      enddo
!
!    compute the second derivative and impose continuity of zero, 
!    first and second derivative
!
       
      do nc=1,2
            bm(nc)=deriv2_7pts(j1(1,nc),ik,r(ik),dx)
      enddo

      xc(2)=(f2ae-bm(1))/(bm(2)-bm(1))
      xc(1)=1.0_dp-xc(2)
      if (iflag.eq.1) then
         write(6,110) els_in,r(ik),2.0_dp*xc(5)**2
110      format (5x, ' Wfc-us ',a3,' rcutus=',f6.3, &
                '  Estimated cut-off energy= ', f8.2,' Ry')
      endif
!
!    define the phis function
!
      do n=1,ik
         phi_out(n)=xc(1)*j1(n,1)+xc(2)*j1(n,2)
      enddo

      do n=ik+1,mesh
         phi_out(n)=psi_in(n)
      enddo

      do nc=1,2
         xc(nc)=xc(nc)*fact(nc)
      enddo
      xc(3)=0.0_dp
      xc(6)=0.0_dp
      xc(7)=0.0_dp
      xc(8)=0.0_dp

      return
      end subroutine compute_phius
