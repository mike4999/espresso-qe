!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
#define ZERO ( 0.D0, 0.D0 )
#define ONE  ( 1.D0, 0.D0 )
!
!-----------------------------------------------------------------------
SUBROUTINE ccalbec( nkb, npwx, npw, nbnd, bec, vkb, psi )
  !-----------------------------------------------------------------------
  !
  !    This subroutine computes the dot product of the beta functions
  !    and the wavefunctions, and save them in the array bec.
  !
  USE kinds, ONLY : DP
  USE wvfct, ONLY : gamma_only
  USE gvect, ONLY : gstart
  !
  IMPLICIT NONE
  !
  ! ... here the dummy variables
  !
  INTEGER :: nkb, npwx, npw, nbnd
    ! input: the total number of beta functions
    ! input: the maximum number of plane waves
    ! input: the length of the vectors
    ! input: the number of bands
  COMPLEX(KIND=DP) ::  vkb(npwx,nkb), psi(npwx,nbnd), bec(nkb,nbnd)
    ! input: the FT of the beta functions
    ! input: the wavefunctions
    ! output: dot product of the beta and the wavefunctions
  !
  !
  IF ( nkb == 0 ) RETURN
  !
  CALL start_clock( 'ccalbec' )
  !
  IF ( gamma_only ) THEN
     !
     CALL pw_gemm( 'Y', nkb, nbnd, npw, vkb, npwx, psi, npwx, bec, nkb )
     !
  ELSE
     !   
     CALL ZGEMM( 'C', 'N', nkb, nbnd, npw, ONE, &
                 vkb, npwx, psi, npwx, ZERO, bec, nkb )
     !
     CALL reduce( 2 * nkb * nbnd, bec )
     !
  END IF
  !
  CALL stop_clock( 'ccalbec' )
  !
  RETURN
  !
END SUBROUTINE ccalbec
