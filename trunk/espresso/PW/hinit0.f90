!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine hinit0
  !-----------------------------------------------------------------------
  !
  ! configuration-independent hamiltonian initialization
  !
  use pwcom
  implicit none
  ! counter on k points
  integer :: ik
  !
  ! calculate the local part of the pseudopotentials
  !
  call init_vloc
  !
  ! bring analytic potentials into numerical form on a radial mesh
  !
  call convert_to_num (ntyp, numeric, ndm, mesh, r, lmaxx, lmax, &
       lloc, nnl, aps, alps, vnl)
  !
  !   k-point independent parameters of non-local pseudopotentials
  !
  call init_us_1
  !
  rewind (iunigk)
  do ik = 1, nks
     !
     !  g2kin is used here as work space
     !
     npw=npwx
     call gk_sort (xk (1, ik), ngm, g, ecutwfc / tpiba2, npw, igk, g2kin)
     !
     call gk_l2gmap (ngm, ig_l2g(1), npw, igk, igk_l2g(1,ik) )
     !
     !  if there is only one k-point npw and igk stay in memory
     !
     if (nks.gt.1) write (iunigk) npw, igk
  enddo
  !
  if (lmovecell.and.startingconfig.eq.'file') then
     !
     !  if lmovecell and restart are both true the cell shape read from the
     !  restart file and stored in the xxx_old variable should be used
     !  instead of the current (read from input) ones.
     !  swap them, rescale the atomic positions and scale the hamiltonian
     !
     call cryst_to_cart (nat, tau, bg, - 1)
     call swap (9, at, at_old)
     call swap (1, omega, omega_old)
     call cryst_to_cart (nat, tau, at, + 1)
     call recips (at (1, 1), at (1, 2), at (1, 3), &
                  bg (1, 1), bg (1, 2), bg (1, 3) )
     call scale_h
  endif
  !
  ! initialize the structure factor
  !
  call struc_fact (nat, tau, ntyp, ityp, ngm, g, bg, nr1, nr2, nr3, &
       strf, eigts1, eigts2, eigts3)
  !
  !  calculate the total local potential
  !
  call setlocal
  !
  !  calculate the core charge (if any) for the nonlinear core correction
  !
  call set_rhoc
  !
  return
end subroutine hinit0

