!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
!
!----------------------------------------------------------------------------
SUBROUTINE s_psi( lda, n, m, psi, spsi )
  !----------------------------------------------------------------------------
  !
  !    This routine applies the S matrix to m wavefunctions psi
  !    and puts the results in spsi.
  !    Requires the products of psi with all beta functions
  !    in array becp(nkb,m) (calculated in h_psi or by ccalbec)
  ! input:
  !     lda   leading dimension of arrays psi, spsi
  !     n     true dimension of psi, spsi
  !     m     number of states psi
  !     psi
  ! output:
  !     spsi  S*psi
  !
  USE parameters, ONLY : DP
  USE wvfct,      ONLY : gamma_only 
  USE us,         ONLY : vkb, nkb, okvan, nh, tvanp, qq
  USE wvfct,      ONLY : igk, g2kin
  USE gsmooth,    ONLY : nls, nr1s, nr2s, nr3s, nrx1s, nrx2s, nrx3s, nrxxs
  USE ldaU,       ONLY : lda_plus_u
  USE basis,      ONLY : ntyp, ityp, nat 
  use workspace,  ONLY :
  !
  IMPLICIT NONE
  !
  ! ... First the dummy variables
  !
  INTEGER          :: lda, n, m
  COMPLEX(KIND=DP) :: psi(lda,m), spsi(lda,m)
  !
  CALL start_clock( 's_psi' )  
  !
  IF ( gamma_only ) THEN
     !
     CALL s_psi_gamma()
     !
  ELSE
     !
     CALL s_psi_k()
     !
  END IF    
  !
  CALL stop_clock( 's_psi' )
  !
  RETURN
  !
  CONTAINS
     !
     !-----------------------------------------------------------------------
     SUBROUTINE s_psi_gamma()
       !-----------------------------------------------------------------------
       ! 
       ! ... gamma version
       !
       USE rbecmod, ONLY : becp
       !
       IMPLICIT NONE  
       !
       ! ... here the local variables
       !
       INTEGER :: ikb, jkb, ih, jh, na, nt, ijkb0, ibnd
       ! counters
       REAL(KIND=DP), ALLOCATABLE :: ps(:,:)
       ! the product vkb and psi
       !
       !
       ! ... initialize  spsi
       !
       CALL ZCOPY( lda * m, psi, 1, spsi, 1 )
       !
       ! ... The product with the beta functions
       !
       IF ( nkb == 0 .OR. .NOT. okvan ) RETURN
       !
       ALLOCATE( ps( nkb, m ) )
       !    
       ps(:,:) = 0.D0
       !
       ijkb0 = 0
       DO nt = 1, ntyp
          IF ( tvanp (nt) ) THEN
             DO na = 1, nat
                IF ( ityp(na) == nt ) THEN
                   DO ibnd = 1, m
                      DO jh = 1, nh(nt)
                         jkb = ijkb0 + jh
                         DO ih = 1, nh(nt)
                            ikb = ijkb0 + ih
                            ps(ikb,ibnd) = ps(ikb,ibnd) + &
                                           qq(ih,jh,nt) * becp(jkb,ibnd)
                         END DO
                      END DO
                   END DO
                   ijkb0 = ijkb0 + nh(nt)
                END IF
             END DO
          ELSE
             DO na = 1, nat
                IF ( ityp(na) == nt ) ijkb0 = ijkb0 + nh(nt)
             END DO
          END IF
       END DO
       !
       CALL DGEMM( 'N', 'N', 2 * n, m, nkb, 1.D0, vkb, &
                   2 * lda, ps, nkb, 1.D0, spsi, 2 * lda )
       !
       DEALLOCATE( ps ) 
       !
       RETURN
       !
     END SUBROUTINE s_psi_gamma
     !
     !-----------------------------------------------------------------------
     SUBROUTINE s_psi_k()
       !-----------------------------------------------------------------------
       !
       ! ... k-points version
       !
       USE becmod,  ONLY : becp
       !
       IMPLICIT NONE
       !
       ! ... local variables
       !
       INTEGER :: ikb, jkb, ih, jh, na, nt, ijkb0, ibnd
       ! counters
       COMPLEX(KIND=DP), ALLOCATABLE :: ps(:,:)
       ! the product vkb and psi
       !
       !
       ! ... initialize  spsi
       !
       CALL ZCOPY( lda * m, psi, 1, spsi, 1 )
       !
       ! ... The product with the beta functions
       !
       IF ( nkb == 0 .OR. .NOT. okvan ) RETURN
       !
       ALLOCATE( ps( nkb, m ) )    
       !
       ps(:,:) = (0.D0,0.D0)
       !
       ijkb0 = 0
       DO nt = 1, ntyp
          IF ( tvanp(nt) ) THEN
             DO na = 1, nat
                IF ( ityp(na) == nt ) THEN
                   DO ibnd = 1, m
                      DO jh = 1, nh(nt)
                         jkb = ijkb0 + jh
                         DO ih = 1, nh(nt)
                            ikb = ijkb0 + ih
                            ps(ikb,ibnd) = ps(ikb,ibnd) + &
                                           qq(ih,jh,nt) * becp(jkb,ibnd)
                         END DO
                      END DO
                   END DO
                   ijkb0 = ijkb0 + nh(nt)
                END IF
             END DO
          ELSE
             DO na = 1, nat
                IF ( ityp(na) == nt ) ijkb0 = ijkb0 + nh(nt)
             END DO
          END IF
       END DO
       !
       CALL ZGEMM( 'N', 'N', n, m, nkb, (1.D0, 0.D0), vkb, &
                   lda, ps, nkb, (1.D0, 0.D0), spsi, lda )
       !
       DEALLOCATE( ps )
       !
       RETURN
       !
     END SUBROUTINE s_psi_k     
     !
END subroutine s_psi
