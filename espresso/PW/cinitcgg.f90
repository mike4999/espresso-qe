!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
SUBROUTINE cinitcgg( npwx, npw, nstart, nbnd, psi, evc, e )
  !----------------------------------------------------------------------------
  !
  ! ... Hamiltonian diagonalization in the subspace spanned
  ! ... by nstart states psi (atomic or random wavefunctions).
  ! ... Produces on output nbnd eigenvectors (nbnd <= nstart) in evc.
  ! ... Minimal memory use - evc and psi may overlap
  ! ... Calls h_1psi to calculate H|psi>, S|psi
  !
  USE kinds, ONLY : DP
  !
  IMPLICIT NONE
  !
  INTEGER :: npw, npwx, nstart, nbnd
    ! dimension of the matrix to be diagonalized
    ! leading dimension of matrix psi, as declared in the calling pgm unit
    ! input number of states
    ! output number of states
  COMPLEX(KIND=DP) :: psi(npwx,nstart), evc(npwx,nbnd)
    ! input and output eigenvectors (may overlap) 
  REAL(KIND=DP) :: e(nbnd)
    ! eigenvalues
  !
  ! ... local variables
  !
  INTEGER                        :: m, ibnd, i, j, npw2
  COMPLEX (KIND=DP), ALLOCATABLE :: hpsi(:), spsi(:), hc(:,:,:), sc(:,:)
  REAL (KIND=DP),    ALLOCATABLE :: en(:)
  !
  COMPLEX (KIND=DP), EXTERNAL :: ZDOTC, ZDOTU
  REAL (KIND=DP),    EXTERNAL :: DDOT
  !
  !
  CALL start_clock( 'wfcrot1' )
  !
  npw2 = 2 * npw
  !
  ALLOCATE( spsi( npwx ) )
  ALLOCATE( hpsi( npwx ) )
  ALLOCATE( hc( nstart, nstart, 2 ) )
  ALLOCATE( sc( nstart, nstart ) )
  ALLOCATE( en( nstart ) )
  !
  ! ... Set up the Hamiltonian and Overlap matrix
  !
  DO m = 1, nstart
     !
     CALL h_1psi( npwx, npw, psi(1,m), hpsi, spsi )
     !
     hc(m,m,1) = DDOT( npw2, psi(1,m), 1, hpsi, 1 )
     sc(m,m)   = DDOT( npw2, psi(1,m), 1, spsi, 1 )
     !
     DO j = m + 1, nstart
        !
        hc(j,m,1) = ZDOTC( npw, psi(1,j), 1, hpsi, 1 )
        hc(m,j,1) = CONJG( hc(j,m,1) )
        !
        sc(j,m) = ZDOTC( npw, psi(1,j), 1, spsi, 1 )
        sc(m,j) = CONJG( sc(j,m) )
        !
     END DO
     !
  END DO
  !
  CALL reduce( 2 * nstart * nstart, hc(1,1,1) )
  CALL reduce( 2 * nstart * nstart, sc(1,1) )
  !
  ! ... diagonalize
  !
  CALL cdiaghg( nstart, nbnd, hc, sc, nstart, en, hc(1,1,2) )
  !
  e(1:nbnd) = en(1:nbnd)
  !
  ! ... update the basis set
  !
  DO i = 1, npw
     !
     DO ibnd = 1, nbnd
        !
        hc(ibnd,1,1) = ZDOTU( nstart, hc(1,ibnd,2), 1, psi(i,1), npwx )
        !
     END DO
     !
     evc(i,1:nbnd) = hc(1:nbnd,1,1)
     !
  END DO
  !
  DEALLOCATE( en )
  DEALLOCATE( sc )
  DEALLOCATE( hc )
  DEALLOCATE( hpsi )
  DEALLOCATE( spsi )
  !
  CALL stop_clock( 'wfcrot1' )
  !
  RETURN
  !
END SUBROUTINE cinitcgg
