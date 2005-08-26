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
SUBROUTINE stres_us( ik, gk, sigmanlc )
  !----------------------------------------------------------------------------
  !
  ! nonlocal (separable pseudopotential) contribution to the stress
  !
  USE kinds,                ONLY : DP
  USE ions_base,            ONLY : nat, ntyp => nsp, ityp
  USE constants,            ONLY : eps8
  USE klist,                ONLY : nks, xk
  USE lsda_mod,             ONLY : current_spin, lsda, isk
  USE wvfct,                ONLY : gamma_only, npw, npwx, nbnd, igk, wg, et
  USE uspp_param,           ONLY : lmaxkb, nh, tvanp, newpseudo
  USE uspp,                 ONLY : nkb, vkb, qq, deeq
  USE wavefunctions_module, ONLY : evc
  USE mp_global,            ONLY : me_pool, root_pool
  !
  IMPLICIT NONE
  !
  ! ... First the dummy variables
  !  
  INTEGER       :: ik
  REAL(KIND=DP) :: sigmanlc(3,3), gk(3,npw)
  !
  !
  IF ( gamma_only ) THEN
     !
     CALL stres_us_gamma()
     !
  ELSE
     !
     CALL stres_us_k()
     !
  END IF      
  !
  RETURN
  !
  CONTAINS
     !
     !-----------------------------------------------------------------------
     SUBROUTINE stres_us_gamma()
       !-----------------------------------------------------------------------
       ! 
       ! ... gamma version
       !
       IMPLICIT NONE
       !
       ! ... local variables
       !
       INTEGER                       :: na, np, ibnd, ipol, jpol, l, i, &
                                        ikb, jkb, ih, jh, ijkb0
       REAL(KIND=DP)                 :: fac, xyz(3,3), q, evps, DDOT
       REAL(KIND=DP), ALLOCATABLE    :: qm1(:)
       REAL(KIND=DP), ALLOCATABLE    :: becp(:,:)
       COMPLEX(KIND=DP), ALLOCATABLE :: work1(:), work2(:), dvkb(:,:)
       ! dvkb contains the derivatives of the kb potential
       COMPLEX(KIND=DP)              :: ps
       ! xyz are the three unit vectors in the x,y,z directions
       DATA xyz / 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 /
       !
       !
       IF ( nkb == 0 ) RETURN
       !
       IF ( lsda ) current_spin = isk(ik)
       IF ( nks > 1 ) CALL init_us_2( npw, igk, xk(1,ik), vkb )
       !
       ALLOCATE( becp( nkb, nbnd ) )
       !
       CALL pw_gemm( 'Y', nkb, nbnd, npw, vkb, npwx, evc, npwx, becp, nkb )
       !
       ALLOCATE( work1( npwx ), work2( npwx ), qm1( npwx ) )
       !
       DO i = 1, npw
          q = SQRT( gk(1,i)**2 + gk(2,i)**2 + gk(3,i)**2 )
          IF ( q > eps8 ) THEN
             qm1(i) = 1.D0 / q
          ELSE
             qm1(i) = 0.D0
          END IF
       END DO
       !
       IF ( me_pool /= root_pool ) GO TO 100
       !
       ! ... diagonal contribution
       !
       evps = 0.D0
       !
       DO ibnd = 1, nbnd
          fac = wg(ibnd,ik)
          ijkb0 = 0
          DO np = 1, ntyp
             DO na = 1, nat
                IF ( ityp(na) == np ) THEN
                   DO ih = 1, nh(np)
                      ikb = ijkb0 + ih
                      ps = deeq(ih,ih,na,current_spin) - &
                           et(ibnd,ik) * qq(ih,ih,np)
                      evps = evps + fac * ps * ABS( becp(ikb,ibnd) )**2
                      !
                      IF ( tvanp(np) .OR. newpseudo(np) ) THEN
                         !
                         ! ... only in the US case there is a contribution 
                         ! ... for jh<>ih
                         ! ... we use here the symmetry in the interchange of 
                         ! ... ih and jh
                         !
                         DO jh = ( ih + 1 ), nh(np)
                            jkb = ijkb0 + jh
                            ps = deeq(ih,jh,na,current_spin) - &
                                 et(ibnd,ik) * qq(ih,jh,np)
                            evps = evps + ps * fac * 2.D0 * &
                                   becp(ikb,ibnd) * becp(jkb,ibnd)
                         END DO
                       END IF
                   END DO
                   ijkb0 = ijkb0 + nh(np)
                END IF
             END DO
          END DO
       END DO
       !
