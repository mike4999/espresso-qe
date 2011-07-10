
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine allocate_locpot
  !-----------------------------------------------------------------------
  !
  ! dynamical allocation of arrays:
  ! local potential for each kind of atom, structure factor
  !
  USE ions_base, ONLY : nat, ntyp => nsp
  USE vlocal,    ONLY : vloc, strf
  USE gvect,     ONLY : eigts1, eigts2, eigts3, ngm, ngl
  USE grid_dimensions, ONLY : dense
  !
  implicit none
  !
  allocate (vloc( ngl, ntyp))    
  allocate (strf( ngm, ntyp))    

  allocate( eigts1(-dense%nr1:dense%nr1,nat) )
  allocate( eigts2(-dense%nr2:dense%nr2,nat) )
  allocate( eigts3(-dense%nr3:dense%nr3,nat) )

  return
end subroutine allocate_locpot

