!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
!
!----------------------------------------------------------------------------
SUBROUTINE rdiaghg( n, m, h, s, ldh, e, v )
  !----------------------------------------------------------------------------
  !
  !   calculates eigenvalues and eigenvectors of the generalized problem
  !   Hv=eSv, with H symmetric matrix, S overlap matrix .
  !   On output both matrix are unchanged
  !   Uses LAPACK routines
  !
  USE parameters
#ifdef __PARA
  USE para
#endif
  !
  IMPLICIT NONE
  !
  ! ... on INPUT
  !
  INTEGER :: n, m, ldh
  ! dimension of the matrix to be diagonalized
  ! number of eigenstates to be calculated
  ! leading dimension of h, as declared in the calling pgm unit
  REAL(KIND=DP) :: h(ldh,n)
  ! matrix to be diagonalized
  REAL(KIND=DP) :: s(ldh,n)
  ! overlap matrix
  !
  ! ... on OUTPUT
  !
  REAL(KIND=DP) :: e(n)
  ! eigenvalues
  REAL(KIND=DP) :: v(ldh,m)
  ! eigenvectors (column-wise)
  !
  ! ... LOCAL variables
  !
  INTEGER                    :: lwork, nb, ILAENV, mm, info
  ! ILAENV returns optimal block size "nb"
  ! mm = number of calculated eigenvectors
  EXTERNAL                      ILAENV
  INTEGER, ALLOCATABLE       :: iwork(:), ifail(:)
  REAL(KIND=DP), ALLOCATABLE :: sdum(:,:), hdum(:,:),  work(:)
  LOGICAL                    :: all_eigenvalues
  !
  !
  CALL start_clock( 'cdiaghg' )
  !
  all_eigenvalues = ( m == n )
  !
  ! ... check for optimal block size
  !
  nb = ILAENV( 1, 'DSYTRD', 'U', n, -1, -1, -1 )
  !
  IF ( nb < 1 .OR. nb >= n ) THEN
     lwork = 8 * n
  ELSE
     lwork = ( nb + 3 ) * n
  END IF
  !
  ! ... allocate workspace
  !
  ALLOCATE( work( lwork ) )    
  ALLOCATE( sdum( ldh, n) )
  !    
  IF ( .NOT. all_eigenvalues ) THEN
     ALLOCATE( hdum( ldh, n ) )    
     ALLOCATE( iwork(  5 * n ) )    
     ALLOCATE( ifail(  n ) )    
  END IF
  !
  ! ... input s and (see below) h are copied so that they are not destroyed
  !
  CALL DCOPY( ldh * n, s, 1, sdum, 1 )
  !
#ifdef __PARA
  !
  ! ... only the first processor diagonalize the matrix
  !
  IF ( me == 1 ) THEN
#endif
#ifdef HAS_DSYGVX
     IF ( all_eigenvalues ) THEN
#endif
        !
        ! ... calculate all eigenvalues
        !
        CALL DCOPY( ldh * n, h, 1, v, 1 )
#ifdef __AIX
        !
        ! ... there is a name conflict between essl and lapack ...
        !
        CALL DSYGV( 1, v, ldh, sdum, ldh, e, v, ldh, n, work, lwork )
        info = 0
#else
        CALL DSYGV( 1, 'V', 'U', n, v, ldh, sdum, ldh, e, work, &
                    lwork, info )
#endif
#ifdef HAS_DSYGVX
     ELSE
        !
        ! ... calculate only m lowest eigenvalues
        !
        CALL DCOPY( ldh * n, h, 1, hdum, 1 )
        CALL DSYGVX( 1, 'V', 'I', 'U', n, hdum, ldh, sdum, ldh, &
                     0.D0, 0.D0, 1, m, 0.D0, mm, e, v, ldh, work, lwork, &
                     iwork, ifail, info )
     END IF
#endif
     CALL errore( 'rdiaghg', 'info =/= 0', ABS( info ) )
#ifdef __PARA
  END IF
  !
  ! ... broadcast eigenvectors and eigenvalues to all other processors
  !
  CALL broadcast( n, e )
  CALL broadcast( ldh * m, v )
#endif
  !
  ! ... deallocate workspace
  !
  IF ( .NOT. all_eigenvalues ) THEN
     DEALLOCATE( ifail )
     DEALLOCATE( iwork )
     DEALLOCATE( hdum )
  END IF
  DEALLOCATE( sdum )
  DEALLOCATE( work )
  !
  CALL stop_clock( 'cdiaghg' )
  !
  RETURN
  !
END SUBROUTINE rdiaghg