100    CONTINUE
       !
       ! ... non diagonal contribution - derivative of the bessel function
       !
       ALLOCATE( dvkb( npwx, nkb ) )
       !
       CALL gen_us_dj( ik, dvkb )
       !
       DO ibnd = 1, nbnd
          work2(:) = (0.D0,0.D0)
          ijkb0 = 0
          DO np = 1, ntyp
             DO na = 1, nat
                IF ( ityp(na) == np ) THEN
                   DO ih = 1, nh(np)
                      ikb = ijkb0 + ih
                      IF ( .NOT. ( tvanp(np) .OR. newpseudo(np) ) ) THEN
                         ps = becp(ikb,ibnd) * &
                              ( deeq(ih,ih,na,current_spin) - &
                                et(ibnd,ik) * qq(ih,ih,np) )
                      ELSE
                         !
                         ! ... in the US case there is a contribution 
                         ! ... also for jh<>ih
                         !
                         ps = (0.D0,0.D0)
                         DO jh = 1, nh(np)
                            jkb = ijkb0 + jh
                            ps = ps + becp(jkb,ibnd) * &
                                 ( deeq(ih,jh,na,current_spin) - &
                                   et(ibnd,ik) * qq(ih,jh,np) )
                         END DO
                      END IF
                      CALL ZAXPY( npw, ps, dvkb(1,ikb), 1, work2, 1 )
                   END DO
                   ijkb0 = ijkb0 + nh(np)
                END IF
             END DO
          END DO
          !
          DO ipol = 1, 3
             DO jpol = 1, ipol
                DO i = 1, npw
                   work1(i) = evc(i,ibnd) * gk(ipol,i) * gk(jpol,i) * qm1(i)
                END DO
                sigmanlc(ipol,jpol) = sigmanlc(ipol,jpol) - &
                                      2.D0 * wg(ibnd,ik) * &
                                      DDOT( 2 * npw, work1, 1, work2, 1 )
             END DO
          END DO
       END DO
       !
       ! ... non diagonal contribution - derivative of the spherical harmonics
       ! ... (no contribution from l=0)
       !
       IF ( lmaxkb == 0 ) GO TO 10
       !
       DO ipol = 1, 3
          CALL gen_us_dy( ik, xyz(1,ipol), dvkb )
          DO ibnd = 1, nbnd
             work2(:) = (0.D0,0.D0)
             ijkb0 = 0
             DO np = 1, ntyp
                DO na = 1, nat
                   IF ( ityp(na) == np ) THEN
                      DO ih = 1, nh(np)
                         ikb = ijkb0 + ih
                         IF ( .NOT. ( tvanp(np) .OR. newpseudo(np) ) ) THEN
                            ps = becp(ikb,ibnd) * &
                                 ( deeq(ih,ih,na,current_spin) - &
                                   et(ibnd,ik) * qq(ih,ih,np ) )
                         ELSE 
                            !
                            ! ... in the US case there is a contribution 
                            ! ... also for jh<>ih
                            !
                            ps = (0.D0,0.D0)
                            DO jh = 1, nh(np)
                               jkb = ijkb0 + jh
                               ps = ps + becp(jkb,ibnd) * &
                                    ( deeq(ih,jh,na,current_spin) - &
                                      et(ibnd,ik) * qq(ih,jh,np) )
                            END DO
                         END IF
                         CALL ZAXPY( npw, ps, dvkb(1,ikb), 1, work2, 1 )
                      END DO
                      ijkb0 = ijkb0 + nh(np)
                   END IF
                END DO
             END DO
             !
             DO jpol = 1, ipol
                DO i = 1, npw
                   work1(i) = evc(i,ibnd) * gk(jpol,i)
                END DO
                sigmanlc(ipol,jpol) = sigmanlc(ipol,jpol) - &
                                      2.D0 * wg(ibnd,ik) * &
                                      DDOT( 2 * npw, work1, 1, work2, 1 )
             END DO
          END DO
       END DO
       !
       ! ... the factor 2 accounts for the other half of the G-vector sphere
       !
       sigmanlc(:,:) = 2.D0 * sigmanlc(:,:)
       DO l = 1, 3
          sigmanlc(l,l) = sigmanlc(l,l) - evps
       END DO
       !
