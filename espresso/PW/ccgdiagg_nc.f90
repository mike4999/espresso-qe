!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine ccgdiagg_nc (nmax, n, nbnd, psi, e, precondition, eps, &
     maxter, reorder, notconv, avg_iter, npol)
  !-----------------------------------------------------------------------
  !
  ! "poor man" iterative diagonalization of a complex hermitian matrix
  ! through preconditioned conjugate gradient algorithm
  ! Band-by-band algorithm with minimal use of memory
  ! Calls h_1psi to calculate H|psi> and S|psi>
  ! Works for generalized eigenvalue problem (US pseudopotentials) as well
  !
#include "f_defs.h"
  USE kinds, only : DP
  USE uspp, ONLY : okvan, vkb, nkb
  USE wvfct, ONLY: npwx
  USE becmod, ONLY: becp_nc
  implicit none
  !
  logical :: reorder
  integer :: nmax, n, nbnd, notconv, maxter, npol
  complex(kind=DP) :: psi(nmax*npol,nbnd)
  real(kind=DP) :: e (nbnd), precondition (nmax,npol), eps, avg_iter
  !
  integer :: i, j, m, iter, moved
  complex(kind=DP), allocatable :: spsi (:), lagrange (:), &
       hpsi (:), g (:), cg (:), scg (:), ppsi (:), g0 (:)
  complex(kind=DP) :: ZDOTC
  real(kind=DP) :: norma, a0, b0, gg0, gamma, gg, gg1, theta, cg0, e0, &
       es (2), DDOT
  external ZDOTC, DDOT
  real(kind=8), parameter:: pi = 3.14159265358979d0

  call start_clock ('ccgdiagg')

  allocate (spsi(nmax*npol))    
  allocate (scg( nmax*npol))    
  allocate (hpsi(nmax*npol))    
  allocate (g(   nmax*npol))    
  allocate (cg(  nmax*npol))    
  allocate (g0(  nmax*npol))    
  allocate (ppsi(nmax*npol))    
  allocate (lagrange( nbnd))    

  spsi = (0.d0, 0.d0)
  scg = (0.d0, 0.d0)
  hpsi = (0.d0, 0.d0)
  g = (0.d0, 0.d0)
  cg = (0.d0, 0.d0)
  g0 = (0.d0, 0.d0)
  ppsi = (0.d0, 0.d0)
  lagrange = (0.d0, 0.d0)

  avg_iter = 0.d0
  notconv = 0
  moved = 0
  ! every eigenfunction is calculated separately
  do m = 1, nbnd
     !
     ! calculate S|psi>
     !
           call ccalbec_nc(nkb, npwx, n, npol, 1, becp_nc, vkb, psi(1,m))
           call s_psi_nc (nmax, n, 1, psi(1,m), spsi)
     !
     ! orthogonalize starting eigenfunction to those already calculated
     !
     do j = 1, m
        IF (npol == 1) THEN
           lagrange (j) = ZDOTC (n, psi (1, j), 1, spsi, 1)
        ELSE
           lagrange (j) = ZDOTC (nmax*npol, psi (1, j), 1, spsi, 1)
        ENDIF
     enddo
#ifdef __PARA
     call reduce (2 * m, lagrange)
#endif
     norma = DREAL (lagrange (m) )
     do j = 1, m - 1
        IF (npol == 1) THEN
           call ZAXPY (n, - lagrange (j), psi (1, j), 1, psi (1,  m), 1)
        ELSE
           call ZAXPY (nmax*npol, - lagrange (j), psi(1, j), 1, psi(1, m), 1)
        ENDIF
        norma = norma - (DREAL (lagrange (j) ) **2 + DIMAG (lagrange (j) ) **2)
     enddo
     norma = sqrt (norma)
     IF (npol == 1) THEN
        call DSCAL (2 * n, 1.d0 / norma, psi (1, m), 1)
     ELSE
        call DSCAL (2*nmax*npol, 1.d0 / norma, psi (1, m), 1)
     ENDIF
     !
     ! calculate starting gradient (|hpsi> = H|psi>)...
     !
     call h_1psi_nc (nmax, n, npol, psi(1,m), hpsi, spsi)
     !
     ! ...and starting eigenvalue (e = <y|PHP|y> = <psi|H|psi>)
     ! NB: DDOT(2*n,a,1,b,1) = DREAL(ZDOTC(n,a,1,b,1))
     !
     IF (npol == 1) THEN
        e (m) = DDOT (2 * n, psi (1, m), 1, hpsi, 1)
     ELSE
        e (m) = DDOT (2 * nmax * npol, psi (1, m), 1, hpsi, 1)
     ENDIF
