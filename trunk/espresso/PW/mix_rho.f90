!
! Copyright (C) 2002-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
#define ZERO ( 0.D0, 0.D0 )
!
!----------------------------------------------------------------------------
SUBROUTINE mix_rho( rhout, rhoin, nsout, nsin, alphamix, &
                    dr2, ethr, ethr_min, iter, n_iter, filename, conv )
  !----------------------------------------------------------------------------
  !
  ! ... Modified Broyden's method for charge density mixing
  ! ...         D.D. Johnson PRB 38, 12807 (1988)
  !
  ! ... On output: the mixed density is in rhoin, rhout is UNCHANGED
  !
  USE kinds,                ONLY : DP
  USE io_global,            ONLY : stdout
  USE ions_base,            ONLY : nat
  USE gvect,                ONLY : nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
                                   nl, nlm, gstart
  USE ldaU,                 ONLY : lda_plus_u, Hubbard_lmax
  USE lsda_mod,             ONLY : nspin
  USE control_flags,        ONLY : imix, ngm0, tr2
  USE wvfct,                ONLY : gamma_only
  USE wavefunctions_module, ONLY : psic
  USE klist,                ONLY : nelec
  USE parser,               ONLY : find_free_unit
  USE cell_base,            ONLY : omega
  !
  IMPLICIT NONE
  !
  ! ... First the I/O variable
  !
  CHARACTER(LEN=256) :: &
    filename                !  (in) I/O filename for mixing history
                            !  if absent everything is kept in memory
  INTEGER :: &
    iter,                  &!  (in)  counter of the number of iterations
    n_iter                  !  (in)  numb. of iterations used in mixing
  REAL(KIND=DP) :: &
    rhout(nrxx,nspin),     &! (in) the "out" density; (out) rhout-rhoin
    rhoin(nrxx,nspin),     &! (in) the "in" density; (out) the new dens.
    nsout(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat), &!
    nsin(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat),  &!
    alphamix,              &! (in) mixing factor
    dr2                     ! (out) the estimated errr on the energy
  REAL (KIND=DP) :: &
    ethr,        &! actual threshold for diagonalization
    ethr_min      ! minimal threshold for diagonalization
                  ! if in output ethr >= ethr_min a more accurate
                  ! diagonalization is needed
  LOGICAL :: &
    conv                    ! (out) if true the convergence has been reached
  INTEGER, PARAMETER :: &
    maxmix = 25             ! max number of iterations for charge mixing
  !
  ! ... Here the local variables
  !
  INTEGER ::    &
    iunmix,        &! I/O unit number of charge density file
    iunmix2,       &! I/O unit number of ns file
    iunit,         &! counter on I/O unit numbers
    iter_used,     &! actual number of iterations used
    ipos,          &! index of the present iteration
    inext,         &! index of the next iteration
    i, j,          &! counters on number of iterations
    is,            &! counter on spin component
    ig,            &! counter on G-vectors
    iwork(maxmix), &! dummy array used as output by libr. routines
    info,          &! flag saying if the exec. of libr. routines was ok
    ldim            ! 2 * Hubbard_lmax + 1
  COMPLEX(KIND=DP), ALLOCATABLE :: &
    rhocin(:,:),        &! rhocin(ngm0,nspin)
    rhocout(:,:),       &! rhocout(ngm0,nspin)
    rhoinsave(:,:),     &! rhoinsave(ngm0,nspin): work space
    rhoutsave(:,:),     &! rhoutsave(ngm0,nspin): work space
    nsinsave(:,:,:,:),  &!
    nsoutsave(:,:,:,:)   !
  REAL(KIND=DP) :: &
    betamix(maxmix,maxmix), &
    gamma0,                 &
    work(maxmix),           &
    charge
  LOGICAL :: &
    saveonfile,   &! save intermediate steps on file "filename"
    exst           ! if true the file exists
  !
  ! ... saved variables and arrays
  !
  INTEGER, SAVE :: &
    mixrho_iter = 0    ! history of mixing
  COMPLEX(KIND=DP), ALLOCATABLE, SAVE :: &
    df(:,:,:),        &! information from preceding iterations
    dv(:,:,:)          !     "  "       "     "        "  "
  REAL(KIND=DP), ALLOCATABLE, SAVE :: &
    df_ns(:,:,:,:,:), &! idem 
    dv_ns(:,:,:,:,:)   ! idem
  !
  ! ... external functions
  !
  REAL(KIND=DP), EXTERNAL :: rho_dot_product, ns_dot_product
  !
  !
  CALL start_clock( 'mix_rho' )
  !
  mixrho_iter = iter
  !
  IF ( n_iter > maxmix ) CALL errore( 'mix_rho', 'n_iter too big', 1 )
  !
  IF ( lda_plus_u ) ldim = 2 * Hubbard_lmax + 1
  !
  saveonfile = ( filename /= ' ' )
  !
  ALLOCATE( rhocin(ngm0,nspin), rhocout(ngm0,nspin) )
  !
  ! ... psic is used as work space - must be already allocated !
  !
  DO is = 1, nspin
     !
     psic(:) = DCMPLX( rhoin(:,is), 0.D0 )
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1 )
     !
     rhocin(:,is) = psic(nl(:))
     !
     psic(:) = DCMPLX( rhout(:,is), 0.D0 )
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1 )
     !
     rhocout(:,is) = psic(nl(:)) - rhocin(:,is)
     !
  END DO
  !
  IF ( lda_plus_u ) nsout(:,:,:,:) = nsout(:,:,:,:) - nsin(:,:,:,:)
  !
  dr2 = rho_dot_product( rhocout, rhocout ) + ns_dot_product( nsout, nsout )
  !
  ! ... ethr_min is dr2 * 1.D0 / nelec or - 1.0 if no check is required
  !
  IF ( ethr_min > 0.D0 ) THEN
     !
     ethr_min = dr2 * ethr_min
     !
     IF ( ethr > ethr_min ) THEN
        !
        ethr = ethr_min
        !
        ! ... rhoin and rhout are unchanged
        !
        DEALLOCATE( rhocin, rhocout )
        !
        CALL stop_clock( 'mix_rho' )
        !
        RETURN
        !
     END IF
     !   
  END IF
  !
  conv = ( dr2 < tr2 )
  !
  IF ( saveonfile ) THEN
     !
     iunmix = find_free_unit()
     CALL diropn( iunmix, filename, ( 2 * ngm0 * nspin ), exst )
     !
     IF ( lda_plus_u ) then
        iunmix2 = find_free_unit()
        CALL diropn( iunmix2, TRIM( filename ) // '.ns', &
                     ( ldim * ldim * nspin * nat ), exst )
     END IF
     !
     IF ( conv ) THEN
        !
        CLOSE( UNIT = iunmix, STATUS = 'DELETE' )
        !
        IF ( lda_plus_u ) CLOSE( UNIT = iunmix2, STATUS = 'DELETE' )
        !
        DEALLOCATE( rhocin, rhocout )
        !
        CALL stop_clock( 'mix_rho' )
        !
        RETURN
        !
     END IF
     !
     !
     IF ( mixrho_iter > 1 .AND. .NOT. exst ) THEN
        !
        CALL errore( 'mix_rho','file not found, restarting', - 1 )
        mixrho_iter = 1
        !
     END IF
     !
     IF ( .NOT. ALLOCATED( df ) ) ALLOCATE( df( ngm0, nspin, n_iter ) )
     IF ( .NOT. ALLOCATED( dv ) ) ALLOCATE( dv( ngm0, nspin, n_iter ) )
     !
     IF ( lda_plus_u ) THEN
        !
        IF ( .NOT. ALLOCATED( df_ns ) ) &
           ALLOCATE( df_ns( ldim, ldim, nspin, nat, n_iter ) )
        IF ( .NOT. ALLOCATED( dv_ns ) ) &
           ALLOCATE( dv_ns( ldim, ldim, nspin, nat, n_iter ) )
        !
     END IF
     !
  ELSE
     !
     IF ( mixrho_iter == 1 ) THEN
        !
        IF ( .NOT. ALLOCATED( df ) ) ALLOCATE( df( ngm0, nspin, n_iter ) )
        IF ( .NOT. ALLOCATED( dv ) ) ALLOCATE( dv( ngm0, nspin, n_iter ) )
        !
        IF ( lda_plus_u ) THEN
           !
           IF ( .NOT. ALLOCATED( df_ns ) ) &
              ALLOCATE( df_ns( ldim, ldim, nspin, nat, n_iter ) )
           IF ( .NOT. ALLOCATED( dv_ns ) ) &
              ALLOCATE( dv_ns( ldim, ldim, nspin, nat, n_iter ) )
           !
        END IF
        !
     END IF
     !
     IF ( conv ) THEN
        !
        DEALLOCATE( df, dv )
        !
        IF ( lda_plus_u ) DEALLOCATE( df_ns, dv_ns )
        !
        DEALLOCATE( rhocin, rhocout )
        !
        CALL stop_clock( 'mix_rho' )
        !
        RETURN
        !
     END IF
     !
     ALLOCATE( rhoinsave(ngm0,nspin), rhoutsave(ngm0,nspin) )
     !
     IF ( lda_plus_u ) &
        ALLOCATE( nsinsave (ldim,ldim,nspin,nat), &
                  nsoutsave(ldim,ldim,nspin,nat) )
     !
  END IF
  !
  ! ... copy only the high frequency Fourier component into rhoin
  ! ...                                         ( NB: rhout = rhout - rhoin )
  !
  rhoin = rhout
  !
  DO is = 1, nspin
     !
     psic(:) = ZERO
     !
     psic(nl(:)) = rhocin(:,is) + rhocout(:,is)
     !
     IF ( gamma_only ) psic(nlm(:)) = CONJG( psic(nl(:)) )
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
     !
     rhoin(:,is) = rhoin(:,is) - psic
     !
  END DO
  !
  ! ... iter_used = mixrho_iter-1  if  mixrho_iter <= n_iter
  ! ... iter_used = n_iter         if  mixrho_iter >  n_iter
  !
  iter_used = MIN( ( mixrho_iter - 1 ), n_iter )
  !
  ! ... ipos is the position in which results from the present iteration
  ! ... are stored. ipos=mixrho_iter-1 until ipos=n_iter, then back to 1,2,...
  !
  ipos = mixrho_iter - 1 - ( ( mixrho_iter - 2 ) / n_iter ) * n_iter
  !
  IF ( mixrho_iter > 1 ) THEN
     !
     IF ( saveonfile ) THEN
        !
        CALL davcio( df(1,1,ipos), 2*ngm0*nspin, iunmix, 1, -1 )
        CALL davcio( dv(1,1,ipos), 2*ngm0*nspin, iunmix, 2, -1 )
        !
        IF ( lda_plus_u ) THEN
           !
           CALL davcio( df_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,1,-1 )
           CALL davcio( dv_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,2,-1 )
           !
        END IF
        !
     END IF
     !
     df(:,:,ipos) = df(:,:,ipos) - rhocout(:,:)
     dv(:,:,ipos) = dv(:,:,ipos) - rhocin (:,:)
     !
     IF ( lda_plus_u ) THEN
        !
        df_ns(:,:,:,:,ipos) = df_ns(:,:,:,:,ipos) - nsout
        dv_ns(:,:,:,:,ipos) = dv_ns(:,:,:,:,ipos) - nsin
        !
     END IF
     !
  END IF
  !
  IF ( saveonfile ) THEN
     !
     DO i = 1, iter_used
        !
        IF ( i /= ipos ) THEN
           !
           CALL davcio( df(1,1,i), 2*ngm0*nspin, iunmix, 2*i+1, -1 )
           CALL davcio( dv(1,1,i), 2*ngm0*nspin, iunmix, 2*i+2, -1 )
           !
           IF ( lda_plus_u ) THEN
              !
              CALL davcio(df_ns(1,1,1,1,i),ldim*ldim*nspin*nat,iunmix2,2*i+1,-1)
              CALL davcio(dv_ns(1,1,1,1,i),ldim*ldim*nspin*nat,iunmix2,2*i+2,-1)
              !
           END IF
           !
        END IF
        !
     END DO
     !
     CALL davcio( rhocout, 2*ngm0*nspin, iunmix, 1, 1 )
     CALL davcio( rhocin , 2*ngm0*nspin, iunmix, 2, 1 )
     !
     IF ( mixrho_iter > 1 ) THEN
        !
        CALL davcio( df(1,1,ipos), 2*ngm0*nspin, iunmix, 2*ipos+1, 1 )
        CALL davcio( dv(1,1,ipos), 2*ngm0*nspin, iunmix, 2*ipos+2, 1 )
        !
     END IF
     !
     IF ( lda_plus_u ) THEN
        !
        CALL davcio( nsout, ldim*ldim*nspin*nat, iunmix2, 1, 1 )
        CALL davcio( nsin , ldim*ldim*nspin*nat, iunmix2, 2, 1 )
        !
        IF ( mixrho_iter > 1 ) THEN
           !
           CALL davcio( df_ns(1,1,1,1,ipos), ldim*ldim*nspin*nat, &
                        iunmix2, 2*ipos+1, 1 )
           CALL davcio( dv_ns(1,1,1,1,ipos), ldim*ldim*nspin*nat, &
                        iunmix2, 2*ipos+2, 1 )
        END IF
        !
     END IF
     !
  ELSE
     !
     rhoinsave = rhocin
     rhoutsave = rhocout
     !
     IF ( lda_plus_u ) THEN
        !
        nsinsave  = nsin
        nsoutsave = nsout
        !
     END IF
     !
  END IF
  !
  DO i = 1, iter_used
     !
     DO j = i, iter_used
        !
        betamix(i,j) = rho_dot_product( df(1,1,j), df(1,1,i) ) 
        !
        IF ( lda_plus_u ) &
           betamix(i,j) = betamix(i,j) + &
                          ns_dot_product( df_ns(1,1,1,1,j), df_ns(1,1,1,1,i) )
        !
     END DO
     !
  END DO
  !
  CALL DSYTRF( 'U', iter_used, betamix, maxmix, iwork, work, maxmix, info )
  CALL errore( 'broyden', 'factorization', info )
  !
  CALL DSYTRI( 'U', iter_used, betamix, maxmix, iwork, work, info )
  CALL errore( 'broyden', 'DSYTRI', info )
  !
  FORALL( i = 1 : iter_used, &
          j = 1 : iter_used, j > i ) betamix(j,i) = betamix(i,j)
  !
  DO i = 1, iter_used
     !
     work(i) = rho_dot_product( df(1,1,i), rhocout )
     !
     IF ( lda_plus_u ) &
        work(i) = work(i) + ns_dot_product( df_ns(1,1,1,1,i), nsout )
     !
  END DO
  !
  DO i = 1, iter_used
     !
     gamma0 = SUM( betamix(1:iter_used,i) * work(1:iter_used) )
     !
     rhocin (:,:) = rhocin (:,:) - gamma0 * dv(:,:,i)
     rhocout(:,:) = rhocout(:,:) - gamma0 * df(:,:,i)
     !
     IF ( lda_plus_u ) THEN
        !
        nsin  = nsin  - gamma0 * dv_ns(:,:,:,:,i)
        nsout = nsout - gamma0 * df_ns(:,:,:,:,i)
        !
     END IF
     !
  END DO
  !
  ! ... auxiliary vectors dv and df not needed anymore
  !
  IF ( saveonfile ) THEN
     !
     IF ( lda_plus_u ) THEN
        !
        CLOSE( iunmix2, STATUS = 'KEEP' )
        !
        DEALLOCATE( df_ns, dv_ns )
        !
     END IF
     !
     CLOSE( iunmix, STATUS = 'KEEP' )
     !
     DEALLOCATE( df, dv )
     !
  ELSE
     !
     inext = mixrho_iter - ( ( mixrho_iter - 1 ) / n_iter ) * n_iter
     !
     IF ( lda_plus_u ) THEN
        !
        df_ns(:,:,:,:,inext) = nsoutsave
        dv_ns(:,:,:,:,inext) = nsinsave
        !
        DEALLOCATE( nsinsave, nsoutsave )
        !
     END IF
     !
     df(:,:,inext) = rhoutsave(:,:)
     dv(:,:,inext) = rhoinsave(:,:)
     !
     DEALLOCATE( rhoinsave, rhoutsave )
     !
  END IF
  !
  ! ... preconditioning the new search direction
  !
  IF ( imix == 1 ) THEN
     !
     CALL approx_screening( rhocout )
     !
  ELSE IF ( imix == 2 ) THEN
     !
     CALL approx_screening2( rhocout, rhocin )
     !
  END IF
  !
  ! ... set new trial density
  !
  rhocin = rhocin + alphamix * rhocout
  !
  IF ( lda_plus_u ) nsin = nsin + alphamix * nsout
  !
  ! ... the G = 0 component of the total rho is set to nelec
  !
 ! IF ( gstart == 2 ) THEN
 !    !
 !    charge = omega * DBLE( rhocin(nl(1),1) )
 !    !
 !    IF ( nspin == 2 )  charge = charge + omega * DBLE( rhocin(nl(1),2) )
 !    !
 !    IF ( ( ABS( charge - nelec ) / charge ) > 1.D-7 ) &
 !       WRITE( stdout, '(5X,"integrated charge         =",F15.8 )' ) charge
 !    !
 !    rhocin(nl(1),:) = rhocin(nl(1),:) / charge * nelec    
 !    !
 ! END IF
  !
  ! ... back to real space
  !

  DO is = 1, nspin
     !
     psic(:) = ZERO
     !
     psic(nl(:)) = rhocin(:,is)
     !
     IF ( gamma_only ) psic(nlm(:)) = CONJG( psic(nl(:)) )
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
     !
     rhoin(:,is) = rhoin(:,is) + DBLE( psic )
     !
  END DO
  !
  ! ... clean up
  !
  DEALLOCATE( rhocout )
  DEALLOCATE( rhocin )
  !
  CALL stop_clock( 'mix_rho' )
  !
  RETURN
  !
