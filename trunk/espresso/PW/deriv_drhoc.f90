!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine deriv_drhoc (ngl, gl, omega, tpiba2, numeric, a_nlcc, &
 b_nlcc, alpha_nlcc, mesh, r, rab, rhoc, drhocg)
!-----------------------------------------------------------------------
#include "machine.h"
USE kinds
implicit none
!
!    first the dummy variables
!

integer :: ngl, mesh
                               ! input: the number of g shell
                               ! input: the number of radial mesh points

real(kind=DP) :: gl (ngl), r (mesh), rab (mesh), rhoc (mesh), omega, &
 tpiba2, a_nlcc, b_nlcc, alpha_nlcc, drhocg (ngl)
                               ! input: the number of G shells
                               ! input: the radial mesh
                               ! input: the derivative of theradial mesh
                               ! input: the radial core charge
                               ! input: the volume of the unit cell
                               ! input: 2 times pi / alat
                               ! input: the a_c of the analitycal form
                               ! input: the b_c of the analitical form
                               ! input: the alpha of the analytical form
                               ! output: fourier transform of d Rho_c/dG
logical :: numeric
                              ! input: if true the charge is in numeric
!
!     two parameters
!
real(kind=DP) :: pi, fpi
parameter (pi = 3.14159265358979d0, fpi = 4.d0 * pi)
!
!     here the local variables
!

real(kind=DP) :: gx, g2a, rhocg1
real(kind=DP), allocatable :: aux (:)
                                 ! the modulus of g for a given shell
                                 ! the argument of the exponential
                                 ! the fourier transform
                                 ! auxiliary memory for integration

integer :: igl, igl0  ,i
                                 ! counter on g shells
                                 ! lower limit for loop on ngl

!
! G=0 term
!
if (gl (1) .lt.1.0e-8) then
   drhocg (1) = 0.0
   igl0 = 2
else
   igl0 = 1

endif

if (numeric) then

   allocate (aux( mesh))    
   do igl = igl0, ngl
   gx = sqrt (gl (igl) * tpiba2)
   do i = 1, mesh
   aux (i) = r (i) * rhoc (i) * (r (i) * cos (gx * r (i) ) &
    / gx - sin (gx * r (i) ) / gx**2)
   enddo
   call simpson (mesh, aux, rab, rhocg1)
   drhocg (igl) = fpi / omega * rhocg1

   enddo

   deallocate (aux)
else
   do igl = igl0, ngl
   g2a = gl (igl) * tpiba2 / 4.0 / alpha_nlcc
   drhocg (igl) = - (pi / alpha_nlcc) **1.5 * exp ( - g2a) &
    * (a_nlcc + b_nlcc / alpha_nlcc * (2.5 - g2a) ) * sqrt (gl ( &
    igl) * tpiba2) / 2.0 / alpha_nlcc / omega
   enddo

endif
return
end subroutine deriv_drhoc

