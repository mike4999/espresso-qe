!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------
function exc_t(rho,rhoc,lsd)
  !---------------------------------------------------------------
  !
  use kinds, only : DP
  implicit none
  integer:: lsd
  real(kind=dp) :: exc_t, rho(2),arho,rhot, zeta,rhoc
  real(kind=dp) :: ex, ec, vx(2), vc(2)

  real(kind=dp),parameter:: e2 =2.0_DP

  exc_t=0.0_DP

  if(lsd == 0) then
     !
     !     LDA case
     !
     rhot = rho(1) + rhoc
     arho = abs(rhot)
     if (arho.gt.1.e-30_DP) then      
        call xc(arho,ex,ec,vx,vc)
        exc_t=e2*(ex+ec)
     endif
  else
     !
     !     LSDA case
     !
     rhot = rho(1)+rho(2)+rhoc
     arho = abs(rhot)
     if (arho.gt.1.e-30_DP) then      
        zeta = (rho(1)-rho(2)) / arho
        call xc_spin(arho,zeta,ex,ec,vx(1),vx(2),vc(1),vc(2))
        exc_t=e2*(ex+ec)
     endif
  endif

  exc_t=e2*(ex+ec)

  return
end function exc_t