END SUBROUTINE mix_rho
!
!----------------------------------------------------------------------------
FUNCTION rho_dot_product( rho1, rho2 ) RESULT( rho_ddot )
  !----------------------------------------------------------------------------
  !
  ! ... calculates 4pi/G^2*rho1(-G)*rho2(G) = V1_Hartree(-G)*rho2(G)
  ! ... used as an estimate of the self-consistency error on the energy
  !
  USE kinds,         ONLY : DP
  USE constants,     ONLY : e2, tpi, fpi
  USE cell_base,     ONLY : omega, tpiba2
  USE gvect,         ONLY : gg, gstart
  USE lsda_mod,      ONLY : nspin
  USE control_flags, ONLY : ngm0
  USE wvfct,         ONLY : gamma_only
  !
  IMPLICIT NONE
  !
  ! ... I/O variables
  !
  COMPLEX(KIND=DP), INTENT(IN) :: rho1(ngm0,nspin), rho2(ngm0,nspin)
  REAL(KIND=DP)                :: rho_ddot
  !
  ! ... and the local variables
  !
  REAL(KIND=DP) :: fac   ! a multiplicative factors
  INTEGER       :: ig, gi, gf
  !
  !
  gi = gstart
  gf = ngm0
  !
  rho_ddot = 0.D0
  !
  fac = e2 * fpi / tpiba2
  !
  IF ( nspin == 1 ) THEN
     !
     rho_ddot = rho_ddot + &
                fac * SUM( DBLE( CONJG( rho1(gi:gf,1) ) * &
                                        rho2(gi:gf,1) ) / gg(gi:gf) )
     !
     IF ( gamma_only ) rho_ddot = 2.D0 * rho_ddot
     !
  ELSE
     !
     ! ... first the charge
     !
     rho_ddot = rho_ddot + fac * &
                SUM( DBLE( CONJG( rho1(gi:gf,1)+rho1(gi:gf,2) ) * &
                                ( rho2(gi:gf,1)+rho2(gi:gf,2) ) ) / gg(gi:gf) )
     !
     IF ( gamma_only ) rho_ddot = 2.D0 * rho_ddot
     !
     ! ... then the magnetization
     !
     fac = e2 * fpi / tpi**2  ! lambda = 1 a.u.
     !
     ! ... G=0 term
     !
     IF ( gstart == 2 ) THEN
        !
        rho_ddot = rho_ddot + &
                   fac * DBLE( CONJG( rho1(1,1) - rho1(1,2) ) * &
                                    ( rho2(1,1) - rho2(1,2) ) )
        !
     END IF
     !
     IF ( gamma_only ) fac = 2.D0 * fac
     !
     rho_ddot = rho_ddot + fac * &
                SUM( DBLE( CONJG( rho1(gi:gf,1) - rho1(gi:gf,2) ) * &
                                ( rho2(gi:gf,1) - rho2(gi:gf,2) ) ) )
     !
  END IF
  !
  rho_ddot = rho_ddot * omega * 0.5D0
  !
  CALL reduce( 1, rho_ddot )
  !
  RETURN
  !
