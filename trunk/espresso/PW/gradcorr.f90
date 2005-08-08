!
! Copyright (C) 2001-2005 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
SUBROUTINE gradcorr( rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
                     nrxx, nl, ngm, g, alat, omega, nspin, etxc, vtxc, v )
  !----------------------------------------------------------------------------
  !
  USE constants, ONLY : e2
  USE kinds,     ONLY : DP
  USE funct,     ONLY : igcx, igcc

#ifdef EXX
  USE exx,       ONLY: lexx, exxalfa
#endif
  !
  IMPLICIT NONE
  !
  INTEGER,        INTENT(IN)    :: nr1, nr2, nr3, nrx1, nrx2, nrx3, &
                                   nrxx, ngm, nl(ngm), nspin
  REAL (KIND=DP), INTENT(IN)    :: rho_core(nrxx), g(3,ngm), alat, omega
  REAL (KIND=DP), INTENT(OUT)   :: v(nrxx,nspin), vtxc, etxc
  REAL (KIND=DP), INTENT(INOUT) :: rho(nrxx,nspin)
  !
  INTEGER :: k, ipol, is
  !
  REAL (KIND=DP), ALLOCATABLE :: grho(:,:,:), h(:,:,:), dh(:)
  !
  REAL (KIND=DP) :: grho2(2), sx, sc, v1x, v2x, v1c, v2c, &
                    v1xup, v1xdw, v2xup, v2xdw, v1cup, v1cdw , &
                    etxcgc, vtxcgc, segno, arho, fac, zeta, rh, grh2 
  !
  REAL (KIND=DP) :: v2cup, v2cdw,  v2cud, rup, rdw, &
                    grhoup, grhodw, grhoud, grup, grdw

  REAL (KIND=DP), PARAMETER :: epsr = 1.D-6, &
                               epsg = 1.D-10
  !
  !
  IF ( igcx == 0 .AND. igcc == 0 ) RETURN
  !
  etxcgc = 0.D0
  vtxcgc = 0.D0
  !
  ALLOCATE(    h( 3, nrxx, nspin) )
  ALLOCATE( grho( 3, nrxx, nspin) )
  !
  ! ... calculate the gradient of rho + rho_core in real space
  !
  fac = 1.D0 / DBLE( nspin )
  !
  DO is = 1, nspin
     !
     rho(:,is) = fac * rho_core(:) + rho(:,is)
     !
     CALL gradient( nrx1, nrx2, nrx3, nr1, nr2, nr3, nrxx, &
                    rho(1,is), ngm, g, nl, alat, grho(1,1,is) )
     !
  END DO
  !
  IF ( nspin == 1 ) THEN
     !
     ! ... This is the spin-unpolarised case
     !
     DO k = 1, nrxx
        !
        arho = ABS( rho(k,1) )
        !
        IF ( arho > epsr ) THEN
           !
           grho2(1) = grho(1,k,1)**2 + grho(2,k,1)**2 + grho(3,k,1)**2
           !
           IF ( grho2(1) > epsg ) THEN
              !
              segno = SIGN( 1.D0, rho(k,1) )
              !
              CALL gcxc( arho, grho2, sx, sc, v1x, v2x, v1c, v2c )
#if defined (EXX)
              if (lexx) then
                 sx  = (1.d0-exxalfa)*sx
                 v1x = (1.d0-exxalfa)*v1x
                 v2x = (1.d0-exxalfa)*v2x
!                 sc  = (1.d0-exxalfa)*sc
!                 v1c = (1.d0-exxalfa)*v1c
!                 v2c = (1.d0-exxalfa)*v2c
              end if
#endif
              !
              ! ... first term of the gradient correction : D(rho*Exc)/D(rho)
              !
              v(k,1) = v(k,1) + e2 * ( v1x + v1c )
              !
              ! ... h contains :
              !
              ! ...    D(rho*Exc) / D(|grad rho|) * (grad rho) / |grad rho|
              !
              h(:,k,1) = e2 * ( v2x + v2c ) * grho(:,k,1)
              !
              vtxcgc = vtxcgc + e2 * ( v1x + v1c ) * ( rho(k,1) - rho_core(k) )
              etxcgc = etxcgc + e2 * ( sx + sc ) * segno
              !
           END IF
           !
        ELSE
           !
           h(:,k,1) = 0.D0
           !
        END IF
        !
     END DO
     !
  ELSE
     !
     ! ... spin-polarised case
     !
     DO k = 1, nrxx
        !
        rh = rho(k,1) + rho(k,2)
        !
        grho2(:) = grho(1,k,:)**2 + grho(2,k,:)**2 + grho(3,k,:)**2
        !
        CALL gcx_spin( rho(k,1), rho(k,2), grho2(1), &
                       grho2(2), sx, v1xup, v1xdw, v2xup, v2xdw )
