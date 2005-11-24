!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------
subroutine all_electron(ild)
  !---------------------------------------------------------------
  !
  !  this routine is a driver to an all-electron calculation
  !  with the parameters given in input
  !
  !
  use  ld1inc
  use kinds, only : DP
  implicit none

  logical :: ild    ! if true compute log der
  !
  !    compute an initial estimate of the potential
  !
  call starting_potential(ndm,mesh,zval,zed,nwf,oc,nn,ll,r,enl,vxt,vpot,&
       enne,nspin)
  !
  !     solve the eigenvalue self-consistent equation
  !
  call scf
  !
  !  compute total energy
  !
  call elsd (mesh,zed,r,r2,dx,rho,zeta,vxt,vh,nlcc,  &
       nwf,enl,ll,lsd,nspin,oc,ndm,vnl,    &
       etot,ekin,encl,epseu,ehrt,ecxc,evxt)
  !
  !   add sic correction if needed
  !
  if(isic /= 0) call esic  
  !
  !   print results
  !
  call write_results 
  !
  !  compute logarithmic derivative
  !
  if (deld > 0.0_DP .and. ild) call lderiv
  !
  ! compute C6 coefficient if required
  !
  if (vdw) call c6_tfvw ( mesh, zed, dx, r(1), r2(1), rho(1,1) )
  !
  return
  !
end subroutine all_electron