10     CONTINUE
       !
       DEALLOCATE( becp )
       DEALLOCATE( dvkb )
       DEALLOCATE( qm1, work2, work1 )
       !
       RETURN
       !
     END SUBROUTINE stres_us_gamma     
     !
     !
     !----------------------------------------------------------------------
     SUBROUTINE stres_us_k()
       !----------------------------------------------------------------------  
       !
       ! ... k-points version
       !
       IMPLICIT NONE
       !
       ! ... local variables
       !
       INTEGER                       :: na, np, ibnd, ipol, jpol, l, i, &
                                        ikb, jkb, ih, jh, ijkb0
       REAL(KIND=DP)                 :: fac, xyz (3, 3), q, evps, DDOT
       REAL(KIND=DP), ALLOCATABLE    :: qm1(:)
       COMPLEX(KIND=DP), ALLOCATABLE :: becp(:,:)
       COMPLEX(KIND=DP), ALLOCATABLE :: work1(:), work2(:), dvkb(:,:)
       ! dvkb contains the derivatives of the kb potential
       COMPLEX(KIND=DP)              :: ps
       ! xyz are the three unit vectors in the x,y,z directions
       DATA xyz / 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 /
       !
       !
       IF ( nkb == 0 ) RETURN
       !
       IF ( lsda ) current_spin = isk(ik)
       IF ( nks > 1 ) CALL init_us_2( npw, igk, xk(1,ik), vkb )
       !
       ALLOCATE( becp( nkb, nbnd ) )
       !
       CALL ccalbec( nkb, npwx, npw, nbnd, becp, vkb, evc )
       !
       ALLOCATE( work1( npwx ), work2( npwx ), qm1( npwx ) )
       !
       DO i = 1, npw
          q = SQRT( gk(1,i)**2 + gk(2,i)**2 + gk(3,i)**2 )
          IF ( q > eps8 ) THEN
             qm1(i) = 1.D0 / q
          ELSE
             qm1(i) = 0.D0
          END IF
       END DO
       !
       IF ( me_pool /= root_pool ) GO TO 100
       !
       ! ... diagonal contribution
       !
       evps = 0.D0
       !
       DO ibnd = 1, nbnd
          fac = wg(ibnd,ik)
          ijkb0 = 0
          DO np = 1, ntyp
             DO na = 1, nat
                IF ( ityp(na) == np ) THEN
                   DO ih = 1, nh(np)
                      ikb = ijkb0 + ih
                      ps = deeq(ih,ih,na,current_spin) - &
                           et(ibnd,ik) * qq(ih,ih,np)
                      evps = evps + fac * ps * ABS( becp(ikb,ibnd) )**2
                      !
                      IF ( tvanp(np) .OR. newpseudo(np) ) THEN
                         !
                         ! ... only in the US case there is a contribution 
                         ! ... for jh<>ih
                         ! ... we use here the symmetry in the interchange of 
                         ! ... ih and jh
                         !
                         DO jh = ( ih + 1 ), nh(np)
                            jkb = ijkb0 + jh
                            ps = deeq(ih,jh,na,current_spin) - &
                                 et(ibnd,ik) * qq (ih, jh, np)
                            evps = evps + ps * fac * 2.D0 * &
                                   DBLE( CONJG( becp(ikb,ibnd) ) * &
                                         becp(jkb, ibnd) )
                         END DO
                      END IF
                   END DO
                   ijkb0 = ijkb0 + nh(np)
                END IF
             END DO
          END DO
       END DO
       DO l = 1, 3
          sigmanlc(l,l) = sigmanlc(l,l) - evps
       END DO
       !
