!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!  ----------------------------------------------

#include "f_defs.h"

!=----------------------------------------------------------------------------=!
   MODULE forces
!=----------------------------------------------------------------------------=!

       USE kinds
       USE cp_types
       USE cell_base, ONLY: tpiba2

       IMPLICIT NONE
       SAVE
 
       PRIVATE

! ... i^l imaginary unit to the angular momentum
       COMPLEX(dbl), PARAMETER :: cimgl(0:3) = (/ (1.0d0,0.0d0), &
         (0.0d0,1.0d0), (-1.0d0,0.0d0), (0.0d0,0.0d0) /)
       COMPLEX(dbl), PARAMETER :: czero = (0.0_dbl,0.0_dbl)
       REAL(dbl),    PARAMETER :: rzero =  0.0_dbl

       INTERFACE dforce
         MODULE PROCEDURE dforce_p, dforce_d, dforce_kp, dforce_all
       END INTERFACE

       PUBLIC :: dforce, dforce_all

!=----------------------------------------------------------------------------=!
   CONTAINS
!=----------------------------------------------------------------------------=!



    SUBROUTINE dforce1(co, ce, dco, dce, fio, fie, hg, v, psi_stored)

      USE fft, ONLY: pw_invfft, pw_fwfft

      IMPLICIT NONE

      ! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(OUT) :: dco(:), dce(:)
      COMPLEX(dbl), INTENT(IN) ::  co(:), ce(:)
      REAL(dbl),    INTENT(IN) ::  fio, fie
      REAL(dbl),    INTENT(IN) ::  v(:,:,:)
      REAL(dbl),    INTENT(IN) :: hg(:)
      COMPLEX(dbl), OPTIONAL ::  psi_stored(:,:,:)

      ! ... declare other variables
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
    END SUBROUTINE


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
      USE pseudopotential, ONLY: l2ind, lm1x, nspnl, tl

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
      REAL(dbl),    ALLOCATABLE :: gwork(:)
      REAL(dbl) :: t1
      INTEGER   :: igh, ll, is, isa, ig, l, m, ngw, nngw

!  end of declarations
!  ----------------------------------------------

      ngw  = SIZE(df)
      nngw = 2*ngw
      ALLOCATE(temp(ngw,2), gwork(ngw))

      igh = 0
      DO l = 0, lm1x
        IF(tl(l)) THEN
          DO m = -l, l
            igh = igh + 1
            isa = 1
            CALL spharm(gwork, gx(:,:), hg(:), ngw, L, M)
            DO is = 1, nspnl
              ll  = l2ind(l + 1,is)
              IF(ll.GT.0) THEN
                t1= - fio * wsg(igh,is)
                CALL DGEMV('N', nngw, na(is), t1, eigr(1,isa), &
                  2*SIZE(eigr,1), fnlo(isa,igh), 1, rzero, temp(1,1), 1)
                t1= - fie * wsg(igh,is)
                CALL DGEMV('N', nngw, na(is), t1, eigr(1,isa), &
                  2*SIZE(eigr,1), fnle(isa,igh), 1, rzero, temp(1,2), 1)
                CALL ZSCAL( nngw, cimgl(l), temp, 1)
                DO ig=1,ngw
                  df(ig) = df(ig) + temp(ig,1) * wnl(ig,ll,is) * gwork(ig)
                END DO
                DO ig=1,ngw
                  da(ig) = da(ig) + temp(ig,2) * wnl(ig,ll,is) * gwork(ig)
                END DO
              END IF
              isa=isa+na(is)
            END DO
          END DO
        END IF
      END DO

      DEALLOCATE(temp, gwork)

    RETURN
    END SUBROUTINE


