!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------
subroutine iweights (nks, wk, nbnd, nelec, et, Ef, wg, is, isk)
  !--------------------------------------------------------------------
  !     calculates weights for semiconductors and insulators
  !     (bands are either empty or filled)
  !     On output, Ef is the highest occupied Kohn-Sham level
  USE kinds
  USE noncollin_module, ONLY: noncolin
  implicit none
  !
  integer, intent(in) :: nks, nbnd, is, isk(nks)
  real(kind=DP), intent(in) :: wk (nks), et(nbnd, nks), nelec
  real(kind=DP), intent(out) :: wg (nbnd, nks), Ef
  real(kind=DP) :: degspin 
  integer :: kpoint, ibnd

  degspin=2.d0
  if (noncolin) degspin=1.d0
  if (is /= 0) degspin = 1.d0
  Ef = - 1.0e+20
  do kpoint = 1, nks
     if (is /= 0) then
        if (isk(kpoint) .ne.  is ) cycle
     end if
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
