!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

!-----------------------------------------------------------------------
subroutine estimate (hessm1, nax3, nat, nat3)
  !-----------------------------------------------------------------------
  !
  USE kinds
  implicit none
  integer :: nax3, nat3, nat, i
  real(DP) :: hessm1 (nax3, nat3)

  hessm1(:,:) = 0.d0
  do i = 1, nat3
     hessm1 (i, i) = 1.d0
  enddo

  return
end subroutine estimate
