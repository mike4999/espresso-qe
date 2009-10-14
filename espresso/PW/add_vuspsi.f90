!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE add_vuspsi( lda, n, m, hpsi )
  !----------------------------------------------------------------------------
  !
  !    This routine applies the Ultra-Soft Hamiltonian to a
  !    vector psi and puts the result in hpsi.
  !    Requires the products of psi with all beta functions
  !    in array becp(nkb,m) (calculated by calbec)
  ! input:
  !     lda   leading dimension of arrays psi, spsi
  !     n     true dimension of psi, spsi
  !     m     number of states psi
  ! output:
  !     hpsi  V_US|psi> is added to hpsi
  !
  USE kinds,         ONLY: DP
  USE ions_base,     ONLY: nat, ntyp => nsp, ityp
  USE lsda_mod,      ONLY: current_spin
  USE control_flags, ONLY: gamma_only
  USE noncollin_module
  USE uspp,          ONLY: vkb, nkb, deeq, deeq_nc
  USE uspp_param,    ONLY: nh
  USE becmod,        ONLY: bec_type, becp
  !
  IMPLICIT NONE
  !
  ! ... I/O variables
  !
  INTEGER, INTENT(IN)  :: lda, n, m
  COMPLEX(DP), INTENT(OUT) :: hpsi(lda*npol,m)  
  !
  ! ... here the local variables
  !
  INTEGER :: jkb, ikb, ih, jh, na, nt, ijkb0, ibnd
    ! counters
  !
  !
  CALL start_clock( 'add_vuspsi' )  
  !
  IF ( gamma_only ) THEN
     !
     CALL add_vuspsi_gamma()
     !
  ELSE IF ( noncolin) THEN
     !
     CALL add_vuspsi_nc ()
     !
  ELSE
     !
     CALL add_vuspsi_k()
     !
  END IF
  !
  CALL stop_clock( 'add_vuspsi' )  
  !
  RETURN
  !
  CONTAINS
     !
     !-----------------------------------------------------------------------
     SUBROUTINE add_vuspsi_gamma()
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       REAL(DP), ALLOCATABLE :: ps (:,:)
       !
       IF ( nkb == 0 ) RETURN
       !
       ALLOCATE (ps (nkb,m))
       ps(:,:) = 0.D0
       !
       ijkb0 = 0
       !
       DO nt = 1, ntyp
          !
          DO na = 1, nat
             !
             IF ( ityp(na) == nt ) THEN
                !
                DO ibnd = 1, m
                   !
                   DO jh = 1, nh(nt)
                      !
                      jkb = ijkb0 + jh
                      !
                      DO ih = 1, nh(nt)
                         !
                         ikb = ijkb0 + ih
                         !
                         ps(ikb,ibnd) = ps(ikb,ibnd) + &
                              deeq(ih,jh,na,current_spin) * becp%r(jkb,ibnd)
                         !
                      END DO
                      !
                   END DO
                   !
                END DO
                !
                ijkb0 = ijkb0 + nh(nt)
                !
             END IF
             !
          END DO
          !
       END DO
       !
       CALL DGEMM( 'N', 'N', ( 2 * n ), m, nkb, 1.D0, vkb, &
                   ( 2 * lda ), ps, nkb, 1.D0, hpsi, ( 2 * lda ) )
       !
       DEALLOCATE (ps)
       !
       RETURN
       !
     END SUBROUTINE add_vuspsi_gamma
     !
     !-----------------------------------------------------------------------
     SUBROUTINE add_vuspsi_k()
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       COMPLEX(DP), ALLOCATABLE :: ps (:,:)
       !
       IF ( nkb == 0 ) RETURN
       !
       ALLOCATE (ps (nkb,m))
       ps(:,:) = ( 0.D0, 0.D0 )
       !
       ijkb0 = 0
       !
       DO nt = 1, ntyp
          !
          DO na = 1, nat
             !
             IF ( ityp(na) == nt ) THEN
                !
                DO ibnd = 1, m
                   !
                   DO jh = 1, nh(nt)
                      !
                      jkb = ijkb0 + jh
                      !
                      DO ih = 1, nh(nt)
                         !
                         ikb = ijkb0 + ih
                         !
                         ps(ikb,ibnd) = ps(ikb,ibnd) + &
                              deeq(ih,jh,na,current_spin) * becp%k(jkb,ibnd)
                         !
                      END DO
                      !
                   END DO
                   !
                END DO
                !
                ijkb0 = ijkb0 + nh(nt)
                !
             END IF
             !
          END DO
          !
       END DO
       !
       CALL ZGEMM( 'N', 'N', n, m, nkb, ( 1.D0, 0.D0 ) , vkb, &
                   lda, ps, nkb, ( 1.D0, 0.D0 ) , hpsi, lda )
       !
       DEALLOCATE (ps)
       !
       RETURN
       !
     END SUBROUTINE add_vuspsi_k     
     !  
     !-----------------------------------------------------------------------
     SUBROUTINE add_vuspsi_nc()
       !-----------------------------------------------------------------------
       !
       !
       IMPLICIT NONE
       COMPLEX(DP), ALLOCATABLE :: ps (:,:,:)
       !
       IF ( nkb == 0 ) RETURN
       !
       ALLOCATE (ps(  nkb,npol, m))    
       ps (:,:,:) = (0.d0, 0.d0)
       !
       ijkb0 = 0
       !
       DO nt = 1, ntyp
          !
          DO na = 1, nat
             !
             IF ( ityp(na) == nt ) THEN
                !
                DO ibnd = 1, m
                   !
                   DO jh = 1, nh(nt)
                      !
                      jkb = ijkb0 + jh
                      !
                      DO ih = 1, nh(nt)
                         !
                         ikb = ijkb0 + ih
                         !
                         ps(ikb,1,ibnd) = ps(ikb,1,ibnd) +    & 
                              deeq_nc(ih,jh,na,1)*becp%nc(jkb,1,ibnd)+ & 
                              deeq_nc(ih,jh,na,2)*becp%nc(jkb,2,ibnd) 
                         ps(ikb,2,ibnd) = ps(ikb,2,ibnd)  +   & 
                              deeq_nc(ih,jh,na,3)*becp%nc(jkb,1,ibnd)+&
                              deeq_nc(ih,jh,na,4)*becp%nc(jkb,2,ibnd) 
                         !
                      END DO
                      !
                   END DO
                   !
                END DO
                !
                ijkb0 = ijkb0 + nh(nt)
                !
             END IF
             !
          END DO
          !
       END DO
       !
       call ZGEMM ('N', 'N', n, m*npol, nkb, ( 1.D0, 0.D0 ) , vkb, &
                   lda, ps, nkb, ( 1.D0, 0.D0 ) , hpsi, lda )
       !
       DEALLOCATE (ps)
       !
       RETURN
       !
     END SUBROUTINE add_vuspsi_nc
     !  
     !  
END SUBROUTINE add_vuspsi
