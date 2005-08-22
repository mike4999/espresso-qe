!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"

!=----------------------------------------------------------------------------=!
   MODULE forces
!=----------------------------------------------------------------------------=!

       USE kinds
       USE cell_base, ONLY: tpiba2

       IMPLICIT NONE
       SAVE
 
       PRIVATE

! ... i^l imaginary unit to the angular momentum
       COMPLEX(dbl), PARAMETER :: cimgl(0:3) = (/ (1.0d0,0.0d0), &
         (0.0d0,1.0d0), (-1.0d0,0.0d0), (0.0d0,-1.0d0) /)
       COMPLEX(dbl), PARAMETER :: czero = (0.0_dbl,0.0_dbl)
       REAL(dbl),    PARAMETER :: rzero =  0.0_dbl

       PUBLIC :: dforce, dforce_all

!=----------------------------------------------------------------------------=!
   CONTAINS
!=----------------------------------------------------------------------------=!



    SUBROUTINE dforce1( co, ce, dco, dce, fio, fie, hg, v, psi_stored )

      USE fft, ONLY: pw_invfft, pw_fwfft

      IMPLICIT NONE

      ! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(OUT) :: dco(:), dce(:)
      COMPLEX(dbl), INTENT(IN)  :: co(:), ce(:)
      REAL(dbl),    INTENT(IN)  :: fio, fie
      REAL(dbl),    INTENT(IN)  :: v(:,:,:)
      REAL(dbl),    INTENT(IN)  :: hg(:)
      COMPLEX(dbl), OPTIONAL    :: psi_stored(:,:,:)

      ! ... declare other variables
      !
      COMPLEX(dbl), ALLOCATABLE :: psi(:,:,:)
      COMPLEX(dbl) :: fp, fm, aro, are
      REAL(dbl)    :: fioby2, fieby2, arg
      INTEGER      :: ig

      !  end of declarations

      IF( PRESENT( psi_stored ) ) THEN
        psi_stored = psi_stored * CMPLX(v, 0.0d0)
        CALL pw_fwfft(psi_stored, dco, dce)
      ELSE
        ALLOCATE( psi(SIZE(v,1), SIZE(v,2), SIZE(v,3)) )
        CALL pw_invfft(psi, co, ce)
        psi = psi * CMPLX(v, 0.0d0)
        CALL pw_fwfft(psi, dco, dce)
        DEALLOCATE(psi)
      END IF

      fioby2   = fio * 0.5
      fieby2   = fie * 0.5

      DO ig = 1, SIZE(co)
        fp = dco(ig) + dce(ig)
        fm = dco(ig) - dce(ig)
        aro = CMPLX( REAL(fp), AIMAG(fm) )
        are = CMPLX( AIMAG(fp),-REAL(fm))
        arg = tpiba2 * hg(ig)
        dco(ig) = -fioby2 * (arg * co(ig) + aro)
        dce(ig) = -fieby2 * (arg * ce(ig) + are)
      END DO

    RETURN
    END SUBROUTINE dforce1


!  ----------------------------------------------


    SUBROUTINE dforce2(fio, fie, df, da, fnlo, fnle, hg, gx, eigr, wsg, wnl)

        !  this routine computes:
        !  the generalized force df=cmplx(dfr,dfi) acting on the i-th
        !  electron state at the ik-th point of the Brillouin zone
        !  represented by the vector c=cmplx(cr,ci)
        !  ----------------------------------------------