#ifdef __PARA
     call reduce (1, e (m) )
#endif
     !
     ! start iteration for this band
     !
     do iter = 1, maxter
        !
        ! calculate  P (PHP)|y>  (P=preconditioning matrix, assumed diagonal)
        !
        do i = 1, n
           g (i) = hpsi (i) / precondition (i,1)
           ppsi (i) = spsi (i) / precondition (i,1)
           IF (npol == 2) THEN
              g (i+nmax) = hpsi (i+nmax) / precondition (i,2)
              ppsi (i+nmax) = spsi (i+nmax) / precondition (i,2)
           ENDIF
        enddo
        !
        ! ppsi is now S P(P^2)|y> = S P^2|psi>)
        !
        IF (npol == 1) THEN
           es (1) = DDOT (2 * n, spsi, 1, g, 1)
           es (2) = DDOT (2 * n, spsi, 1, ppsi, 1)
        ELSE
           es (1) = DDOT (2 * nmax*npol, spsi, 1, g, 1)
           es (2) = DDOT (2 * nmax*npol, spsi, 1, ppsi, 1)
        ENDIF
#ifdef __PARA
        call reduce (2, es)
#endif
        es (1) = es (1) / es (2)
        IF (npol == 1) THEN
           call DAXPY (2 * n, - es (1), ppsi, 1, g, 1)
        ELSE
           call DAXPY (2 * nmax * npol, - es (1), ppsi, 1, g, 1)
        ENDIF
        !
        ! e1 = <y| S P^2 PHP|y> / <y| S S P^2|y> ensures that <g| S P^2|y> = 0
        ! orthogonalize to lowest eigenfunctions (already calculated)
        !
        !     scg is used as workspace
        !
           call ccalbec_nc(nkb, npwx, n, npol, 1, becp_nc, vkb, g)
           call s_psi_nc (nmax, n, 1, g, scg)
        do j = 1, m - 1
           IF (npol == 1) THEN
              lagrange (j) = ZDOTC (n, psi (1, j), 1, scg, 1)
           ELSE
              lagrange (j) = ZDOTC (nmax * npol, psi (1, j), 1, scg, 1)
           ENDIF
        enddo
#ifdef __PARA
        call reduce (2 * m - 2, lagrange)
#endif
        do j = 1, m - 1
           IF (npol == 1) THEN
              call ZAXPY (n, - lagrange (j), psi (1, j), 1, g, 1)
              call ZAXPY (n, - lagrange (j), psi (1, j), 1, scg, 1)
           ELSE
              call ZAXPY (nmax*npol, - lagrange (j), psi (1, j), 1, g, 1)
              call ZAXPY (nmax*npol, - lagrange (j), psi (1, j), 1, scg, 1)
           ENDIF
        enddo
        if (iter.ne.1) then
           !
           ! gg1 is <g(n+1)|S|g(n)> (used in Polak-Ribiere formula)
           !
           IF (npol == 1) THEN
              gg1 = DDOT (2 * n, g, 1, g0, 1)
           ELSE
              gg1 = DDOT (2 * nmax * npol, g, 1, g0, 1)
           ENDIF
#ifdef __PARA
           call reduce (1, gg1)
#endif
        endif
        !
        ! gg  is <g(n+1)|S|g(n+1)>
        !
        IF (npol == 1) THEN
           call ZCOPY (n, scg, 1, g0, 1)
        ELSE
           call ZCOPY (nmax * npol, scg, 1, g0, 1)
        ENDIF
        do i = 1, n
           g0 (i) = g0 (i) * precondition (i,1)
           IF (npol == 2) THEN
              g0 (i+nmax) = g0 (i+nmax) * precondition (i,2)
           ENDIF
        enddo
        IF (npol == 1) THEN
           gg = DDOT (2 * n, g, 1, g0, 1)
        ELSE
           gg = DDOT (2 * nmax * npol, g, 1, g0, 1)
        ENDIF
