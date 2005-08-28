!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
#if defined (__AIX) || defined (__FFTW) || defined (__SGI)
#  define __FFT_MODULE_DRV
#endif
!
#if defined (__PARA)
!
!----------------------------------------------------------------------------
SUBROUTINE cft3( f, n1, n2, n3, nx1, nx2, nx3, sign )
  !----------------------------------------------------------------------------
  !
  ! ...  sign = +-1 : parallel 3d fft for rho and for the potential
  !
  ! ...  sign = +1  : G-space to R-space, output = \sum_G f(G)exp(+iG*R)
  ! ...               fft along z using pencils (cft_1)
  ! ...               transpose across nodes    (fft_scatter)
  ! ...                  and reorder
  ! ...               fft along y and x         (cft_2)
  !
  ! ...  sign = -1  : R-space to G-space, output = \int_R f(R)exp(-iG*R)/Omega
  ! ...               fft along x and y         (cft_2)
  ! ...               transpose across nodes    (fft_scatter)
  ! ...                  and reorder
  ! ...               fft along z using pencils (cft_1)
  !
#if defined (__FFT_MODULE_DRV)
  USE fft_scalar, ONLY : cft_1z, cft_2xy
#endif
  USE sticks,     ONLY : dfftp
  USE fft_base,   ONLY : fft_scatter
  USE kinds,      ONLY : DP
  USE mp_global,  ONLY : nproc_pool, me_pool
  USE pfft,       ONLY : nct, ncp, ncplane, nxx, npp
  !
  IMPLICIT NONE
  !
  INTEGER,          INTENT(IN)    :: n1, n2, n3, nx1, nx2, nx3, sign
  COMPLEX(DP), INTENT(INOUT) :: f(nxx)
  !
  INTEGER                        :: nxx_save, mc, i, j, ii, iproc, nppx
  INTEGER                        :: me_p
  COMPLEX(DP), ALLOCATABLE  :: aux(:)
  !
  !
  CALL start_clock( 'cft3' )
  !
  ALLOCATE( aux( nxx ) )
  !
  me_p = me_pool + 1
  !
  ! ... the following is needed if the fft is distributed over only one proces
  ! ... for the special case nx3.ne.n3. Not an elegant solution, but simple, f
  ! ... and better than the preceding one that did not work in some cases. Not
  ! ... that fft_scatter does nothing if nproc_pool=1. PG
  !
  IF ( nproc_pool == 1 ) THEN
     !
     nppx = nx3
     !
  ELSE
     !
     nppx = npp(me_p)
     !
  END IF
  !
  IF ( sign == 1 ) THEN
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cft_1z( f, ncp(me_p), n3, nx3, sign, aux )
     !
#else
     !
     CALL cft_1( f, ncp(me_p), n3, nx3, sign, aux )
     !
#endif
     !
     CALL fft_scatter( aux, nx3, nxx, f, ncp, npp, sign )
     !
     f(:) = ( 0.D0, 0.D0 )
     !
     DO i = 1, nct
        !
        mc = dfftp%ismap(i)
        !
        DO j = 1, npp(me_p)
           !
           f(mc+(j-1)*ncplane) = aux(j+(i-1)*nppx)
           !
        END DO
        !
     END DO
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cft_2xy( f, npp(me_p), n1, n2, nx1, nx2, sign )
     !
#else
     !
     CALL cft_2( f, npp(me_p), n1, n2, nx1, nx2, sign )
     !
#endif
     !
  ELSE IF ( sign == - 1) THEN
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cft_2xy( f, npp(me_p), n1, n2, nx1, nx2, sign )
     !
#else
     !
     CALL cft_2( f, npp(me_p), n1, n2, nx1, nx2, sign )
     !
#endif
     !
     DO i = 1, nct
        !
        mc = dfftp%ismap(i)
        !
        DO j = 1, npp (me_p)
           !
           aux(j+(i-1)*nppx) = f(mc+(j-1)*ncplane)
           !
        END DO
        !
     END DO
     !
     CALL fft_scatter( aux, nx3, nxx, f, ncp, npp, sign )
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cft_1z( aux, ncp(me_p), n3, nx3, sign, f )
     !
#else
     !
     CALL cft_1( aux, ncp(me_p), n3, nx3, sign, f )
     !
#endif
     !
  ELSE
     !
     CALL errore( 'cft3', 'not allowed', ABS( sign ) )
     !
  END IF
  !
  DEALLOCATE( aux )
  !
  CALL stop_clock( 'cft3' )
  !
  RETURN
  !
END SUBROUTINE cft3
!
#else
!
!----------------------------------------------------------------------------
SUBROUTINE cft3( f, n1, n2, n3, nx1, nx2, nx3, sign )
  !----------------------------------------------------------------------------
  !
#if defined( __FFT_MODULE_DRV)
  USE fft_scalar, ONLY : cfft3d
#endif
  USE kinds,      ONLY : DP
  !
  IMPLICIT NONE
  !
  INTEGER,          INTENT(IN)    :: n1, n2, n3, nx1, nx2, nx3, sign
  COMPLEX(DP), INTENT(INOUT) :: f(nx1*nx2*nx3)
  !
  !
  CALL start_clock( 'cft3' )
  !
  ! ... sign = +-1 : complete 3d fft (for rho and for the potential)
  !
  IF ( sign == 1 ) THEN
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cfft3d( f, n1, n2, n3, nx1, nx2, nx3, 1 )
     !
#else
     !
     CALL cft_3( f, n1, n2, n3, nx1, nx2, nx3, 1, 1 )
     !
#endif
     !
  ELSE IF ( sign == - 1 ) THEN
     !
#if defined (__FFT_MODULE_DRV)
     !
     CALL cfft3d( f, n1, n2, n3, nx1, nx2, nx3, -1 )
     !
#else
     !
     CALL cft_3( f, n1, n2, n3, nx1, nx2, nx3, 1, -1 )
     !
#endif
     !
  ELSE
     !
     CALL errore( 'cft3', 'what should i do?', 1 )
     !
  ENDIF
  !
  CALL stop_clock( 'cft3' )
  !
  RETURN
  !
END SUBROUTINE cft3
!
#endif