! ... declare modules
      USE spherical_harmonics
      USE ions_base, ONLY: na
      USE pseudopotential, ONLY: nspnl
      USE uspp_param, only: nh, lmaxkb
      USE uspp, only: nhtol, nhtolm, indv, dvan, beta
      use cvan, only: ish


      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl), INTENT(IN) :: wnl(:,:,:)
      COMPLEX(dbl), INTENT(IN) :: eigr(:,:)
      REAL(dbl), INTENT(IN) :: fio, fie, fnlo(:,:), fnle(:,:), wsg(:,:)
      COMPLEX(dbl)  :: df(:), da(:)
      REAL(dbl), INTENT(IN) :: hg(:)
      REAL(dbl), INTENT(IN) :: gx(:,:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: temp(:,:)
      REAL(dbl),    ALLOCATABLE :: gwork(:,:)
      REAL(dbl) :: t1, fac
      INTEGER   :: igh, ll, is, isa, ig, l, m, ngw, nngw, iy, ih, iv
      INTEGER   :: inl

!  end of declarations
!  ----------------------------------------------

      ngw  = SIZE(df)
      nngw = 2*ngw
      ALLOCATE(temp(ngw,2), gwork(ngw,(lmaxkb+1)**2))

      CALL ylmr2( (lmaxkb+1)**2, ngw, gx, hg, gwork )

      isa = 1
      DO is = 1, nspnl
        DO ih = 1, nh( is )
          !
          iv  = indv  ( ih, is )
          iy  = nhtolm( ih, is )
          ll  = nhtol ( ih, is ) + 1
          l   = ll - 1
          igh = ih
          inl = ish(is)+(ih-1)*na(is)+1

          ! WRITE(6,*) 'is, ih, inl, l = ', is, ih, inl, l
!
          ! fac = wsg(ih,is) / dvan( ih, ih, is)
          ! WRITE(6,*) 'wsg = ', fac
          ! WRITE(6,*) 'fnl = ', sqrt( fac ) * fnlo(isa,igh) / bec( inl, ib_bec )

          t1= - fio * wsg(igh,is)
          CALL DGEMV('N', nngw, na(is), t1, eigr(1,isa), &
               2*SIZE(eigr,1), fnlo(isa,igh), 1, rzero, temp(1,1), 1)
          t1= - fie * wsg(igh,is)
          CALL DGEMV('N', nngw, na(is), t1, eigr(1,isa), &
               2*SIZE(eigr,1), fnle(isa,igh), 1, rzero, temp(1,2), 1)
          CALL ZSCAL( nngw, cimgl(l), temp, 1)
          DO ig=1,ngw
             df(ig) = df(ig) + temp(ig,1) * wnl(ig,iv,is) * gwork(ig,iy)
          END DO
          DO ig=1,ngw
             da(ig) = da(ig) + temp(ig,2) * wnl(ig,iv,is) * gwork(ig,iy)
          END DO
        END DO
        isa=isa+na(is)
      END DO

      DEALLOCATE(temp, gwork)

    RETURN
    END SUBROUTINE dforce2



    SUBROUTINE dforce2_bec( fio, fie, df, da, eigr, beco, bece )

        !  this routine computes:
        !  the generalized force df=cmplx(dfr,dfi) acting on the i-th
        !  electron state at the ik-th point of the Brillouin zone
        !  represented by the vector c=cmplx(cr,ci)
        !  ----------------------------------------------

      USE ions_base,       ONLY: na
      USE pseudopotential, ONLY: nspnl
      USE electrons_base,  ONLY: iupdwn
      USE uspp_param,      only: nh
      USE uspp,            only: nhtol, nhtolm, indv, beta, dvan
      use cvan,            only: ish


      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(IN) :: eigr(:,:)
      REAL(dbl), INTENT(IN) :: fio, fie
      COMPLEX(dbl)  :: df(:), da(:)
      REAL(dbl), INTENT(IN) :: beco(:)
      REAL(dbl), INTENT(IN) :: bece(:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: temp(:,:)
      REAL(dbl) :: t1
      REAL(dbl) :: sgn
      INTEGER   :: l, is, ig, ngw, iv, inl, isa

!  end of declarations
!  ----------------------------------------------

      ngw  = SIZE(df)
      ALLOCATE(temp(ngw,2))

      isa = 1
      
      DO is = 1, nspnl
        !
        DO iv = 1, nh( is )
          !
          l   = nhtol ( iv, is )
          inl = ish(is) + (iv-1) * na(is) + 1

          sgn = 1.0d0
          IF( MOD( l, 2 ) /= 0 ) sgn = -1.0d0   !  ( -1)^l
          
          t1= - fio * dvan( iv, iv, is ) * sgn
          !
          CALL DGEMV('N', 2*ngw, na(is), t1, eigr(1,isa), &
               2*SIZE(eigr,1), beco( inl ), 1, rzero, temp(1,1), 1)
          !
          CALL ZSCAL( ngw, cimgl(l), temp(1,1), 1)
          !
          t1= - fie * dvan( iv, iv, is ) * sgn
          CALL DGEMV('N', 2*ngw, na(is), t1, eigr(1,isa), &
               2*SIZE(eigr,1), bece( inl ), 1, rzero, temp(1,2), 1)
          !
          CALL ZSCAL( ngw, cimgl(l), temp(1,2), 1)
          !
          DO ig=1,ngw
             df(ig) = df(ig) + temp(ig,1) * beta(ig,iv,is)
          END DO
          DO ig=1,ngw
             da(ig) = da(ig) + temp(ig,2) * beta(ig,iv,is)
          END DO
        END DO
        !
        isa = isa + na( is )
        !
      END DO

      DEALLOCATE(temp)

    RETURN
    END SUBROUTINE dforce2_bec



!=----------------------------------------------------------------------------=!

     

    SUBROUTINE dforce( ib, iss, c, cdesc, f, df, da, v, eigr, bec )
       !
       USE wave_types, ONLY: wave_descriptor
       USE turbo, ONLY: tturbo, nturbo, turbo_states
       USE reciprocal_vectors, ONLY: ggp, g, gx
       USE electrons_base, ONLY: nupdwn, iupdwn
       !
       IMPLICIT NONE
       !
       INTEGER,      INTENT(IN)  :: ib, iss     ! band and spin index
       COMPLEX(dbl), INTENT(IN)  :: c(:,:)
       COMPLEX(dbl), INTENT(OUT) :: df(:), da(:)
       REAL (dbl),   INTENT(IN)  :: v(:,:,:), bec(:,:), f(:)
       COMPLEX(dbl), INTENT(IN)  :: eigr(:,:)
       type (wave_descriptor), INTENT(IN) :: cdesc
       !
       COMPLEX(dbl), ALLOCATABLE :: dum( : )   
       ! COMPLEX(dbl) :: df_( SIZE( df ) ) , da_( SIZE( da ) )   ! DEBUG
       !
       INTEGER :: ig, in
       !
       IF( ib > nupdwn( iss ) ) CALL errore( ' dforce ', ' ib out of range ', 1 )
       !
       in = iupdwn( iss ) + ib - 1 
       !
       IF( ib == nupdwn( iss ) ) THEN
          !
          ALLOCATE( dum( SIZE( da ) ) )
          !
          CALL dforce1( c(:,ib), c(:,ib), df, dum, f(ib), f(ib), ggp, v )
          !
          CALL dforce2_bec( f(ib), f(ib), df , dum , eigr, bec( :, in ), bec( :, in ) )
          !
          ! CALL dforce2( f(ib), f(ib), df, dum, fnl(:,:,ib), &
          !    fnl(:,:,ib), g(:), gx(:,:), eigr, wsg, wnl )
          !
          DEALLOCATE( dum )
          !
       ELSE
          !
          CALL dforce1( c(:,ib), c(:,ib+1), df, da, f(ib), f(ib+1), ggp, v )
          !
          CALL dforce2_bec( f(ib), f(ib+1), df, da, eigr, bec( :, in ), bec( :, in+1 ) )
          !
          ! CALL dforce2( f(ib), f(ib+1), df, da, fnl(:,:,ib), &
          !    fnl(:,:,ib+1), g(:), gx(:,:), eigr, wsg, wnl )
          !
          ! DO ig = 1, SIZE( df ), 50
          !    WRITE(6,*) ig, df(ig), df_(ig)
          !    WRITE(6,*) ig, da(ig), da_(ig)
          ! END DO
          !
       END IF
       !
       return
    END SUBROUTINE dforce


!  ----------------------------------------------


    SUBROUTINE dforce_all( ispin, c, cdesc, f, cgrad, vpot, eigr, bec )
        !
        USE wave_types,       ONLY: wave_descriptor
        USE electrons_base,   ONLY: nupdwn
        !
        IMPLICIT NONE

        INTEGER,                INTENT(IN)    :: ispin
        COMPLEX(dbl),           INTENT(INOUT) :: c(:,:)
        type (wave_descriptor), INTENT(IN)    :: cdesc
        REAL(dbl),              INTENT(IN)    :: vpot(:,:,:), f(:)
        COMPLEX(dbl),           INTENT(OUT)   :: cgrad(:,:)
        COMPLEX(dbl),           INTENT(IN)    :: eigr(:,:)
        REAL(dbl),              INTENT(IN)    :: bec(:,:)
       
        INTEGER :: ib
        !
        IF( nupdwn( ispin ) > 0 ) THEN
           !
           !   Process two states at the same time
           !
           DO ib = 1, nupdwn( ispin ), 2
              CALL dforce( ib, ispin, c, cdesc, f, cgrad(:,ib), cgrad(:,ib+1), &
                  vpot, eigr, bec )
           END DO
           !
        END IF
        !
        RETURN
    END SUBROUTINE dforce_all



 END MODULE forces
