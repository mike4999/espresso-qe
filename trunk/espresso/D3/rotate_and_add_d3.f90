!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine rotate_and_add_d3 (phi, phi2, nat, isym, s, invs, irt, &
     rtau, sxq)
!-----------------------------------------------------------------------
!  Rotates a third order matrix (phi) in crystal coordinates according
!  to the specified symmetry operation and add the rotated matrix
!  to phi2.   phi is left unmodified.
!
#include "machine.h"
  implicit none
  !
  ! input variables
  !

  integer :: nat, isym, s (3, 3, 48), invs (48), irt (48, nat)
  ! number of atoms in the unit cell
  ! index of the symm.op.
  ! the symmetry operations
  ! index of the inverse operations
  ! index of the rotated atom

  complex (8) :: phi (3, 3, 3, nat, nat, nat), phi2 (3, 3, 3, nat, nat, nat)
  ! the input d3dyn.mat.
  ! in crystal coordinates
  ! the rotated d3dyn.mat
  ! in crystal coordinates
  real (8) :: rtau (3, 48, nat), sxq (3)
  ! for each atom and rotation gives
  ! the R vector involved
  ! the rotated q involved in this sym.op
  !
  !  local variables
  !

  integer :: na, nb, nc, sna, snb, snc, ism1, i, j, k, l, m, n
  ! counters on atoms
  ! indices of rotated atoms
  ! index of the inverse symm.op.
  ! generic counters

  real (8) :: arg
  ! argument of the phase

  complex (8) :: phase, work
  ! auxiliary variable
  real (8) :: tpi
  parameter (tpi = 2.d0 * 3.14159265358979d0)


  ism1 = invs(isym)
  do nc = 1, nat
     snc = irt(isym,nc)
     do na = 1, nat
        do nb = 1, nat
           sna = irt(isym,na)
           snb = irt(isym,nb)
           arg = (sxq (1) * (rtau(1,isym,na) - rtau(1,isym,nb) ) &
                + sxq (2) * (rtau(2,isym,na) - rtau(2,isym,nb) ) &
                + sxq (3) * (rtau(3,isym,na) - rtau(3,isym,nb) ) ) * tpi
           phase = DCMPLX(cos(arg),-sin(arg))
           do m = 1, 3
              do i = 1, 3
                 do j = 1, 3
                    work = DCMPLX(0.d0, 0.d0)
                    do k = 1, 3
                       do l = 1, 3
                          do n = 1, 3
                             work = work &
                                  + s(m,n,ism1) * s(i,k,ism1) * s(j,l,ism1) &
                                  * phi(n,k,l,nc,na,nb) * phase
                          enddo
                       enddo
                    enddo
                    phi2(m,i,j,snc,sna,snb) = phi2(m,i,j,snc,sna,snb) + work
                 enddo
              enddo

           enddo
        enddo
     enddo

  enddo
  return
end subroutine rotate_and_add_d3
