!
! Copyright (C) 2001 PWSCF group
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
!----------------------------------------------------------------------------
SUBROUTINE ccgdiagg( ndmx, ndim, nbnd, psi, e, btype, precondition, &
                     ethr, maxter, reorder, notconv, avg_iter, ik )
  !----------------------------------------------------------------------------
  !
  ! ... "poor man" iterative diagonalization of a complex hermitian matrix
  ! ... through preconditioned conjugate gradient algorithm
  ! ... Band-by-band algorithm with minimal use of memory
  ! ... Calls h_1psi and s_1psi to calculate H|psi> and S|psi>
  ! ... Works for generalized eigenvalue problem (US pseudopotentials) as well
  !
  USE constants,        ONLY : pi
  USE kinds,            ONLY : DP
  USE noncollin_module, ONLY : noncolin, npol
  USE uspp,             ONLY : vkb, nkb
  USE becmod,           ONLY : becp_nc
  USE bp,               ONLY : lelfield
  !
  IMPLICIT NONE
  !
  ! ... I/O variables
  !
  INTEGER,           INTENT(IN)    :: ndmx, ndim, nbnd, maxter, ik
  INTEGER,           INTENT(IN)    :: btype(nbnd)
  REAL (KIND=DP),    INTENT(IN)    :: precondition(ndmx*npol), ethr
  COMPLEX (KIND=DP), INTENT(INOUT) :: psi(ndmx*npol,nbnd)
  REAL (KIND=DP),    INTENT(INOUT) :: e(nbnd)
  INTEGER,           INTENT(OUT)   :: notconv
  REAL (KIND=DP),    INTENT(OUT)   :: avg_iter
  !
  ! ... local variables
  !
  INTEGER                        :: i, j, m, iter, moved
  COMPLEX (KIND=DP), ALLOCATABLE :: hpsi(:), spsi(:), lagrange(:), &
                                    g(:), cg(:), scg(:), ppsi(:), g0(:)  
  REAL (KIND=DP)                 :: psi_norm, a0, b0, gg0, gamma, gg, gg1, &
                                    cg0, e0, es(2)
  REAL (KIND=DP)                 :: theta, cost, sint, cos2t, sin2t
  LOGICAL                        :: reorder
  INTEGER                        :: kdim, kdmx, kdim2
  REAL (KIND=DP)                 :: empty_ethr, ethr_m
  !
  ! ... external functions
  !
  REAL (KIND=DP), EXTERNAL :: DDOT
  !
  !
  CALL start_clock( 'ccgdiagg' )
  !
  empty_ethr = MAX( ( ethr * 5.D0 ), 1.D-5 )
  !
  IF ( npol == 1 ) THEN
     !
     kdim = ndim
     kdmx = ndmx
     !
  ELSE
     !
     kdim = ndmx * npol
     kdmx = ndmx * npol
     !
  END IF
  !
  kdim2 = 2 * kdim
  !
  ALLOCATE( spsi( kdmx ) )
  ALLOCATE( scg(  kdmx ) )
  ALLOCATE( hpsi( kdmx ) )
  ALLOCATE( g(    kdmx ) )
  ALLOCATE( cg(   kdmx ) )
  ALLOCATE( g0(   kdmx ) )
  ALLOCATE( ppsi( kdmx ) )
  !    
  ALLOCATE( lagrange( nbnd ) )
  !
  avg_iter = 0.D0
  notconv  = 0
  moved    = 0
  !
  ! ... every eigenfunction is calculated separately
  !
  DO m = 1, nbnd
     !
     IF ( btype(m) == 1 ) THEN
        !
        ethr_m = ethr
        !
     ELSE
        !
        ethr_m = empty_ethr
        !
     END IF
     !
     spsi     = ZERO
     scg      = ZERO
     hpsi     = ZERO
     g        = ZERO
     cg       = ZERO
     g0       = ZERO
     ppsi     = ZERO
     lagrange = ZERO
     !
     ! ... calculate S|psi>
     !
     IF ( noncolin ) THEN
        !
        CALL ccalbec_nc( nkb, ndmx, ndim, npol, 1, becp_nc, vkb, psi(1,m) )
        !
        CALL s_psi_nc( ndmx, ndim, 1, psi(1,m), spsi )
        !
     ELSE
        !
        CALL s_1psi( ndmx, ndim, psi(1,m), spsi )
        !
     END IF
     !
     ! ... orthogonalize starting eigenfunction to those already calculated
     !
     CALL ZGEMV( 'C', kdim, m, ONE, psi, kdmx, spsi, 1, ZERO, lagrange, 1 )
     !
     CALL reduce( 2 * m, lagrange )
     !
     psi_norm = DBLE( lagrange(m) )
     !
     DO j = 1, m - 1
        !
        psi(:,m)  = psi(:,m) - lagrange(j) * psi(:,j)
        !
        psi_norm = psi_norm - &
                   ( DBLE( lagrange(j) )**2 + AIMAG( lagrange(j) )**2 )
        !
     END DO
     !
     psi_norm = SQRT( psi_norm )
     !
     psi(:,m) = psi(:,m) / psi_norm
     !
     ! ... calculate starting gradient (|hpsi> = H|psi>) ...
     !
     IF ( noncolin ) THEN
        !
        CALL h_1psi_nc( ndmx, ndim, npol, psi(1,m), hpsi, spsi )
        IF( lelfield )  CALL h_epsi_her(ndmx,ndim,1,ik,psi(1,m),hpsi)

        !
     ELSE
        !
        CALL h_1psi( ndmx, ndim, psi(1,m), hpsi, spsi )
        IF( lelfield )  CALL h_epsi_her(ndmx,ndim,1,ik,psi(1,m),hpsi)


        !
     END IF
     !
     ! ... and starting eigenvalue (e = <y|PHP|y> = <psi|H|psi>)
     !
     ! ... NB:  DDOT(2*ndim,a,1,b,1) = REAL( ZDOTC(ndim,a,1,b,1) )
     !
     e(m) = DDOT( kdim2, psi(1,m), 1, hpsi, 1 )
     !
     CALL reduce( 1, e(m) )
     !
     ! ... start iteration for this band
     !
     iterate: DO iter = 1, maxter
        !
        ! ... calculate  P (PHP)|y>
        ! ... ( P = preconditioning matrix, assumed diagonal )
        !
        g(:)    = hpsi(:) / precondition(:)
        ppsi(:) = spsi(:) / precondition(:)
        !
        ! ... ppsi is now S P(P^2)|y> = S P^2|psi>)
        !
        es(1) = DDOT( kdim2, spsi(1), 1, g(1), 1 )
        es(2) = DDOT( kdim2, spsi(1), 1, ppsi(1), 1 )
        !
        CALL reduce( 2, es )
        !
        es(1) = es(1) / es(2)
        !
        g(:) = g(:) - es(1) * ppsi(:)
        !
        ! ... e1 = <y| S P^2 PHP|y> / <y| S S P^2|y> ensures that 
        ! ... <g| S P^2|y> = 0
        ! ... orthogonalize to lowest eigenfunctions (already calculated)
        !
        ! ... scg is used as workspace
        !
        IF ( noncolin ) THEN
           !
           CALL ccalbec_nc( nkb, ndmx, ndim, npol, 1, becp_nc, vkb, g(1) )
           !
           CALL s_psi_nc( ndmx, ndim, 1, g(1), scg(1) )
           !
        ELSE
           !
           CALL s_1psi( ndmx, ndim, g(1), scg(1) )
           !
        END IF
        !
        CALL ZGEMV( 'C', kdim, ( m - 1 ), ONE, psi, &
                    kdmx, scg, 1, ZERO, lagrange, 1  )
        !
        CALL reduce( 2*m - 2, lagrange )
        !
        DO j = 1, ( m - 1 )
           !
           g(:)   = g(:)   - lagrange(j) * psi(:,j)
           scg(:) = scg(:) - lagrange(j) * psi(:,j)
           !
        END DO
        !
        IF ( iter /= 1 ) THEN
           !
           ! ... gg1 is <g(n+1)|S|g(n)> (used in Polak-Ribiere formula)
           !
           gg1 = DDOT( kdim2, g(1), 1, g0(1), 1 )
           !
           CALL reduce( 1, gg1 )
           !
        END IF
        !
        ! ... gg is <g(n+1)|S|g(n+1)>
        !
        g0(:) = scg(:)
        !
        g0(:) = g0(:) * precondition(:)
        !
        gg = DDOT( kdim2, g(1), 1, g0(1), 1 )
        !
        CALL reduce( 1, gg )
        !
        IF ( iter == 1 ) THEN
           !
           ! ... starting iteration, the conjugate gradient |cg> = |g>
           !
           gg0 = gg
           !
           cg(:) = g(:)
           !
        ELSE
           !
           ! ... |cg(n+1)> = |g(n+1)> + gamma(n) * |cg(n)>
           !
           ! ... Polak-Ribiere formula :
           !
           gamma = ( gg - gg1 ) / gg0
           gg0   = gg
           !
           cg(:) = cg(:) * gamma
           cg(:) = g + cg(:)
           !
           ! ... The following is needed because <y(n+1)| S P^2 |cg(n+1)> 
           ! ... is not 0. In fact :
           ! ... <y(n+1)| S P^2 |cg(n)> = sin(theta)*<cg(n)|S|cg(n)>
           !
           psi_norm = gamma * cg0 * sint
           !
           cg(:) = cg(:) - psi_norm * psi(:,m)
           !
        END IF
        !
        ! ... |cg> contains now the conjugate gradient
        !
        ! ... |scg> is S|cg>
        !
        IF ( noncolin ) THEN
           !
           CALL h_1psi_nc( ndmx, ndim, npol, cg(1), ppsi(1), scg(1) )
          IF( lelfield )  CALL h_epsi_her(ndmx,ndim,1,ik,cg(1),ppsi(1))

           !
        ELSE
           !
           CALL h_1psi( ndmx, ndim, cg(1), ppsi(1), scg(1) )
         IF( lelfield )  CALL h_epsi_her(ndmx,ndim,1,ik,cg(1),ppsi(1))

           !
        END IF
        !
        cg0 = DDOT( kdim2, cg(1), 1, scg(1), 1 )
        !
        CALL reduce( 1, cg0 )
        !
        cg0 = SQRT( cg0 )
        !
        ! ... |ppsi> contains now HP|cg>
        ! ... minimize <y(t)|PHP|y(t)> , where :
        ! ...                         |y(t)> = cos(t)|y> + sin(t)/cg0 |cg>
        ! ... Note that  <y|P^2S|y> = 1, <y|P^2S|cg> = 0 ,
        ! ...           <cg|P^2S|cg> = cg0^2
        ! ... so that the result is correctly normalized :
        ! ...                           <y(t)|P^2S|y(t)> = 1
        !
        a0 = 2.D0 * DDOT( kdim2, psi(1,m), 1, ppsi(1), 1 ) / cg0
        !
        CALL reduce( 1, a0 )
        !
        b0 = DDOT( kdim2, cg(1), 1, ppsi(1), 1 ) / cg0**2
        !
        CALL reduce( 1, b0 )
        !
        e0 = e(m)
        !
        theta = 0.5D0 * ATAN( a0 / ( e0 - b0 ) )
        !
        cost = COS( theta )
        sint = SIN( theta )
        !
        cos2t = cost*cost - sint*sint
        sin2t = 2.D0*cost*sint
        !
        es(1) = 0.5D0 * (   ( e0 - b0 ) * cos2t + a0 * sin2t + e0 + b0 )
        es(2) = 0.5D0 * ( - ( e0 - b0 ) * cos2t - a0 * sin2t + e0 + b0 )
        !
        ! ... there are two possible solutions, choose the minimum
        !
        IF ( es(2) < es(1) ) THEN
           !
           theta = theta + 0.5D0 * pi
           !
           cost = COS( theta )
           sint = SIN( theta )
           !
        END IF
        !
        ! ... new estimate of the eigenvalue
        !
        e(m) = MIN( es(1), es(2) )
        !
        ! ... upgrade |psi>
        !
        psi(:,m) = cost * psi(:,m) + sint / cg0 * cg(:)
        !
        ! ... here one could test convergence on the energy
        !
        IF ( ABS( e(m) - e0 ) < ethr_m ) EXIT iterate
        !
        ! ... upgrade H|psi> and S|psi>
        !
        spsi(:) = cost * spsi(:) + sint / cg0 * scg(:)
        !
        hpsi(:) = cost * hpsi(:) + sint / cg0 * ppsi(:)
        !
     END DO iterate
     !
     IF ( iter >= maxter ) notconv = notconv + 1
     !
     avg_iter = avg_iter + iter + 1
     !
     ! ... reorder eigenvalues if they are not in the right order
     ! ... ( this CAN and WILL happen in not-so-special cases )
     !
     IF ( m > 1 .AND. reorder ) THEN
        !
        IF ( e(m) - e(m-1) < - 2.D0 * ethr_m ) THEN
           !
           ! ... if the last calculated eigenvalue is not the largest...
           !
           DO i = m - 2, 1, - 1
              !
              IF ( e(m) - e(i) > 2.D0 * ethr_m ) EXIT
              !
           END DO
           !
           i = i + 1
           !
           moved = moved + 1
           !
           ! ... last calculated eigenvalue should be in the 
           ! ... i-th position: reorder
           !
           e0 = e(m)
           !
           ppsi(:) = psi(:,m)
           !
           DO j = m, i + 1, - 1
              !
              e(j) = e(j-1)
              !
              psi(:,j) = psi(:,j-1)
              !
           END DO
           !
           e(i) = e0
           !
           psi(:,i) = ppsi(:)
           !
           ! ... this procedure should be good if only a few inversions occur,
           ! ... extremely inefficient if eigenvectors are often in bad order
           ! ... ( but this should not happen )
           !
        END IF
        !
     END IF
     !
  END DO
  !
  avg_iter = avg_iter / DBLE( nbnd )
  !
  DEALLOCATE( lagrange )
  DEALLOCATE( ppsi )
  DEALLOCATE( g0 )
  DEALLOCATE( cg )
  DEALLOCATE( g )
  DEALLOCATE( hpsi )
  DEALLOCATE( scg )
  DEALLOCATE( spsi )
  !
  CALL stop_clock( 'ccgdiagg' )
  !
  RETURN
  !
END SUBROUTINE ccgdiagg