#ifdef __PARA

        call reduce (1, gg)
#endif
        ! Here one can test on the norm of the gradient
        !            if (sqrt(gg).lt. eps.or. iter.eq.maxter) go to 10
        !            WRITE( stdout,*) iter, gg
        if (iter.eq.1) then
           !
           ! starting iteration, the conjugate gradient |cg> = |g>
           !
           gg0 = gg
           IF (npol == 1) THEN
              call ZCOPY (n, g, 1, cg, 1)
           ELSE
              call ZCOPY (nmax * npol, g, 1, cg, 1)
           ENDIF
        else
           !
           ! following iterations:  |cg(n+1)> = |g(n+1)> + gamma(n) |cg(n)>
           ! This is Fletcher-Reeves formula for gamma
           !                gamma = gg/gg0
           ! and this is Polak-Ribiere formula
           !
           gamma = (gg - gg1) / gg0
           gg0 = gg
           IF (npol == 1) THEN
              call DSCAL (2 * n, gamma, cg, 1)
              call DAXPY (2 * n, 1.d0, g, 1, cg, 1)
           ELSE
              call DSCAL (2 * nmax*npol, gamma, cg, 1)
              call DAXPY (2 * nmax*npol, 1.d0, g, 1, cg, 1)
           ENDIF
           !
           ! The following is needed because <y(n+1)| S P^2|cg(n+1)> is not 0
           ! In fact, <y(n+1)| S P^2|cg(n)> = sin(theta) <cg(n)|S|cg(n)>
           !**               norma = DDOT(2*n,psi(1,m),1,cg,1)
           !**               call reduce(1,norma)
           !
           norma = gamma * cg0 * sin (theta)
           IF (npol == 1) THEN
              call DAXPY (2 * n, - norma, psi (1, m), 1, cg, 1)
           ELSE
              call DAXPY (2 * nmax*npol, - norma, psi (1, m), 1, cg, 1)
           ENDIF
        endif
        !
        ! |cg> contains now the conjugate gradient
        !
        ! |scg> is S|cg>
        !
        call h_1psi_nc (nmax, n, npol, cg, ppsi, scg)
        IF (npol == 1) THEN
           cg0 = DDOT (2 * n, cg, 1, scg, 1)
        ELSE
           cg0 = DDOT (2 * nmax * npol, cg, 1, scg, 1)
        ENDIF
#ifdef __PARA
        call reduce (1, cg0)
#endif
        cg0 = sqrt (cg0)
        !
        ! |ppsi> contains now HP|cg>
        ! minimize <y(t)|PHP|y(t)> , where |y(t)>=cos(t)|y> + sin(t)/cg0 |cg>
        ! Note that <y|P^2S|y> = 1 , <y|P^2S|cg> = 0 , <cg|P^2S|cg> = cg0^2
        ! so that the result is correctly normalized: <y(t)|P^2S|y(t)> = 1
        !
        IF (npol == 1) THEN
           a0 = 2.d0 * DDOT (2 * n, psi (1, m), 1, ppsi, 1) / cg0
        ELSE
           a0 = 2.d0 * DDOT (2 * nmax * npol, psi (1, m), 1, ppsi, 1) / cg0
        ENDIF
#ifdef __PARA
        call reduce (1, a0)
#endif
        IF (npol == 1) THEN
           b0 = DDOT (2 * n, cg, 1, ppsi, 1) / cg0**2
        ELSE
           b0 = DDOT (2 * nmax * npol, cg, 1, ppsi, 1) / cg0**2
        ENDIF
#ifdef __PARA
        call reduce (1, b0)
