!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------
         subroutine intref(lam,e,mesh,dx,r,r2,sqr, &
                     vpot,ze2,chi)
!---------------------------------------------------------------
!
!  numerical integration of the radial schroedinger equation 
!  computing logarithmic derivatives
!  thresh dermines the absolute accuracy for the eigenvalue
!
!
!
      use kinds, only : DP
      implicit none
      integer :: &
              mesh,    &     ! the mesh size
              lam           ! the angular momentum

      real(kind=dp) :: &
              r(mesh),r2(mesh),sqr(mesh),dx, & ! the radial mesh
              vpot(mesh), &   ! the local potential
              chi(mesh),  &   ! the solution
              ze2,       &   ! the nuclear charge in Ry units
              e             ! the eigenvalue

      integer :: &
              ierr,  &      ! used to control allocation
              n             ! generic counter 

      real(kind=dp) :: &
              lamsq,   &     ! combined angular momentum
              b(0:3),c(4), &   ! used for starting guess of the solution 
              b0e, rr1,rr2,& ! auxiliary
              xl1, x4l6, &
              x6l12, x8l20   !

      real(kind=dp),allocatable :: &
              al(:)      ! the known part of the differential equation

      allocate(al(mesh),stat=ierr)

      do n=1,4
         al(n)=vpot(n)-ze2/r(n)
      enddo
      call series(al,r,r2,b)


      lamsq=(lam+0.5_DP)**2
      xl1=lam+1
      x4l6=4*lam+6
      x6l12=6*lam+12
      x8l20=8*lam+20
!
!     b) find the value of solution s in the first two points
!
      b0e=b(0)-e
      c(1)=0.5*ze2/xl1
      c(2)=(c(1)*ze2+b0e)/x4l6
      c(3)=(c(2)*ze2+c(1)*b0e+b(1))/x6l12
      c(4)=(c(3)*ze2+c(2)*b0e+c(1)*b(1)+b(2))/x8l20
      rr1=(1.0_DP+r(1)*(c(1)+r(1)* &
                     (c(2)+r(1)*(c(3)+r(1)*c(4)))))*r(1)**(lam+1)
      rr2=(1.0_DP+r(2)*(c(1)+r(2)* &
                     (c(2)+r(2)*(c(3)+r(2)*c(4)))))*r(2)**(lam+1)
      chi(1)=rr1/sqr(1)
      chi(2)=rr2/sqr(2)

      do n=1,mesh
         al(n)=( (vpot(n)-e)*r2(n) + &
                      lamsq )*dx**2/12.0_DP
         al(n)=1.0_DP-al(n)
      enddo
!
!     Integrate forward the equation:
!     c) integrate the equation from 0 to matching radius
!
      do n=2,mesh-1
         chi(n+1)=((12.0_DP-10.0_DP*al(n))*chi(n) &
                   -al(n-1)*chi(n-1))/al(n+1)
      enddo
!
!    compute the logarithmic derivative and save in dlchi
!            
      do n=1,mesh
         chi(n)= chi(n)*sqr(n)
      enddo


      deallocate(al)
      return
      end
