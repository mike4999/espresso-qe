!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------
subroutine iweights (nks, wk, nbnd, nelec, et, Ef, wg)
  !--------------------------------------------------------------------
  !     calculates weights for semiconductors and insulators
  !     (bands are either empty or filled)
  !     On output, Ef is the highest occupied Kohn-Sham level
  use parameters
  implicit none
  !
  integer :: nks, nbnd
  real(kind=DP), intent(IN ) :: wk (nks), et(nbnd, nks), nelec
  real(kind=DP), intent(OUT) :: wg (nbnd, nks), Ef
  real(kind=DP), parameter :: degspin = 2.d0
  integer :: kpoint, ibnd

  Ef = - 1.0e+20
  do kpoint = 1, nks
     do ibnd = 1, nbnd
        if (ibnd <= nint (nelec) / degspin) then
           wg (ibnd, kpoint) = wk (kpoint)
           Ef = MAX (Ef, et (ibnd, kpoint) )
        else
           wg (ibnd, kpoint) = 0.d0
        endif
     enddo
  enddo
#ifdef __PARA
  !
  ! find max across pools
  !
  call poolextreme (Ef, + 1)
#endif

  return
end subroutine iweights