END FUNCTION rho_dot_product
!
!----------------------------------------------------------------------------
FUNCTION ns_dot_product( ns1, ns2 )
  !----------------------------------------------------------------------------
  !
  ! ... calculates U/2 \sum_i ns1(i)*ns2(i)
  ! ... used as an estimate of the self-consistency error on the 
  ! ... LDA+U correction to the energy
  !
  USE kinds,      ONLY : DP
  USE ldaU,       ONLY : lda_plus_u, Hubbard_lmax, Hubbard_l, Hubbard_U, &
                         Hubbard_alpha
  USE ions_base,  ONLY : nat, ityp
  USE lsda_mod,   ONLY : nspin
  !
  IMPLICIT NONE  
  !
  ! ... I/O variables
  !
  REAL(KIND=DP) :: &
    ns_dot_product                                    ! (out) the function value
  REAL(KIND=DP), INTENT(IN) :: &
    ns1(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat), &
    ns2(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat)  ! (in) the two ns 
  !
  ! ... and the local variables
  !
  INTEGER :: na, nt, m1, m2
  !
  !
  ns_dot_product = 0.D0
  !
  IF ( .NOT. lda_plus_u ) RETURN
  !
  DO na = 1, nat
     !
     nt = ityp(na)
     !
     IF ( Hubbard_U(nt) /= 0.D0 .OR. Hubbard_alpha(nt) /= 0.D0 ) THEN
        !
        m1 = 2 * Hubbard_l(nt) + 1
        m2 = 2 * Hubbard_l(nt) + 1
        !
        ns_dot_product = ns_dot_product + 0.5D0 * Hubbard_U(nt) * &
                         SUM( ns1(:m1,:m2,:nspin,na) * ns2(:m1,:m2,:nspin,na) )
        !
     END IF
     !
  END DO
  !
  IF ( nspin == 1 ) ns_dot_product = 2.D0 * ns_dot_product
  !
  RETURN
  !
