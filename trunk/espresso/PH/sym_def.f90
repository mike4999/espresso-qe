!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!---------------------------------------------------------------------
subroutine sym_def (def, irr)
  !---------------------------------------------------------------------
  ! Symmetrizes the first order changes of the Fermi energies of an
  ! irreducible representation. These objects are defined complex because
  ! perturbations may be complex
  !
  ! Used in the q=0 metallic case only.
  !
#include"machine.h"
  use pwcom
  use parameters, only : DP
  use phcom
  implicit none

  integer :: irr
  ! input: the representation under consideration

  complex(kind=DP) :: def (3)
  ! inp/out: the fermi energy changes

  integer :: ipert, jpert, isym, irot
  ! counter on perturbations
  ! counter on perturbations
  ! counter on symmetries
  ! the rotation

  complex(kind=DP) :: w_def (3)
  ! the fermi energy changes (work array)
  if (nsymq.eq.1.and. (.not.minus_q) ) return
  !
  ! first the symmetrization   S(irotmq)*q = -q + Gi if necessary
  !
  if (minus_q) then
     call setv (6, 0.d0, w_def, 1)
     do ipert = 1, npert (irr)
        do jpert = 1, npert (irr)
           w_def (ipert) = w_def (ipert) + tmq (jpert, ipert, irr) &
                * def (jpert)
        enddo
     enddo
     do ipert = 1, npert (irr)
        def (ipert) = 0.5d0 * (def (ipert) + conjg (w_def (ipert) ) )
     enddo
  endif
  !
  ! Here we symmetrize with respect to the small group of q
  !
  call setv (6, 0.d0, w_def, 1)
  do ipert = 1, npert (irr)
     do isym = 1, nsymq
        irot = irgq (isym)
        do jpert = 1, npert (irr)
           w_def (ipert) = w_def (ipert) + t (jpert, ipert, irot, irr) &
                * def (jpert)
        enddo
     enddo
  enddo
  !
  ! normalize and exit
  !
  call DSCAL (6, 1.d0 / nsymq, w_def, 1)

  call DCOPY (6, w_def, 1, def, 1)
  return
end subroutine sym_def
