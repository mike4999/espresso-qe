!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
SUBROUTINE divide_et_impera( xk, wk, isk, lsda, nkstot, nks )
  !----------------------------------------------------------------------------
  !
  ! ... This routine divides the k points (with granularity kunit) among nodes
  ! ... and sets the variable nkstot equal to the total number of k-points
  !
#if defined (__PARA)
  !
  USE io_global, only : stdout
  USE kinds,     ONLY : DP
  USE mp_global, ONLY : my_pool_id, npool, kunit
  !
  IMPLICIT NONE
  !
  INTEGER :: nkstot, nks, ik, isk(nks), rest, nbase
    ! total number of k-points
    ! number of k-points per pool
    ! counter on kpoints
    ! spin index of each kpoint (when lsda=.t.)
    ! the rest of the integer division nkstot/npool
    ! the position in the original list of the fi
    ! point that belongs to this pool - 1
  LOGICAL :: lsda
    ! logical for local spin density approx.
  REAL (KIND=DP) :: xk(3,nks), wk(nks)
    ! k-points
    ! k-point weights
  !
  !
  IF ( MOD( nks, kunit ) /= 0 ) &
     CALL errore( 'd_&_i', ' nks/kunit is not an integer', nks )
  !
  nkstot = nks
  nks    = kunit * ( nkstot / kunit / npool )
  !
  IF ( nks == 0 ) CALL errore( 'd_&_i', ' nks = 0 for some nodes', 1 )
  !
  rest = ( nkstot - nks * npool ) / kunit
  !
  IF ( ( my_pool_id + 1 ) <= rest ) nks = nks + kunit
  !
  ! ... calculates nbase = the position in the list of the first point that
  ! ...                    belong to this npool - 1
  !
  nbase = nks * my_pool_id
  !
  IF ( ( my_pool_id + 1 ) > rest ) nbase = nbase + rest * kunit
  !
  ! ... displaces these points in the first positions of the list
  !
  IF ( nbase > 0 ) THEN
     !
     xk(:,1:nks) =  xk(:,nbase+1:nbase+nks)
     !
     wk(1:nks) = wk(nbase+1:nbase+nks)
     !
     IF ( lsda ) isk(1:nks) = isk(nbase+1:nbase+nks)
     !
  END IF
  !
#endif
  !
  RETURN
  !
END SUBROUTINE divide_et_impera