END FUNCTION ns_dot_product
!
!----------------------------------------------------------------------------
SUBROUTINE approx_screening( drho )
  !----------------------------------------------------------------------------
  !
  ! ... apply an average TF preconditioning to drho
  !
  USE kinds,          ONLY : DP
  USE constants,      ONLY : e2, pi, fpi
  USE cell_base,      ONLY : omega, tpiba2
  USE gvect,          ONLY : gstart, gg
  USE klist,          ONLY : nelec
  USE lsda_mod,       ONLY : nspin
  USE control_flags,  ONLY : ngm0
  !
  IMPLICIT NONE  
  !
  ! ... I/O variables
  !
  COMPLEX(KIND=DP) :: &
    drho(ngm0,nspin) ! (in/out)
  !
  ! ... and the local variables
  !
  REAL(KIND=DP) :: rrho, rmag, rs, agg0
  INTEGER       :: ig
  !
  !
  rs = ( 3.D0 * omega / fpi / nelec )**( 1.D0 / 3.D0 )
  !
  agg0 = ( 12.D0 / pi )**( 2.D0 / 3.D0 ) / tpiba2 / rs
  !
  IF ( nspin == 1 ) THEN
     !
     drho(:,1) =  drho(:,1) * gg(:) / ( gg(:) + agg0 )
     !
  ELSE
     !
     DO ig = 1, ngm0
        !
        rrho = ( drho(ig,1) + drho(ig,2) ) * gg(ig) / ( gg(ig) + agg0 )
        rmag = ( drho(ig,1) - drho(ig,2) )
        !
        drho(ig,1) =  0.5D0 * ( rrho + rmag )
        drho(ig,2) =  0.5D0 * ( rrho - rmag )
        !
     END DO
     !
  END IF
  !
  RETURN
  !