#if defined (EXX)
        if (lexx) then
           sx    = (1.d0-exxalfa)*sx
           v1xup = (1.d0-exxalfa)*v1xup
           v1xdw = (1.d0-exxalfa)*v1xdw
           v2xup = (1.d0-exxalfa)*v2xup
           v2xdw = (1.d0-exxalfa)*v2xdw
        end if
#endif
        !
        IF ( rh > epsr ) THEN
           !
           IF ( igcc == 3 ) THEN
              !
              rup = rho(k,1)
              rdw = rho(k,2)
              !
              grhoup = grho(1,k,1)**2 + grho(2,k,1)**2 + grho(3,k,1)**2
              grhodw = grho(1,k,2)**2 + grho(2,k,2)**2 + grho(3,k,2)**2
              !
              grhoud = grho(1,k,1) * grho(1,k,2) + &
                       grho(2,k,1) * grho(2,k,2) + &
                       grho(3,k,1) * grho(3,k,2)
              !
              CALL gcc_spin_more( rup, rdw, grhoup, grhodw, grhoud, &
                                  sc, v1cup, v1cdw, v2cup, v2cdw, v2cud )
              !
           ELSE
              !
              zeta = ( rho(k,1) - rho(k,2) ) / rh
              !
              grh2 = ( grho(1,k,1) + grho(1,k,2) )**2 + &
                     ( grho(2,k,1) + grho(2,k,2) )**2 + &
                     ( grho(3,k,1) + grho(3,k,2) )**2
              !
              CALL gcc_spin( rh, zeta, grh2, sc, v1cup, v1cdw, v2c )
              !
              v2cup = v2c
              v2cdw = v2c
              v2cud = v2c
              !
           END IF
           !
        ELSE
           !
           sc    = 0.D0
           v1cup = 0.D0
           v1cdw = 0.D0
           v2c   = 0.D0
           v2cup = 0.D0
           v2cdw = 0.D0
           v2cud = 0.D0
           !
        ENDIF
#if defined (EXX)
!        if (lexx) then
!           sc    = (1.d0-exxalfa)*sc
!           v1cup = (1.d0-exxalfa)*v1cup
!           v1cdw = (1.d0-exxalfa)*v1cdw
!           v2c   = (1.d0-exxalfa)*v2c
!           v2cup = (1.d0-exxalfa)*v2cup
!           v2cdw = (1.d0-exxalfa)*v2cdw
!           v2cud = (1.d0-exxalfa)*v2cud
!        end if
#endif
        !
        ! ... first term of the gradient correction : D(rho*Exc)/D(rho)
        !
        v(k,1) = v(k,1) + e2 * ( v1xup + v1cup )
        v(k,2) = v(k,2) + e2 * ( v1xdw + v1cdw )
        !
        ! ... h contains D(rho*Exc)/D(|grad rho|) * (grad rho) / |grad rho|
        !
        DO ipol = 1, 3
           !
           grup = grho(ipol,k,1)
           grdw = grho(ipol,k,2)
           h(ipol,k,1) = e2 * ( ( v2xup + v2cup ) * grup + v2cud * grdw )
           h(ipol,k,2) = e2 * ( ( v2xdw + v2cdw ) * grdw + v2cud * grup )
           !
        END DO
        !
        vtxcgc = vtxcgc + &
                 e2 * ( v1xup + v1cup ) * ( rho(k,1) - rho_core(k) * fac )
        vtxcgc = vtxcgc + &
                 e2 * ( v1xdw + v1cdw ) * ( rho(k,2) - rho_core(k) * fac )
        etxcgc = etxcgc + e2 * ( sx + sc )
        !
     END DO
     !
  END IF
  !
  DO is = 1, nspin
     !
     rho(:,is) = rho(:,is) - fac * rho_core(:)
     !
  END DO
  !
  DEALLOCATE( grho )
  !
  ALLOCATE( dh( nrxx ) )    
  !
  ! ... second term of the gradient correction :
  ! ... \sum_alpha (D / D r_alpha) ( D(rho*Exc)/D(grad_alpha rho) )
  !
  DO is = 1, nspin
     !
     CALL grad_dot( nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                    nrxx, h(1,1,is), ngm, g, nl, alat, dh )
     !
     v(:,is) = v(:,is) - dh(:)
     !
     vtxcgc = vtxcgc - SUM( dh(:) * rho(:,is) )
     !
  END DO
  !
  vtxc = vtxc + omega * vtxcgc / ( nr1 * nr2 * nr3 )
  etxc = etxc + omega * etxcgc / ( nr1 * nr2 * nr3 )
  !
  DEALLOCATE( dh )
  DEALLOCATE( h )
  !
  RETURN
  !
