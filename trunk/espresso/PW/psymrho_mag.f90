!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!-----------------------------------------------------------------------
SUBROUTINE psymrho_mag (rho, nrx1, nrx2, nrx3, nr1, nr2, nr3, nsym, s, ftau, &
                        bg, at)
  !-----------------------------------------------------------------------
  !  p-symmetrize the charge density.
  !
#ifdef __PARA
  !
  USE kinds,     ONLY : DP
  USE mp_global, ONLY : me_pool, root_pool
  USE pfft,      ONLY : nxx
  !
  IMPLICIT NONE
  !
  INTEGER :: nrx1, nrx2, nrx3, nr1, nr2, nr3, nsym, s, ftau, i

  REAL (KIND=DP) :: rho(nxx,3), at(3,3), bg(3,3)
  REAL (kind=DP), ALLOCATABLE :: rrho (:,:)
  !
  !
  ALLOCATE (rrho( nrx1 * nrx2 * nrx3, 3))    

  DO i=1,3
     CALL gather (rho(1,i), rrho(1,i))
  ENDDO

  IF ( me_pool == root_pool ) &
     CALL symrho_mag( rrho, nrx1, nrx2, nrx3, &
                      nr1, nr2, nr3, nsym, s, ftau, bg, at )

  DO i=1,3
     CALL scatter (rrho(1,i), rho(1,i))
  ENDDO

  DEALLOCATE (rrho)
#endif
  RETURN
END SUBROUTINE psymrho_mag