100    CONTINUE
       !
       ! ... non diagonal contribution - derivative of the bessel function
       !
       ALLOCATE( dvkb( npwx, nkb ) )
       !
       CALL gen_us_dj( ik, dvkb )
       !
       DO ibnd = 1, nbnd
          work2(:) = (0.D0,0.D0)
          ijkb0 = 0
          DO np = 1, ntyp
             DO na = 1, nat
                IF ( ityp(na) == np ) THEN
                   DO ih = 1, nh(np)
                      ikb = ijkb0 + ih
                      IF ( .NOT. ( tvanp(np) .OR. newpseudo(np) ) ) THEN
                         ps = becp(ikb, ibnd) * &
                              ( deeq(ih,ih,na,current_spin) - &
                                et(ibnd,ik) * qq(ih,ih,np) )
                      ELSE
                         !
                         ! ... in the US case there is a contribution 
                         ! ... also for jh<>ih
                         !
                         ps = (0.D0,0.D0)
                         DO jh = 1, nh(np)
                            jkb = ijkb0 + jh
                            ps = ps + becp(jkb,ibnd) * &
                                 ( deeq(ih,jh,na,current_spin) - &
                                   et(ibnd,ik) * qq(ih,jh,np) )
                         END DO
                      END IF
                      CALL ZAXPY( npw, ps, dvkb(1,ikb), 1, work2, 1 )
                   END DO
                   ijkb0 = ijkb0 + nh(np)
                END IF
             END DO
          END DO
          DO ipol = 1, 3
             DO jpol = 1, ipol
                DO i = 1, npw
                   work1(i) = evc(i,ibnd) * gk(ipol,i) * gk(jpol,i) * qm1(i)
                END DO
                sigmanlc(ipol,jpol) = sigmanlc(ipol,jpol) - &
                                      2.D0 * wg(ibnd,ik) * &
                                      DDOT( 2 * npw, work1, 1, work2, 1 )
             END DO
          END DO
       END DO
       !
       ! ... non diagonal contribution - derivative of the spherical harmonics
       ! ... (no contribution from l=0)
       !
       IF ( lmaxkb == 0 ) GO TO 10
       !
       DO ipol = 1, 3
          CALL gen_us_dy( ik, xyz(1,ipol), dvkb )
          DO ibnd = 1, nbnd
             work2(:) = (0.D0,0.D0)
             ijkb0 = 0
             DO np = 1, ntyp
                DO na = 1, nat
                   IF ( ityp(na) == np ) THEN
                      DO ih = 1, nh(np)
                         ikb = ijkb0 + ih
                         IF ( .NOT. ( tvanp(np) .OR. newpseudo(np) ) ) THEN
                            ps = becp(ikb,ibnd) * &
                                 ( deeq(ih,ih,na,current_spin) - &
                                   et(ibnd, ik) * qq(ih,ih,np) )
                         ELSE
                            !
                            ! ... in the US case there is a contribution 
                            ! ... also for jh<>ih
                            !
                            ps = (0.D0,0.D0)
                            DO jh = 1, nh(np)
                               jkb = ijkb0 + jh
                               ps = ps + becp(jkb,ibnd) * &
                                    ( deeq(ih,jh,na,current_spin) - &
                                      et(ibnd,ik) * qq(ih,jh,np) )
                            END DO
                         END IF
                         CALL ZAXPY( npw, ps, dvkb(1,ikb), 1, work2, 1 )
                      END DO
                      ijkb0 = ijkb0 + nh(np)
                   END IF
                END DO
             END DO
             DO jpol = 1, ipol
                DO i = 1, npw
                   work1(i) = evc(i,ibnd) * gk(jpol,i)
                END DO
                sigmanlc(ipol,jpol) = sigmanlc(ipol,jpol) - &
                                      2.D0 * wg(ibnd,ik) * & 
                                      DDOT( 2 * npw, work1, 1, work2, 1 )
             END DO
          END DO
       END DO
       !
10     CONTINUE
       !
       DEALLOCATE( becp )
       DEALLOCATE( dvkb )
       DEALLOCATE( work1, work2, qm1 )
       !
       RETURN
       !
     END SUBROUTINE stres_us_k
     !
END SUBROUTINE stres_us
