!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine set_efsh (drhoscf, imode0, irr, npe)
  !-----------------------------------------------------------------------
  !  This routine calculates the FermiEnergy shift
  !   and stores it in the variable ef_sh
  !
#include "machine.h"
  USE kinds, only : DP
  USE io_global,  ONLY : stdout
  use pwcom
  use phcom
  use d3com
  implicit none
  integer :: npe, imode0, irr
  ! input: the number of perturbation
  ! input: the position of the current mode
  ! input: index of the current irr. rep.
  complex (kind = dp) :: drhoscf (nrxx, npe)
  ! input: variation of the charge density

  integer :: ipert, ik, ikk, ibnd
  ! counters
  complex (kind = dp) :: delta_n, def (npertx)
  ! the change in electron number
  ! the change of the Fermi energy for each perturbation
  real (kind = dp) :: weight, wdelta
  ! kpoint weight
  ! delta function weight
  real (kind = dp), save :: dos_ef
  ! density of states at Ef
  real (kind = dp), external :: w0gauss
  logical, save :: first = .true.
  ! Used for initialization
  !
  ! first call: calculates density of states at Ef
  !
  if (first) then
     first = .false.
     dos_ef = 0.d0
     do ik = 1, nksq
        if (lgamma) then
           ikk = ik
        else
           ikk = 2 * ik - 1
        endif
        weight = wk (ikk)
        do ibnd = 1, nbnd
           wdelta = w0gauss ( (ef - et (ibnd, ikk) ) / degauss, ngauss) &
                / degauss
           dos_ef = dos_ef + weight * wdelta
        enddo
     enddo
#ifdef __PARA
     call poolreduce (1, dos_ef)
#endif
  endif
  !
  ! determines Fermi energy shift (such that each pertubation is neutral)
  !
  WRITE( stdout, * )
  do ipert = 1, npe
     call cft3 (drhoscf (1, ipert), nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
#ifdef __PARA
     delta_n = (0.d0, 0.d0)
     if (gg (1) < 1.0d-8) delta_n = omega * drhoscf (nl (1), ipert)
     call reduce (2, delta_n)
#else
     delta_n = omega * drhoscf (nl (1), ipert)
#endif
     def (ipert) = - delta_n / dos_ef
  enddo
  !
  ! symmetrizes the Fermi energy shift
  !
  call sym_def1 (def, irr)
  do ipert = 1, npe
     ef_sh (imode0 + ipert) = DREAL (def (ipert) )
  enddo

  WRITE( stdout, '(5x,"Pert. #",i3,": Fermi energy shift (Ryd) =", &
       &            2f10.4)')  (ipert, def (ipert) , ipert = 1, npe)
  return
end subroutine set_efsh
