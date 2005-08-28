!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine symdyn_munu (dyn, u, xq, s, invs, rtau, irt, irgq, at, &
     bg, nsymq, nat, irotmq, minus_q)
  !-----------------------------------------------------------------------
  !
  !    This routine symmetrize the dynamical matrix written in the basis
  !    of the modes
  !
  !
#include "f_defs.h"
  USE kinds, only : DP
  implicit none
  integer :: nat, s (3, 3, 48), irt (48, nat), irgq (48), invs (48), &
       nsymq, irotmq
  ! input: the number of atoms
  ! input: the symmetry matrices
  ! input: the rotated of each atom
  ! input: the small group of q
  ! input: the inverse of each matrix
  ! input: the order of the small gro
  ! input: the symmetry q -> -q+G

  real(DP) :: xq (3), rtau (3, 48, nat), at (3, 3), bg (3, 3)
  ! input: the coordinates of q
  ! input: the R associated at each r
  ! input: direct lattice vectors
  ! input: reciprocal lattice vectors

  logical :: minus_q
  ! input: if true symmetry sends q->

  complex(DP) :: dyn (3 * nat, 3 * nat), u (3 * nat, 3 * nat)
  ! inp/out: matrix to symmetrize
  ! input: the patterns

  integer :: i, j, icart, jcart, na, nb, mu, nu
  ! counter on modes
  ! counter on modes
  ! counter on cartesian coordinates
  ! counter on cartesian coordinates
  ! counter on atoms
  ! counter on atoms
  ! counter on modes
  ! counter on modes

  complex(DP) :: work, wrk (3, 3), phi (3, 3, nat, nat)
  ! auxiliary variable
  ! auxiliary variable
  ! the dynamical matrix
  !
  ! First we transform in the cartesian coordinates
  !
  do i = 1, 3 * nat
     na = (i - 1) / 3 + 1
     icart = i - 3 * (na - 1)
     do j = 1, 3 * nat
        nb = (j - 1) / 3 + 1
        jcart = j - 3 * (nb - 1)
        work = (0.d0, 0.d0)
        do mu = 1, 3 * nat
           do nu = 1, 3 * nat
              work = work + u (i, mu) * dyn (mu, nu) * CONJG(u (j, nu) )
           enddo
        enddo
        phi (icart, jcart, na, nb) = work
     enddo
  enddo
  !
  ! Then we transform to the crystal axis
  !
  do na = 1, nat
     do nb = 1, nat
        call trntnsc (phi (1, 1, na, nb), at, bg, - 1)
     enddo
  enddo
  !
  !   And we symmetrize in this basis
  !
  call symdynph_gq (xq, phi, s, invs, rtau, irt, irgq, nsymq, nat, &
       irotmq, minus_q)
  !
  !  Back to cartesian coordinates
  !
  do na = 1, nat
     do nb = 1, nat
        call trntnsc (phi (1, 1, na, nb), at, bg, + 1)
     enddo
  enddo
  !
  !  rewrite the dynamical matrix on the array dyn with dimension 3nat x 3
  !
  do i = 1, 3 * nat
     na = (i - 1) / 3 + 1
     icart = i - 3 * (na - 1)
     do j = 1, 3 * nat
        nb = (j - 1) / 3 + 1
        jcart = j - 3 * (nb - 1)
        dyn (i, j) = phi (icart, jcart, na, nb)
     enddo

  enddo
  return
end subroutine symdyn_munu
