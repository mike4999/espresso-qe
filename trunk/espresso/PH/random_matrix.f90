!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine random_matrix (irt, irgq, nsymq, minus_q, irotmq, nat, &
     wdyn, lgamma)
  !----------------------------------------------------------------------
  !
  !   Create a random hermitian matrix with non zero elements similar to
  !   the dynamical matrix of the system
  !
  !
#include "f_defs.h"
  USE kinds, only : DP
  implicit none
  !
  !    The dummy variables
  !

  integer :: nat, irt (48, nat), irgq (48), nsymq, irotmq
  ! input: number of atoms
  ! input: index of the rotated atom
  ! input: the small group of q
  ! input: the order of the small group
  ! input: the rotation sending q -> -q

  complex(kind=DP) :: wdyn (3, 3, nat, nat)
  ! output: random matrix
  logical :: lgamma, minus_q
  ! input: if true q=0
  ! input: if true there is a symmetry
  !
  !    The local variables
  !
  integer :: na, nb, ipol, jpol, isymq, irot, ira, iramq
  ! counters
  ! ira:   rotated atom
  ! iramq: rotated atom with the q->-q+G symmetry
  real(kind=DP) :: arg
  real(kind=DP), EXTERNAL :: rndm
  ! a function generating a random number
  !
  !
  wdyn (:, :, :, :) = (0d0, 0d0)
  do na = 1, nat
     do ipol = 1, 3
        wdyn (ipol, ipol, na, na) = DCMPLX (2 * rndm () - 1, 0.d0)
        do jpol = ipol + 1, 3
           if (lgamma) then
              wdyn (ipol, jpol, na, na) = DCMPLX (2 * rndm () - 1, 0.d0)
           else
              wdyn (ipol, jpol, na, na) = DCMPLX (2 * rndm () - 1, &
                                                  2 * rndm () - 1)
           endif
           wdyn (jpol, ipol, na, na) = conjg (wdyn (ipol, jpol, na, na) )
        enddo
        do nb = na + 1, nat
           do isymq = 1, nsymq
              irot = irgq (isymq)
              ira = irt (irot, na)
              if (minus_q) then
                 iramq = irt (irotmq, na)
              else
                 iramq = 0
              endif
              if ( (nb == ira) .or. (nb == iramq) ) then
                 do jpol = 1, 3
                    if (lgamma) then
                       wdyn (ipol, jpol, na, nb) = DCMPLX (2*rndm () - 1, 0.d0)
                    else
                       wdyn (ipol, jpol, na, nb) = DCMPLX (2*rndm () - 1,  &
                                                           2*rndm () - 1)
                    endif
                    wdyn(jpol, ipol, nb, na) = conjg(wdyn(ipol, jpol, na, nb))
                 enddo
                 goto 10
              endif
           enddo
10         continue
        enddo
     enddo
  enddo
  return
end subroutine random_matrix