!=----------------------------------------------------------------------------=!

     
      subroutine dforce_p( ik, ib, c, cdesc, f, df, da, v, fnl, eigr, ps )
        USE wave_types, ONLY: wave_descriptor
        USE turbo, ONLY: tturbo, nturbo, turbo_states
        USE reciprocal_vectors, ONLY: ggp, g, gx
        USE control_flags, ONLY: gamma_only
        implicit none
        integer ik,ib
        COMPLEX(dbl), INTENT(IN) :: c(:,:,:)
        type (wave_descriptor), INTENT(IN) :: cdesc
        COMPLEX(dbl) :: df(:), da(:)
        REAL (dbl)     :: v(:,:,:), f(:,:)
        REAL (dbl)     :: fnl(:,:,:)
        type (pseudo)  :: ps
        COMPLEX(dbl) :: eigr ( :, : )
        !
        INTEGER :: istate
        !
        IF( .NOT. gamma_only ) &
          CALL errore( ' dforce_p ', ' this sub. works for gamma point only ', 1 )
        !
        istate = (ib+1)/2
        !
        IF( tturbo .AND. ( istate <= nturbo ) ) THEN
            CALL dforce1(c(:,ib,ik), c(:,ib+1,ik), df, da, &
              f(ib,ik), f(ib+1,ik), ggp, v, turbo_states(:,:,:,istate))
        ELSE
            CALL dforce1(c(:,ib,ik), c(:,ib+1,ik), df, da, f(ib,ik), f(ib+1,ik), ggp, v)
        END IF
        !
        CALL dforce2(f(ib,ik), f(ib+1,ik), df, da, fnl(:,:,ib), &
            fnl(:,:,ib+1), g, gx, eigr, ps%wsg, ps%wnl(:,:,:,ik)) 
        !
        return
      end subroutine


!-----------------------------------------------------------------------------!


      subroutine dforce_p_s(ib, c, cdesc, f, df, da, v, fnl, eigr, wsg, wnl)
        USE wave_types, ONLY: wave_descriptor
        USE turbo, ONLY: tturbo, nturbo, turbo_states
        USE reciprocal_vectors, ONLY: ggp, g, gx
        USE control_flags, ONLY: gamma_only
        IMPLICIT NONE
        INTEGER, INTENT(IN) :: ib
        COMPLEX(dbl), INTENT(IN) :: c(:,:)
        type (wave_descriptor), INTENT(IN) :: cdesc
        COMPLEX(dbl), INTENT(OUT) :: df(:), da(:)
        REAL (dbl), INTENT(IN) :: v(:,:,:), fnl(:,:,:), wnl(:,:,:), wsg(:,:), f(:)
        COMPLEX(dbl), INTENT(IN)  :: eigr(:,:)
        INTEGER :: istate
        !
        IF( .NOT. gamma_only ) &
          CALL errore( ' dforce_p_s ', ' this sub. works for gamma point only ', 1 )
        !
        istate = (ib+1)/2
        !
        IF( tturbo .AND. ( istate <= nturbo ) ) THEN
          CALL dforce1(c(:,ib), c(:,ib+1), df, da, &
              f(ib), f(ib+1), ggp, v, turbo_states(:,:,:,istate))
        ELSE
          CALL dforce1(c(:,ib), c(:,ib+1), df, da, f(ib), f(ib+1), ggp, v)
        END IF
        !
        CALL dforce2(f(ib), f(ib+1), df, da, fnl(:,:,ib), &
            fnl(:,:,ib+1), g(:), gx(:,:), eigr, wsg, wnl)
        !
        return
      end subroutine


