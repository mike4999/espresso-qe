!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine compute_weight (wgg)  
!-----------------------------------------------------------------------
!
!     This routine implements Eq.15 (B) of the notes. It computes the we
!     to give to the v,v' terms in the orthogonality term
!


use pwcom 
use allocate 
use parameters, only : DP 
use phcom  
implicit none 


real(kind=DP) :: wgg (nbnd, nbnd, nksq)  
                                 ! output: the weights


integer :: ik, ikk, ikq, ibnd, jbnd  
                                 ! counter on k points
                                 ! counter on bands

real(kind=DP) :: wg1, wg2, theta, wgauss, eps  
                                 ! auxiliary
                                 ! weight function
                                 ! a small number


parameter (eps = 1.d-12)  
!
!     the weights are computed for each k point ...
!
do ik = 1, nksq  
if (lgamma) then  
   ikk = ik  
   ikq = ik  
else  
   ikk = 2 * ik - 1  
   ikq = ikk + 1  
endif  
!
!     each band v ...
!
do ibnd = 1, nbnd  
if (wk (ikk) .eq.0.d0) then  
   wg1 = 0.d0  
else  
   wg1 = wg (ibnd, ikk) / wk (ikk)  
endif  
!
!     and each band v' ...
!
do jbnd = 1, nbnd  
if (degauss.ne.0.d0) then  
   theta = wgauss ( (et (jbnd, ikq) - et (ibnd, ikk) ) / degauss, &
    0)
   wg2 = wgauss ( (ef - et (jbnd, ikq) ) / degauss, ngauss) &
    + 1.d-30
else  
   theta = 0.5d0  
   if (wk (ikk) .le.eps) then  
      wg2 = 0.d0  
   else  
      wg2 = wg (jbnd, ikk) / wk (ikk)  
   endif  
endif  
wgg (ibnd, jbnd, ik) = wg1 * (1.d0 - theta) + wg2 * theta  
enddo  
enddo  
!         do ibnd=1,nbnd
!            do jbnd=1,nbnd
!               write(6,'(3i5,f20.10)') ibnd, jbnd, ik,wgg(ibnd,jbnd,ik)
!            enddo
!         enddo


enddo  
!      call stop_ph(.true.)
return  

end subroutine compute_weight
