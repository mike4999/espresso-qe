!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------------

subroutine symd0rho (nper, irr, d0rho, s, ftau, nsymq, irgq, t, &
     nat, nr1, nr2, nr3, nrx1, nrx2, nrx3)
  !---------------------------------------------------------------------
  !  symmetrizes q=0 drho
  !
#include"machine.h"
  !
  implicit none
  integer :: nper, irr, s (3, 3, 48), ftau (3, 48), nsymq, irgq (48) &
       , nat, nr1, nr2, nr3, nrx1, nrx2, nrx3
  ! the number of perturbations
  ! the representation under consideration

  complex (8) :: d0rho (nrx1, nrx2, nrx3, nper), t (3, 3, 48, 3 * nat)
  ! charge variation to symmetrize

  integer :: ri, rj, rk, i, j, k, ipert, jpert, isym, irot
  !
  !  the rotated points
  !  counter on mesh points
  ! counter on perturbations
  ! counter on perturbations
  ! counter on symmetries
  ! the rotation

  complex (8), allocatable :: aux1 (:,:,:,:)
  ! the symmetrized charge


  call start_clock ('symd0rho')
  do k = 1, nr3
     do j = 1, nr2
        do i = 1, nr1
           do ipert = 1, nper
              d0rho (i, j, k, ipert) = DREAL (d0rho (i, j, k, ipert) )
           enddo
        enddo
     enddo

  enddo

  if (nsymq.eq.1) return

  allocate  (aux1( nrx1, nrx2, nrx3, nper))    
  !
  ! Here we symmetrize with respect to the group
  !
  call setv (2 * nrx1 * nrx2 * nrx3 * nper, 0.d0, aux1, 1)
  do k = 1, nr3
     do j = 1, nr2
        do i = 1, nr1
           do isym = 1, nsymq
              irot = irgq (isym)
              ri = s (1, 1, irot) * (i - 1) + s (2, 1, irot) * (j - 1) + s (3, &
                   1, irot) * (k - 1) - ftau (1, irot)
              ri = mod (ri, nr1) + 1
              if (ri.lt.1) ri = ri + nr1
              rj = s (1, 2, irot) * (i - 1) + s (2, 2, irot) * (j - 1) + s (3, &
                   2, irot) * (k - 1) - ftau (2, irot)
              rj = mod (rj, nr2) + 1
              if (rj.lt.1) rj = rj + nr2
              rk = s (1, 3, irot) * (i - 1) + s (2, 3, irot) * (j - 1) + s (3, &
                   3, irot) * (k - 1) - ftau (3, irot)
              rk = mod (rk, nr3) + 1

              if (rk.lt.1) rk = rk + nr3
              do ipert = 1, nper
                 do jpert = 1, nper
                    aux1 (i, j, k, ipert) = aux1 (i, j, k, ipert) + t (jpert, ipert, &
                         irot, irr) * d0rho (ri, rj, rk, jpert)
                 enddo
              enddo
           enddo
        enddo
     enddo
  enddo

  call DSCAL (2 * nrx1 * nrx2 * nrx3 * nper, 1.d0 / float (nsymq), &
       aux1, 1)

  call ZCOPY (nrx1 * nrx2 * nrx3 * nper, aux1, 1, d0rho, 1)
  deallocate (aux1)

  call stop_clock ('symd0rho')
  return
end subroutine symd0rho