!  ----------------------------------------------


    SUBROUTINE dforce1_d(co, dco, fi, hg, v)


      USE fft, ONLY: pw_invfft, pw_fwfft

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(OUT) :: dco(:)
      COMPLEX(dbl), INTENT(IN)  :: co(:)
      REAL(dbl),    INTENT(IN) :: fi
      REAL(dbl),    INTENT(IN) :: v(:,:,:)
      REAL(dbl),    INTENT(IN) :: hg(:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: psi2(:,:,:)
      COMPLEX(dbl), ALLOCATABLE :: dce(:), ce(:)
      COMPLEX(dbl) :: fp, fm
      REAL(dbl)    :: fiby2, arg
      INTEGER      :: ig
      INTEGER      :: ngw
      !
      ngw = SIZE(co)

      ALLOCATE( psi2(SIZE(v,1), SIZE(v,2), SIZE(v,3)) )
      ALLOCATE( ce(SIZE(co)), dce(SIZE(co)) )
      ce = 0.0d0
      CALL pw_invfft(psi2, co, ce)
      psi2 = psi2 * CMPLX(v, 0.0d0)
      CALL pw_fwfft(psi2, dco, dce)

      fiby2   = fi*0.5
      DO ig=1,ngw
        fp = dco(ig) + dce(ig)
        fm = dco(ig) - dce(ig)
        arg = tpiba2 * hg(ig)
        dco(ig) = -fiby2 * (arg * co(ig) + CMPLX(REAL(fp), AIMAG(fm)))
      END DO
      DEALLOCATE( ce, dce, psi2 )
      !
    RETURN
    END SUBROUTINE

!  ----------------------------------------------


    SUBROUTINE dforce2_d(fi, df, fnl, hg, gx, eigr, wsg, wnl)

      !  this routine computes:
      !  the generalized force df=cmplx(dfr,dfi) acting on the i-th
      !  electron state at the ik-th point of the Brillouin zone
      !  represented by the vector c=cmplx(cr,ci)

! ... declare modules
      USE spherical_harmonics
      USE ions_base, ONLY: na
      USE pseudopotential, ONLY: l2ind, lm1x, nspnl, tl

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl), INTENT(IN) :: wnl(:,:,:)
      COMPLEX(dbl), INTENT(IN) :: eigr(:,:)
      REAL(dbl), INTENT(IN) :: fi, fnl(:,:),wsg(:,:)
      COMPLEX(dbl)  :: df(:)
      REAL(dbl), INTENT(IN) :: hg(:)
      REAL(dbl), INTENT(IN) :: gx(:,:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: temp(:)
      REAL(dbl),    ALLOCATABLE :: gwork(:)
      REAL(dbl) ::  t1
      INTEGER   ::  igh, ll, is, isa, ig, l, m
      INTEGER :: ngw, nngw

!  end of declarations

      ngw = SIZE(df)
      nngw = 2*ngw
      ALLOCATE( temp(ngw), gwork(ngw) )

      igh = 0
      DO l = 0, lm1x
        IF(tl(l)) THEN
          DO m = -l, l
            igh = igh + 1
            isa = 1
            CALL spharm(gwork, gx(:,:), hg(:), ngw, L, M)
            DO is = 1, nspnl
              ll  = l2ind(l + 1,is)
              IF(ll.GT.0) THEN
                t1= - fi * wsg(igh,is)
                CALL DGEMV('N', nngw, na(is), t1, eigr(1,isa), &
                  2*SIZE(eigr,1), fnl(isa,igh), 1, rzero, temp(1), 1)
                CALL ZSCAL(ngw, cimgl(l), temp(1), 1)
                DO ig = 1, ngw
                  df(ig) = df(ig) + temp(ig) * wnl(ig,ll,is) * gwork(ig)
                END DO
              END IF
              isa = isa + na(is)
            END DO
          END DO
        END IF
      END DO

      DEALLOCATE(temp, gwork)

    RETURN
    END SUBROUTINE


!=----------------------------------------------------------------------------=!

     
    SUBROUTINE dforce_d(ik, ib, c, cdesc, f, df, v, fnl, eigr, ps)
        USE wave_types, ONLY: wave_descriptor
        USE reciprocal_vectors, ONLY: ggp, g, gx
        USE control_flags, ONLY: gamma_only
        IMPLICIT NONE
        integer ik, ib
        COMPLEX(dbl), INTENT(IN) :: c(:,:,:)
        type (wave_descriptor), INTENT(IN) :: cdesc
        COMPLEX(dbl) :: df(:)
        REAL (dbl)     :: v(:,:,:), f(:,:)
        REAL (dbl)     :: fnl(:,:,:)
        type (pseudo)  :: ps
        COMPLEX(dbl) :: eigr (:,:)
        !
        IF( .NOT. gamma_only ) &
          CALL errore( ' dforce_p ', ' this sub. works for gamma point only ', 1 )
        !
        CALL dforce1_d(c(:,ib,ik), df, f(ib,ik), ggp, v)
        !
        CALL dforce2_d(f(ib,ik), df, fnl(:,:,ib), g, gx, eigr, ps%wsg, ps%wnl(:,:,:,ik))
        !
        return
    end subroutine

!=----------------------------------------------------------------------------=!

    subroutine dforce_d_s(ib, c, cdesc, f, df, v, fnl, eigr, wsg, wnl)
      USE wave_types, ONLY: wave_descriptor
      USE turbo, ONLY: tturbo, nturbo, turbo_states
      USE reciprocal_vectors, ONLY: ggp, g, gx
      USE control_flags, ONLY: gamma_only
      IMPLICIT NONE
      INTEGER, INTENT(IN) :: ib
      COMPLEX(dbl), INTENT(IN) :: c(:,:)
      type (wave_descriptor), INTENT(IN) :: cdesc
      COMPLEX(dbl), INTENT(OUT) :: df(:)
      REAL (dbl), INTENT(IN) :: v(:,:,:), fnl(:,:,:), wnl(:,:,:), wsg(:,:), f(:)
      COMPLEX(dbl) :: eigr (:,:)
        !
        IF( .NOT. gamma_only ) &
          CALL errore( ' dforce_d_s ', ' this sub. works for gamma point only ', 1 )
        !
        CALL dforce1_d(c(:,ib), df, f(ib), ggp, v)
        !
        CALL dforce2_d(f(ib), df, fnl(:,:,ib), g, gx, eigr, wsg, wnl)
        !
      return
    end subroutine


!  ----------------------------------------------


    SUBROUTINE dforce_kp( ik, ib, c0, cdesc, f, df, v, fnlk, eigr, ps )

        USE wave_types, ONLY: wave_descriptor
        USE reciprocal_space_mesh, ONLY: gkmask_l
        USE reciprocal_space_mesh, ONLY: gkcutz_l, gkx_l, gk_l
        USE control_flags, ONLY: gamma_only

        IMPLICIT NONE

        INTEGER, INTENT(IN) :: ib, ik
        COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:)
        type (wave_descriptor), INTENT(IN) :: cdesc
        COMPLEX(dbl)        :: df(:)
        REAL (dbl)          :: v(:,:,:), f(:,:)
        COMPLEX(dbl)        :: fnlk(:,:,:)
        COMPLEX(dbl)        :: eigr(:,:)
        TYPE (pseudo)       :: ps

        IF( gamma_only ) &
          CALL errore( ' dforce_kp ', ' this sub. does not work for gamma point ', 1 )

        CALL dforce1_kp( c0(:,ib,ik), df, f(ib,ik),  gkcutz_l(:,ik), v)
        CALL dforce2_kp( f(ib,ik), df, fnlk(:,:,ib), gk_l(:,ik), &
          gkx_l(:,:,ik), eigr, ps%wsg, ps%wnl(:,:,:,ik) )

        df(:)       = df(:)       * gkmask_l(:,ik)

      RETURN
    END SUBROUTINE dforce_kp                                                           