END SUBROUTINE approx_screening
!
!----------------------------------------------------------------------------
SUBROUTINE approx_screening2( drho, rhobest )
  !----------------------------------------------------------------------------
  !
  ! ... apply a local-density dependent TF preconditioning to drho
  !
  USE kinds,                ONLY : DP
  USE constants,            ONLY : e2, pi, tpi, fpi, eps8, eps32
  USE cell_base,            ONLY : omega, tpiba2
  USE gvect,                ONLY : nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
                                   nl, nlm, gg
  USE klist,                ONLY : nelec
  USE lsda_mod,             ONLY : nspin
  USE control_flags,        ONLY : ngm0
  USE wvfct,                ONLY : gamma_only
  USE wavefunctions_module, ONLY : psic
  !
  IMPLICIT NONE
  !
  ! ... I/O variables
  !
  COMPLEX(KIND=DP) :: &
    drho(ngm0,nspin), rhobest(ngm0,nspin)
  !
  ! ... and the local variables
  !
  INTEGER, PARAMETER :: mmx = 12
  !
  INTEGER :: &
    iwork(mmx), i, j, m, info, nspin_save
  REAL(KIND=DP) :: &
    rs, min_rs, max_rs, avg_rsm1, target, dr2_best, ccc, cbest, l2smooth
  REAL(KIND=DP) :: &
    aa(mmx,mmx), invaa(mmx,mmx), bb(mmx), work(mmx), vec(mmx), agg0
  COMPLEX(KIND=DP), ALLOCATABLE :: &
    v(:,:),     &! v(ngm0,mmx)
    w(:,:),     &! w(ngm0,mmx)
    dv(:),      &! dv(ngm0)
    vbest(:),   &! vbest(ngm0)
    wbest(:)     ! wbest(ngm0)
  REAL(KIND=DP), ALLOCATABLE :: &
    alpha(:)     ! alpha(nrxx)
  !
  COMPLEX(KIND=DP) :: rrho, rmag
  INTEGER          :: ir, ig
  !
  REAL(KIND=DP), PARAMETER :: one_third = 1.D0 / 3.D0
  !
  REAL(KIND=DP), EXTERNAL :: rho_dot_product
  !
  !
  IF ( nspin == 2 ) THEN
     !
     DO ig = 1, ngm0
        !
        rrho = drho(ig,1) + drho(ig,2)
        rmag = drho(ig,1) - drho(ig,2)
        !        
        drho(ig,1) = rrho
        drho(ig,2) = rmag
        !
     END DO
     !
  END IF
  !
  nspin_save = nspin
  nspin      = 1
  target     = 0.D0
  !
  IF ( gg(1) < eps8 ) drho(1,1) = ZERO
  !
  ALLOCATE( alpha(nrxx), v(ngm0,mmx), w(ngm0,mmx), &
            dv(ngm0), vbest(ngm0), wbest(ngm0) )
  !
  v(:,:)   = ZERO
  w(:,:)   = ZERO
  dv(:)    = ZERO
  vbest(:) = ZERO
  wbest(:) = ZERO
  !
  ! ... calculate alpha from density smoothed with a lambda=0 a.u.
  !
  l2smooth = 0.D0
  !
  psic(:) = ZERO
  !
  IF ( nspin == 1 ) THEN
     !
     psic(nl(:)) = rhobest(:,1) * EXP( - 0.5D0 * l2smooth * tpiba2 * gg(:) )
     !
  ELSE
     !
     psic(nl(:)) = ( rhobest(:,1) + rhobest(:,2) ) * &
                   EXP( - 0.5D0 * l2smooth * tpiba2 * gg(:) )
     !
  END IF
  !
  IF ( gamma_only ) psic(nlm(:)) = CONJG( psic(nl(:)) )
  !
  CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
  !
  alpha(:) = DBLE( psic(:) )
  !
  min_rs   = ( 3.D0 * omega / fpi / nelec )**one_third
  max_rs   = min_rs
  avg_rsm1 = 0.D0
  !
  DO ir = 1, nrxx
     !
     alpha(ir) = ABS( alpha(ir) )
     !
     IF ( alpha(ir) > eps32 ) THEN
        !
        rs        = ( 3.D0 / fpi / alpha(ir) )**one_third
        min_rs    = MIN( min_rs, rs )
        avg_rsm1  = avg_rsm1 + 1.D0 / rs
        max_rs    = MAX( max_rs, rs )
        alpha(ir) = rs
        !
     END IF   
     !
  END DO
  !
  CALL reduce( 1, avg_rsm1 )
  !
  CALL extreme( min_rs, -1 )
  CALL extreme( max_rs, +1 )
  !
  alpha = 3.D0 * ( tpi / 3.D0 )**( 5.D0 / 3.D0 ) * alpha
  !
  avg_rsm1 = ( nr1 * nr2 * nr3 ) / avg_rsm1
  rs       = ( 3.D0 * omega / fpi / nelec )**one_third
  agg0     = ( 12.D0 / pi )**( 2.D0 / 3.D0 ) / tpiba2 / avg_rsm1
  !
  ! ... calculate deltaV and the first correction vector
  !
  psic(:) = ZERO
  !
  psic(nl(:)) = drho(:,1)
  !
  IF ( gamma_only ) psic(nlm(:)) = CONJG( psic(nl(:)) )
  !
  CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
  !
  psic(:) = psic(:) * alpha(:)
  !
  CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1 )
  !
  dv(:) = psic(nl(:)) * gg(:) * tpiba2
  v(:,1)= psic(nl(:)) * gg(:) / ( gg(:) + agg0 )
  !
  m       = 1
  ccc     = rho_dot_product( dv, dv )
  aa(:,:) = 0.D0
  bb(:)   = 0.D0
  !
  repeat_loop: DO
     !
     ! ... generate the vector w
     !     
     w(:,m) = fpi * e2 * v(:,m)
     !
     psic(:) = ZERO
     !
     psic(nl(:)) = v(:,m)
     !
     IF ( gamma_only ) psic(nlm(:)) = CONJG( psic(nl(:)) )
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
     !
     psic(:) = psic(:) * alpha(:)
     !
     CALL cft3( psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1 )
     !
     w(:,m) = w(:,m) + gg(:) * tpiba2 * psic(nl(:))
     !
     ! ... build the linear system
     !
     DO i = 1, m
        !
        aa(i,m) = rho_dot_product( w(1,i), w(1,m) )
        !
        aa(m,i) = aa(i,m)
        !
     END DO
     !
     bb(m) = rho_dot_product( w(1,m), dv )
     !
     ! ... solve it -> vec
     !
     invaa = aa
     !
     CALL DSYTRF( 'U', m, invaa, mmx, iwork, work, mmx, info )
     CALL errore( 'broyden', 'factorization', info )
     !
     CALL DSYTRI( 'U', m, invaa, mmx, iwork, work, info )
     CALL errore( 'broyden', 'DSYTRI', info )
     !     
     FORALL( i = 1 : m, j = 1 : m, j > i ) invaa(j,i) = invaa(i,j)
     !
     FORALL( i = 1 : m ) vec(i) = SUM( invaa(i,:) * bb(:) )
     !
     vbest(:) = ZERO
     wbest(:) = dv(:)
     !
     DO i = 1, m
        !
        vbest = vbest + vec(i) * v(:,i)
        wbest = wbest - vec(i) * w(:,i)
        !
     END DO
     !
     cbest = ccc - SUM( bb(:) * vec(:) )
     !
     dr2_best = rho_dot_product( wbest, wbest )
     !
     IF ( target == 0.D0 ) target = 1.D-6 * dr2_best
     !
     IF ( dr2_best < target ) THEN
        !
        drho(:,1) = vbest(:)
        !
        nspin = nspin_save
        !
        IF ( nspin == 2 ) THEN
           !
           DO ig = 1, ngm0
              !
              rrho = drho(ig,1)
              rmag = drho(ig,2)
              !
              drho(ig,1) = 0.5D0 * ( rrho + rmag )
              drho(ig,2) = 0.5D0 * ( rrho - rmag )
              !
           END DO
           !
        END IF
        !
        DEALLOCATE( alpha, v, w, dv, vbest, wbest )
        !
        EXIT repeat_loop
        !
     ELSE IF ( m >= mmx ) THEN
        !
        m = 1
        !
        v(:,m)  = vbest(:)
        aa(:,:) = 0.D0
        bb(:)   = 0.D0
        !
        CYCLE repeat_loop
        !
     END IF
     !
     m = m + 1
     !
     v(:,m) = wbest(:) / ( gg(:) + agg0 )
     !
  END DO repeat_loop
  !
  RETURN
  !
END SUBROUTINE approx_screening2
