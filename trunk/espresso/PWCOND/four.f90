!
! Copyright (C) 2003 A. Smogunov 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine four(alpha, w0, k, dz)
!
! This routine computes the bidimensional fourier transform of the 
! beta function. It has been implemented for s, p, d-orbitals. 
!
!   w0(z,g,m)=1/S * \int w(r) \exp{-ig r_\perp} dr_\perp
!   where w(r) - beta function of the alpha's orbital.
!
!   (see Gradshtein "Tables of integrals")
! For a fixed l it computes w0 for all m.
!
! The order of spherical harmonics used: 
!             s ; 
!             p_z, p_{-x}, p_{-y} ;
!             d_{z^2-1}, d_{-xz}, d_{-yz}, d_{x^2-y^2}, d_{xy}
!
! input:  alpha -  the number of the orbital in the full list.
!                  This orbital is the fist one for a given l.
!         k     -  the number of the slab in z direction
!         dz    -  the slab width           
!
! output: w0(z, g, m), where 
!                      z(k)< z <z(k+1) and 
!                      g - 2D g-vector
! 
#include "machine.h"
  use pwcom
  use cond
implicit none

  integer :: alpha, k, kz, ig, ign, igphi, il, il1, nbb, itp, &
             indexr, iz, lb, ir, nmesh, nmeshs
  real(kind=DP), parameter :: eps=1.d-8
  complex(kind=DP), parameter :: cim=(0.d0, 1.d0)
  real(kind=DP) :: gn, s1, s2, cs, sn, cs2, sn2, arg, rz, dz1, zr, &
                   dr, dz,  bessj  
  real(kind=DP), allocatable :: x1(:), x2(:), x3(:), x4(:)
  real(kind=DP), allocatable :: fx1(:), fx2(:), fx3(:), fx4(:), zsl(:)
  complex(kind=DP) :: exg, cong, xfact, w0(nz1, ngper, 5)
  complex(kind=DP), allocatable :: wadd(:,:)


  allocate( x1(0:ndm) )
  allocate( x2(0:ndm) )
  allocate( x3(0:ndm) )
  allocate( x4(0:ndm) ) 
  allocate( fx1( nz1 ) )
  allocate( fx2( nz1 ) )
  allocate( fx3( nz1 ) )
  allocate( fx4( nz1 ) )
  allocate( zsl( nz1) )
  allocate( wadd( nz1, ngper ) )
 
  itp=itnew(alpha)
  nbb=nbnew(alpha)
  lb=ls(alpha)
  nmesh=indexr(rsph(nbb,itp)*alat,msh(itp),r(0,itp))
  dz1=dz/nz1
  zsl(1)=(z(k)+dz1*0.5d0-taunew(3,alpha))*alat
  do kz=2, nz1
    zsl(kz)=zsl(kz-1)+dz1*alat
  enddo

  ig=0 
  do ign=1, ngpsh

     gn=gnsh(ign)
     do kz=1, nz1
       if (abs(zsl(kz))+eps.le.rsph(nbb,itp)*alat) then
         iz=indexr(zsl(kz),nmesh,r(0,itp))
         if ((nmesh-iz)/2*2.eq.nmesh-iz) then
            nmeshs=nmesh
         else
            nmeshs=nmesh+1
         endif 
         do ir=iz, nmeshs
            rz=sqrt(r(ir,itp)**2-zsl(kz)**2)
            if (lb.eq.0) then
               x1(ir)=betar(ir,nbb,itp)*bessj(0,gn*rz)
            elseif (lb.eq.1) then
               x1(ir)=betar(ir,nbb,itp)*bessj(1,gn*rz)/  &
                                           r(ir,itp)*rz
               x2(ir)=betar(ir,nbb,itp)*bessj(0,gn*rz)/  &
                                           r(ir,itp)    
            elseif (lb.eq.2) then
               x1(ir)=betar(ir,nbb,itp)                  &
                              *bessj(2,gn*rz)*rz**2/r(ir,itp)**2
               x2(ir)=betar(ir,nbb,itp)                  &
                              *bessj(1,gn*rz)*rz/r(ir,itp)**2
               x3(ir)=betar(ir,nbb,itp)*bessj(0,gn*rz)/  &
                                             r(ir,itp)**2
               x4(ir)=betar(ir,nbb,itp)*bessj(0,gn*rz)
            else
               call errore ('four','ls not programmed ',1)
            endif
         enddo
         call simpson(nmeshs-iz+1,x1(iz),rab(iz,itp),fx1(kz))  
         dr=r(iz,itp)-r(iz-1,itp)
         zr=r(iz,itp)-abs(zsl(kz))
         if (lb.eq.0) then 
            x1(iz-1)=betar(iz,nbb,itp)-                   &
               (betar(iz,nbb,itp)-betar(iz-1,nbb,itp))/dr*zr 
            fx1(kz)=fx1(kz)+(x1(iz-1)+x1(iz))*0.5d0*zr
         else
            fx1(kz)=fx1(kz)+x1(iz)*0.5d0*zr
            call simpson(nmeshs-iz+1,x2(iz),rab(iz,itp),fx2(kz))
         endif
         if (lb.eq.1) then
            if(iz.eq.1) then
              x2(iz-1)=0.d0
            else
              x2(iz-1)=(betar(iz,nbb,itp)-(betar(iz,nbb,itp)-   &
                        betar(iz-1,nbb,itp))/dr*zr)/abs(zsl(kz))
            endif 
            fx2(kz)=fx2(kz)+(x2(iz-1)+x2(iz))*0.5d0*zr           
         endif 
         if (lb.eq.2) then
            fx2(kz)=fx2(kz)+x2(iz)*0.5d0*zr 
            call simpson(nmeshs-iz+1,x3(iz),rab(iz,itp),fx3(kz))
            call simpson(nmeshs-iz+1,x4(iz),rab(iz,itp),fx4(kz)) 
            if(iz.eq.1) then
               x3(iz-1)=0.d0
            else          
               x3(iz-1)=(betar(iz,nbb,itp)-(betar(iz,nbb,itp)-   &
                         betar(iz-1,nbb,itp))/dr*zr)/abs(zsl(kz))**2
            endif
            x4(iz-1)=betar(iz,nbb,itp)-(betar(iz,nbb,itp)-       &
                      betar(iz-1,nbb,itp))/dr*zr
            fx3(kz)=fx3(kz)+(x3(iz-1)+x3(iz))*0.5d0*zr
            fx4(kz)=fx4(kz)+(x4(iz-1)+x4(iz))*0.5d0*zr
         endif
       else
          fx1(kz)=0.d0  
          fx2(kz)=0.d0  
          fx3(kz)=0.d0  
          fx4(kz)=0.d0  
       endif 
     enddo
     do igphi=1, ninsh(ign) 
        ig=ig+1 
        if (gn.gt.eps) then
          cs=gper(1,ig)*tpiba/gn
          sn=gper(2,ig)*tpiba/gn
        else
          cs=0.d0
          sn=0.d0
        endif
        cs2=cs**2-sn**2
        sn2=2*cs*sn

        do kz=1, nz1
            if (lb.eq.0) then
               w0(kz,ig,1)=fx1(kz)
            elseif (lb.eq.1) then
               w0(kz,ig,2)=cs*fx1(kz)
               w0(kz,ig,1)=fx2(kz)
               w0(kz,ig,3)=sn*fx1(kz)
            elseif (lb.eq.2) then
               w0(kz,ig,5)=sn2*fx1(kz)
               w0(kz,ig,2)=cs*fx2(kz)
               w0(kz,ig,1)=fx3(kz)
               w0(kz,ig,3)=sn*fx2(kz)
               w0(kz,ig,4)=cs2*fx1(kz)
               wadd(kz,ig)=fx4(kz)
            endif
        enddo
     enddo 

  enddo

  if (lb.eq.0) then
     s1=tpi/sarea/sqrt(fpi)
  elseif (lb.eq.1) then
     s1=tpi/sarea*sqrt(3.d0/fpi) 
  elseif (lb.eq.2) then
     s1=-tpi/2.d0/sarea*sqrt(15.d0/fpi)
     s2=tpi/sarea*sqrt(5.d0/tpi/8.d0)
  endif
  do ig=1, ngper
    do kz=1, nz1
      if (lb.eq.0) then
        w0(kz,ig,1)=s1*w0(kz,ig,1)
      elseif (lb.eq.1) then
        w0(kz,ig,2)=-cim*s1*w0(kz,ig,2)
        w0(kz,ig,1)=s1*zsl(kz)*w0(kz,ig,1)
        w0(kz,ig,3)=-cim*s1*w0(kz,ig,3)
      elseif (lb.eq.2) then
        w0(kz,ig,5)=s1*w0(kz,ig,5)
        w0(kz,ig,2)=-2.d0*cim*s1*zsl(kz)*w0(kz,ig,2)
        w0(kz,ig,1)=3.d0*zsl(kz)**2*s2*w0(kz,ig,1)-s2*wadd(kz,ig)
        w0(kz,ig,3)=-2.d0*cim*s1*zsl(kz)*w0(kz,ig,3)
        w0(kz,ig,4)=s1*w0(kz,ig,4)
      endif
    enddo
  enddo

  deallocate(x1)
  deallocate(x2)
  deallocate(x3)
  deallocate(x4)
  deallocate(fx1)
  deallocate(fx2)
  deallocate(fx3)
  deallocate(fx4)
  deallocate(zsl)
  deallocate(wadd)

  return
end subroutine four

function indexr(zz, ndim, r)
  USE kinds, only : DP
  implicit none

  integer :: iz, ndim, indexr
  real(kind=DP) :: zz, r(0:ndim) 
!
!     abs(zz)<r(indexr)
!
  iz=0       
  do while(r(iz).le.abs(zz)+1.d-10)
    iz=iz+1
  enddo
  indexr=iz
  return
end function indexr 