END SUBROUTINE gradcorr
!
!----------------------------------------------------------------------------
SUBROUTINE gradient( nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                     nrxx, a, ngm, g, nl, alat, ga )
  !----------------------------------------------------------------------------
  !
  ! ... Calculates ga = \grad a in R-space (a is also in R-space)
  !
  USE constants, ONLY : tpi
  USE cell_base, ONLY : tpiba
  USE kinds,     ONLY : DP
  USE gvect,     ONLY : nlm
  USE wvfct,     ONLY : gamma_only
  !
  IMPLICIT NONE
  !
  INTEGER,        INTENT(IN)     :: nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                                    nrxx, ngm, nl(ngm)
  REAL (KIND=DP), INTENT(IN)     :: a(nrxx), g(3,ngm), alat
  REAL (KIND=DP), INTENT(OUT)    :: ga(3,nrxx)
  !
  INTEGER                        :: n, ipol
  COMPLEX (KIND=DP), ALLOCATABLE :: aux(:), gaux(:)
  !
  !
  ALLOCATE(  aux( nrxx ) )
  ALLOCATE( gaux( nrxx ) )
  !
  aux = DCMPLX( a(:), 0.D0 )
  !
  ! ... bring a(r) to G-space, a(G) ...
  !
  CALL cft3( aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, -1 )
  !
  ! ... multiply by (iG) to get (\grad_ipol a)(G) ...
  !
  ga(:,:) = 0.D0
  !
  DO ipol = 1, 3
     !
     gaux(:) = 0.D0
     !
     gaux(nl(:)) = g(ipol,:) * DCMPLX( - AIMAG( aux(nl(:)) ), &
                                       +  REAL( aux(nl(:)) ) )
     !
     IF ( gamma_only ) THEN
        !
        gaux(nlm(:)) = DCMPLX( +  REAL( gaux(nl(:)) ), &
                               - AIMAG( gaux(nl(:)) ) )
        !
     END IF
     !
     ! ... bring back to R-space, (\grad_ipol a)(r) ...
     !
     CALL cft3( gaux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
     !
     ! ...and add the factor 2\pi/a  missing in the definition of G
     !
     ga(ipol,:) = ga(ipol,:) + tpiba * REAL( gaux(:) )
     !
  END DO
  !
  DEALLOCATE( gaux )
  DEALLOCATE( aux )
  !
  RETURN
  !
END SUBROUTINE gradient
!
!----------------------------------------------------------------------------
SUBROUTINE grad_dot( nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                     nrxx, a, ngm, g, nl, alat, da )
  !----------------------------------------------------------------------------
  !
  ! ... Calculates da = \sum_i \grad_i a_i in R-space
  !
  USE constants, ONLY : tpi
  USE cell_base, ONLY : tpiba
  USE kinds,     ONLY : DP
  USE gvect,     ONLY : nlm
  USE wvfct,     ONLY : gamma_only
  !
  IMPLICIT NONE
  !
  INTEGER,        INTENT(IN)     :: nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                                    nrxx, ngm, nl(ngm)
  REAL (KIND=DP), INTENT(IN)     :: a(3,nrxx), g(3,ngm), alat
  REAL (KIND=DP), INTENT(OUT)    :: da(nrxx)
  !
  INTEGER                        :: n, ipol
  COMPLEX (KIND=DP), ALLOCATABLE :: aux(:), gaux(:)
  !
  !
  ALLOCATE(  aux( nrxx ) )
  ALLOCATE( gaux( nrxx ) )
  !
  gaux(:) = 0.D0
  !
  DO ipol = 1, 3
     !
     aux = DCMPLX( a(ipol,:), 0.D0 )
     !
     ! ... bring a(ipol,r) to G-space, a(G) ...
     !
     CALL cft3( aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, -1 )
     !
     gaux(nl(:)) = gaux(nl(:)) + &
                   g(ipol,:) * DCMPLX( - AIMAG( aux(nl(:)) ), &
                                       +  REAL( aux(nl(:)) ) )
     !
  END DO
  !
  IF ( gamma_only ) THEN
     !
     gaux(nlm(:)) = DCMPLX( +  REAL( gaux(nl(:)) ), &
                            - AIMAG( gaux(nl(:)) ) )
     !
  END IF
  !
  ! ... bring back to R-space, (\grad_ipol a)(r) ...
  !
  CALL cft3( gaux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1 )
  !
  ! ... add the factor 2\pi/a  missing in the definition of G and sum
  !
  da(:) = tpiba * REAL( gaux(:) )
  !
  DEALLOCATE( gaux )
  DEALLOCATE( aux )
  !
  RETURN
  !
END SUBROUTINE grad_dot