!  ----------------------------------------------


    SUBROUTINE dforce1_kp(c, df, fi, hg, v)


      USE fft, ONLY: pw_invfft, pw_fwfft

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(OUT) :: df(:)
      COMPLEX(dbl), INTENT(IN) ::  c(:)
      REAL(dbl),     INTENT(IN) ::  fi
      REAL(dbl),     INTENT(IN) ::  v(:,:,:)
      REAL(dbl),     INTENT(IN) ::  hg(:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: psi2(:,:,:)
      REAL(dbl)      fiby2, arg
      INTEGER     ig
      COMPLEX(dbl)  fp

      ALLOCATE( psi2(SIZE(v,1), SIZE(v,2), SIZE(v,3)) )

! ... Brings wave functions in the real space
      CALL pw_invfft(psi2, c)

! ... Psi * V  ( DEh + DExc + DEps ) 
      psi2 = psi2 * CMPLX(v, 0.0d0)
      CALL pw_fwfft(psi2, df)
      DEALLOCATE(psi2)

      arg = tpiba2 * 0.5d0
      DO ig = 1, SIZE(df)
        df(ig)= - fi * (df(ig) + arg * hg(ig) * c(ig))
      END DO
    RETURN
    END SUBROUTINE


!  ----------------------------------------------


    SUBROUTINE dforce2_kp(fi, df, fnlk, hg, gx, eigr, wsg, wnl)

      !  this routine computes:
      !  the generalized force df=cmplx(dfr,dfi) acting on the i-th
      !  electron state at the ik-th point of the Brillouin zone
      !  represented by the vector c=cmplx(cr,ci)

! ... declare modules
      USE spherical_harmonics
      USE ions_base, ONLY: na
      USE pseudopotential, ONLY: l2ind, lm1x, nspnl, tl

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl) :: gx(:,:), hg(:)
      REAL(dbl), INTENT(IN) :: wnl(:,:,:)
      COMPLEX(dbl), INTENT(IN) :: eigr(:,:)
      COMPLEX(dbl), INTENT(IN) :: fnlk(:,:)
      REAL(dbl), INTENT(IN) :: fi, wsg(:,:)
      COMPLEX(dbl)  df(:)

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: temp(:)
      REAL(dbl),    ALLOCATABLE :: gwork(:)
      COMPLEX(dbl)  fw
      INTEGER   ::  igh, ll, is, isa, ig, l, m, ngw