#endif
        e0 = e (m)
        theta = atan (a0 / (e0 - b0) ) / 2.d0
        es (1) = ( (e0 - b0) * cos (2.d0 * theta) + a0 * sin (2.d0 * &
             theta) + e0 + b0) / 2.d0
        es (2) = ( - (e0 - b0) * cos (2.d0 * theta) - a0 * sin (2.d0 * &
             theta) + e0 + b0) / 2.d0
        !
        ! there are two possible solutions, choose the minimum
        !
        if (es (2) .lt.es (1) ) theta = theta + pi / 2.d0
        !
        ! new estimate of the eigenvalue
        !
        e (m) = min (es (1), es (2) )
        !
        ! upgrade |psi> ...
        !
        IF (npol == 1) THEN
           call DSCAL (2 * n, cos (theta), psi (1, m), 1)

           call DAXPY (2 * n, sin (theta) / cg0, cg, 1, psi (1, m), 1)
           !
           ! here one could test convergence on the energy
           !
           if (abs (e (m) - e0) .lt.eps) goto 10
           !
           ! .... S|psi>....
           !
           call DSCAL (2 * n, cos (theta), spsi, 1)
           call DAXPY (2 * n, sin (theta) / cg0, scg, 1, spsi, 1)
           !
           ! ...and H|psi>
           !
           call DSCAL (2 * n, cos (theta), hpsi, 1)

           call DAXPY (2 * n, sin (theta) / cg0, ppsi, 1, hpsi, 1)
        ELSE
           call DSCAL (2 * nmax * npol, cos (theta), psi (1, m), 1)

           call DAXPY (2 * nmax * npol, sin (theta) / cg0, cg, 1, psi (1, m), 1)
           !
           ! here one could test convergence on the energy
           !
           if (abs (e (m) - e0) .lt.eps) goto 10
           !
           ! .... S|psi>....
           !
           call DSCAL (2 * nmax * npol, cos (theta), spsi, 1)
           call DAXPY (2 * nmax * npol, sin (theta) / cg0, scg, 1, spsi, 1)
           !
           ! ...and H|psi>
           !
           call DSCAL (2 * nmax * npol, cos (theta), hpsi, 1)

           call DAXPY (2 * nmax * npol, sin (theta) / cg0, ppsi, 1, hpsi, 1)
        ENDIF
     enddo
#ifdef DEBUG
     WRITE( stdout , '("   WARNING: e(",i3,") =",f10.5, &
          &    "eV, is not converged to within ",1pe8.1)') m,e(m)*13.6058,eps
#endif
     notconv = notconv + 1
10   avg_iter = avg_iter + iter + 1
     ! reorder eigenvalues if they are not in the right order
     ! (this CAN and WILL happen in not-so-special cases)
     if (m.gt.1.and.reorder) then
        if (e (m) - e (m - 1) .lt. - 2.d0 * eps) then
           ! if the last calculated eigenvalue is not the largest...
           do i = m - 2, 1, - 1
              if (e (m) - e (i) .gt.2.d0 * eps) goto 20
           enddo
20         i = i + 1
           moved = moved+1
           ! last calculated eigenvalue should be in the i-th position: reorder
           e0 = e (m)
           IF (npol == 1) THEN
              call ZCOPY (n, psi (1, m), 1, ppsi, 1)
           ELSE
              call ZCOPY (nmax*npol, psi (1, m), 1, ppsi, 1)
           ENDIF
           do j = m, i + 1, - 1
              e (j) = e (j - 1)
              IF (npol == 1) THEN
                 call ZCOPY (n, psi (1, j - 1), 1, psi (1, j), 1)
              ELSE
                 call ZCOPY (nmax*npol, psi (1, j - 1), 1, psi (1, j), 1)
              ENDIF
           enddo
           e (i) = e0
           IF (npol == 1) THEN
              call ZCOPY (n, ppsi, 1, psi (1, i), 1)
           ELSE
              call ZCOPY (nmax*npol, ppsi, 1, psi (1, i), 1)
           ENDIF
           ! this procedure should be good if only a few inversions occur,
           ! extremely inefficient if eigenvectors are often in bad order
           ! (but this should not happen)
        endif
     endif
  enddo

  avg_iter = avg_iter / nbnd
  deallocate (lagrange)
  deallocate (ppsi)
  deallocate (g0)
  deallocate (cg)
  deallocate (g)
  deallocate (hpsi)
  deallocate (scg)
  deallocate (spsi)
  call stop_clock ('ccgdiagg')
#ifdef DEBUG
  if (notconv.ne.0) print &
      '(" warning : ",i3," eigenvectors did not converge", &
        " after ",i2," iterations")', notconv,maxter
  if (moved.ne.0)  print '(" warning : ",i3, &
        " eigenvalues not correctly ordered")', moved
#endif
  return
end subroutine ccgdiagg_nc