!  end of declarations

      ngw = SIZE(df)
      ALLOCATE( temp(SIZE(df)), gwork(SIZE(df)) )
      igh = 0
      DO l = 0, lm1x
        IF(tl(l)) THEN
          DO m = -l, l
            igh = igh + 1
            isa = 1
            CALL spharm(gwork, gx(:,:), hg(:), ngw, L, M)
            DO is = 1, nspnl
              ll  = l2ind(l + 1,is)
              IF(ll.GT.0) THEN
! ...           TEMP(IG) = EIGR(IG,:) * FNLK(:,IGH) 
                fw = CMPLX( -fi * wsg(igh,is), 0.0d0)
                CALL ZGEMV('N', ngw, na(is), fw, eigr(1,isa), &
                  size(eigr,1), fnlk(isa,igh), 1, czero, temp(1), 1)
                CALL ZSCAL(ngw,cimgl(l),temp(1),1)
                DO ig = 1, SIZE(df)
                  df(ig) = df(ig) + temp(ig) * wnl(ig,ll,is) * gwork(ig)
                END DO
              END IF
              isa = isa + na(is)
            END DO
          END DO
        END IF
      END DO
      DEALLOCATE(temp, gwork)
    RETURN
    END SUBROUTINE


!  ----------------------------------------------


      SUBROUTINE dforce_all( ispin, c, cdesc, f, cgrad, vpot, fnl, eigr, ps, ik)
        USE wave_types, ONLY: wave_descriptor
        USE pseudo_projector, ONLY: projector
        IMPLICIT NONE

        INTEGER, INTENT(IN) :: ispin
        COMPLEX(dbl), INTENT(INOUT) :: c(:,:,:)
        type (wave_descriptor), INTENT(IN) :: cdesc
        TYPE (pseudo), INTENT(IN) :: ps
        COMPLEX(dbl) ::  eigr(:,:)
        TYPE (projector) :: fnl(:)
        REAL(dbl), INTENT(IN) :: vpot(:,:,:), f(:,:)
        COMPLEX(dbl), INTENT(OUT) :: cgrad(:,:,:)
        INTEGER, INTENT(IN), OPTIONAL :: ik
       
        INTEGER :: ikk, ib, iks, ike, nb

        
        iks = 1
        ike = cdesc%nkl
        IF( PRESENT( ik ) ) THEN
          iks = ik
          ike = ik
        END IF

        DO ikk = iks, ike
          nb  = cdesc%nbl( ispin )
          IF( nb < 1 ) THEN
            cgrad = 0.0d0
          ELSE
            IF( .NOT. cdesc%gamma ) THEN
              DO ib = 1, nb
                CALL dforce(ikk, ib, c, cdesc, f, cgrad(:,ib,ikk), vpot(:,:,:), fnl(ikk)%c, eigr, ps)
              END DO
            ELSE
! ...         Process two states at the same time
              DO ib = 1, ( nb - MOD(nb,2) ), 2
                CALL dforce(ikk, ib, c, cdesc, f, cgrad(:,ib,ikk), cgrad(:,ib+1,1), &
                  vpot(:,:,:), fnl(ikk)%r, eigr, ps)
              END DO
! ...         Account for an odd number of states
              ib = nb
              IF( MOD(ib,2) .GT. 0 ) THEN
                CALL dforce(ikk, ib, c, cdesc, f, cgrad(:,ib,ikk), vpot(:,:,:), fnl(ikk)%r, eigr, ps)
              END IF
            END IF
          END IF
        END DO
        RETURN
      END SUBROUTINE



     END MODULE forces
