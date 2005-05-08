!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

!  AB INITIO COSTANT PRESSURE MOLECULAR DYNAMICS
!  ----------------------------------------------
!  Car-Parrinello Parallel Program
!  Carlo Cavazzoni - Gerardo Ballabio
!  SISSA, Trieste, Italy - 1997-99
!  Last modified: Wed Apr  5 23:04:18 MDT 2000
!  ----------------------------------------------

#include "f_defs.h"


  MODULE stress

       USE kinds
       USE control_flags, ONLY: timing

       IMPLICIT NONE
       PRIVATE
       SAVE

       PUBLIC :: pstress, print_stress_time

       INTEGER, DIMENSION(6), PARAMETER :: alpha = (/ 1,2,3,2,3,3 /)
       INTEGER, DIMENSION(6), PARAMETER :: beta  = (/ 1,1,1,2,2,3 /)

       REAL(dbl),  DIMENSION(3,3), PARAMETER :: delta = reshape &
         ( (/ 1.0_dbl, 0.0_dbl, 0.0_dbl, &
              0.0_dbl, 1.0_dbl, 0.0_dbl, &
              0.0_dbl, 0.0_dbl, 1.0_dbl  &
            /), (/ 3, 3 /) )

! ...  dalbe(:) = delta(alpha(:),beta(:))
       REAL(dbl),  DIMENSION(6), PARAMETER :: dalbe = &
         (/ 1.0_dbl, 0.0_dbl, 0.0_dbl, 1.0_dbl, 0.0_dbl, 1.0_dbl /)

       REAL(dbl) :: timeek = 0.0d0
       REAL(dbl) :: timeex = 0.0d0
       REAL(dbl) :: timeesr = 0.0d0
       REAL(dbl) :: timeeh = 0.0d0
       REAL(dbl) :: timeel = 0.0d0
       REAL(dbl) :: timeenl = 0.0d0
       REAL(dbl) :: timetot = 0.0d0
       INTEGER   :: timcnt = 0

       REAL(dbl), EXTERNAL  :: cclock

     CONTAINS

!  ----------------------------------------------
!  BEGIN manual

      SUBROUTINE pstress( strvxc, rhoeg, vxc, pail, desr, &
        fnl, ps, c0, cdesc, occ, eigr, sfac, grho, v2xc, box, edft) 

!  this routine computes stress tensor from dft total energy
!  ----------------------------------------------
!  END manual

! ... declare modules
      USE cp_types,             ONLY: pseudo
      USE cell_module,          ONLY: boxdimensions
      USE energies,             ONLY: dft_energy_type
      USE ions_base,            ONLY: nsp
      USE mp_global,            ONLY: mpime, nproc, group
      USE mp,                   ONLY: mp_sum
      USE wave_types,           ONLY: wave_descriptor
      USE pseudo_projector,     ONLY: projector
      USE cell_base,            ONLY: tpiba2
      USE io_global,            ONLY: ionode
      USE exchange_correlation, ONLY: stress_xc
      USE control_flags,        ONLY: iprsta
      USE reciprocal_vectors,   ONLY: gx
      USE gvecp,                ONLY: ngm

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl) :: pail(:,:), desr(:), strvxc
      REAL(dbl) :: grho(:,:,:,:,:), v2xc(:,:,:,:,:)
      COMPLEX(dbl) :: rhoeg(:,:), vxc(:,:)
      COMPLEX(dbl), INTENT(IN) :: sfac(:,:)
      REAL(dbl), INTENT(IN) :: occ(:,:,:)
      TYPE (pseudo), INTENT(IN) :: ps
      COMPLEX(dbl), INTENT(IN) :: c0(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      TYPE (boxdimensions), INTENT(IN) :: box
      COMPLEX(dbl) :: eigr(:,:)
      TYPE (projector) :: fnl(:,:)
      TYPE (dft_energy_type) :: edft

! ... declare other variables
      REAL(dbl) :: s1, s2, s3, s4, s5, s6, s7, s8, s0

      REAL(dbl), DIMENSION (6) :: dekin, deht, deps, denl, dexc, dvdw
      REAL(dbl), DIMENSION (3,3) :: paiu
      REAL(dbl), ALLOCATABLE :: gagx_l(:,:)
      REAL(dbl) :: omega, ehr

      INTEGER k, ig

! ... end of declarations
!  ----------------------------------------------

      IF( .NOT. cdesc%gamma ) &
        CALL errore( ' pstress ', ' k-point stress not yet implemented ', 1 )

      omega = box%deth
      ehr   = edft%eht - edft%esr + edft%eself
      
      IF(timing) s0 = cclock()

! ... compute G_alpha * G_beta

      ALLOCATE(gagx_l(6,ngm))
      DO k = 1, 6
        DO ig = 1, ngm
          gagx_l(k,ig) = gx(alpha(k),ig) * gx(beta(k),ig) * tpiba2
        END DO
      END DO

      IF(timing) s1 = cclock()

! ... compute kinetic energy contribution

      CALL stress_kin(dekin, c0, cdesc, occ, gagx_l)

      IF(timing) s2 = cclock()

! ... compute hartree energy contribution
      CALL stress_har(deht, ehr, sfac, ps, rhoeg, gagx_l, box)

      IF(timing) s3 = cclock()

! ... compute exchange & correlation energy contribution
      CALL stress_xc(dexc, strvxc, sfac, vxc, grho, v2xc, gagx_l, &
        ps%tnlcc, ps%rhocp, box)

      IF(timing) s4 = cclock()

! ... compute esr contribution
!      IF(tvdw) THEN
!        CALL vdw_stress(c6, iesr, stau0, dvdw, na, nax, nsp)
!      END IF

      IF(timing) s5 = cclock()

      CALL pseudo_stress(deps, edft%epseu, gagx_l, sfac, ps%dvps, rhoeg, box)

      IF(timing) s6 = cclock()

! ... compute enl (non-local) contribution
      CALL stress_nl(denl, gagx_l, c0, cdesc, occ, eigr, ps%wsg,fnl, &
        ps%wnl(:,:,:,1), edft%enl)

      IF(timing) s7 = cclock()

      IF( iprsta > 2 ) THEN
      CALL stress_debug(dekin, deht, dexc, desr, deps, denl, box%m1 )
      END IF

! ... total stress (pai-lowercase)
      DO k=1,6
        paiu(alpha(k),beta(k)) = -( dekin(k) + deht(k) + dexc(k) + &
                       desr (k) + deps(k) + denl(k) )
        paiu(beta(k),alpha(k)) = paiu(alpha(k),beta(k))
      END DO

      pail(:,:) = matmul( paiu(:,:), box%m1(:,:) )
    
      CALL mp_sum(pail, group)
  
      DEALLOCATE(gagx_l)

      IF( timing ) THEN
        s8 = cclock()
        timeek  = (s2 - s1) + timeek
        timeeh  = (s3 - s2) + timeeh
        timeex  = (s4 - s3) + timeex
        timeesr = (s5 - s4) + timeesr 
        timeel  = (s6 - s5) + timeel
        timeenl = (s7 - s6) + timeenl
        timetot = (s8 - s0) + timetot
        timcnt = timcnt + 1
      END IF

 50   FORMAT(6X,3(F20.12))
 60   FORMAT(6X,6(F20.12))
100   FORMAT(6X,A3,10X,F8.4)

      RETURN
      END SUBROUTINE


      SUBROUTINE print_stress_time( iunit )
        USE io_global, ONLY: ionode
        IMPLICIT NONE
        INTEGER, INTENT(IN) :: iunit
        IF( timing .AND. timcnt > 0 ) THEN
          timeek  = timeek/timcnt
          timeeh  = timeeh/timcnt
          timeex  = timeex/timcnt
          timeesr = timeesr/timcnt
          timeel  = timeel/timcnt
          timeenl = timeenl/timcnt
          timetot = timetot/timcnt
          IF(ionode) THEN
            WRITE( iunit, 999 ) timeek, timeex, timeesr, timeeh, timeel, timeenl, timetot
          END IF
        END IF
        timeek = 0.0d0 
        timeex = 0.0d0
        timeesr = 0.0d0
        timeeh = 0.0d0 
        timeel = 0.0d0
        timeenl = 0.0d0
        timetot = 0.0d0
        timcnt = 0
999     FORMAT(1X,7(1X,F9.3))

        RETURN
      END SUBROUTINE



!  BEGIN manual

      SUBROUTINE stress_nl(denl, gagx_l, c0, cdesc, occ, eigr, wsg, fnl, wnl, enl)

!  this routine computes nl part of the stress tensor from dft total energy
!  ----------------------------------------------
!  END manual


! ... declare modules
      USE pseudopotential, ONLY: nlin_stress, ngh, &
            l2ind,nspnl,nsanl, lnlx, ts,tp,td, tf, lm1x
      USE ions_base, ONLY: nsp, na
      USE spherical_harmonics, ONLY: set_dmqm, set_fmrm, set_pmtm
      USE mp_global, ONLY: mpime, nproc
      USE wave_types, ONLY: wave_descriptor
      USE pseudo_projector, ONLY: projector
      USE cell_base, ONLY: tpiba2
      USE control_flags, ONLY: force_pairing
      USE reciprocal_vectors, ONLY: gstart, gzero, g, gx

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl), INTENT(IN) :: occ(:,:,:)
      COMPLEX(dbl), INTENT(IN) :: c0(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(OUT) :: denl(:)
      REAL(dbl), INTENT(IN) :: gagx_l(:,:)
      COMPLEX(dbl), INTENT(IN) :: eigr(:,:)
      TYPE (projector), INTENT(IN) :: fnl(:,:)
      REAL(dbl), INTENT(IN) :: wsg(:,:)
      REAL(dbl), INTENT(IN) :: wnl(:,:,:)
      REAL(dbl), INTENT(IN) :: enl

! ... declare functions
      REAL(dbl)  DDOT

! ... declare other variables
      INTEGER :: is, l, ll, me, al, be, s, k
      INTEGER :: ir, kk, m, mm, isa, ighp, ig, iy
      INTEGER :: igh, ia, ighd, ighf, in, i, iss, nx, ispin, nspin, ngw
      INTEGER :: ispin_wfc, im(7)
      REAL(dbl)  xg,xrg,arg,wnd,wnd1,wnd2,temp,tt1,fac,tt2
      REAL(dbl)  temp2, fg, gmod
      REAL(dbl)  pm(3,3), pmtm(6,3,3)
      REAL(dbl)  dm(6,5), dmqm(6,5,5)
      REAL(dbl)  fm(3,3,3,7), fmrm(6,7,7)

      COMPLEX(dbl), ALLOCATABLE :: auxc(:,:)
      REAL(dbl), ALLOCATABLE :: wnla(:,:,:)
      REAL(dbl), ALLOCATABLE :: fnls(:,:)
      REAL(dbl), ALLOCATABLE :: gwork(:)
      REAL(dbl), ALLOCATABLE :: gspha(:,:)
      REAL(dbl), ALLOCATABLE :: gwtmp(:)
      REAL(dbl), PARAMETER :: twothird = 2.0d0/3.0d0
      COMPLEX(dbl), PARAMETER :: uimag = (0.0d0,1.0d0)
! ... i^l
      COMPLEX(dbl), PARAMETER :: csign(0:3) = (/ (1.0d0, 0.0d0), &
          (0.0d0,1.0d0), (-1.0d0,0.0d0), (0.0d0,-1.0d0) /)


!  end of declarations
!  ----------------------------------------------

      me = mpime + 1
      nspin = cdesc%nspin

      IF(gzero) THEN
        denl = - enl * dalbe
      ELSE
        denl = 0.0_dbl
      END IF
  
      ngw = cdesc%ngwl
      
! ... initialize array wnla
      ALLOCATE(wnla(ngw, lnlx, nsp))
      CALL nlin_stress(wnla)

      ALLOCATE(gwork(ngw))
      ALLOCATE(gwtmp(ngw))
      ALLOCATE(gspha(ngw, (lm1x+1)**2 ))

      CALL ylmr2( (lm1x+1)**2, ngw, gx, g, gspha )

      SPIN_LOOP: DO ispin = 1, nspin

        ispin_wfc = ispin
        IF( force_pairing ) ispin_wfc = 1

        nx = cdesc%nbl( ispin )

        IF( nx < 1 ) CYCLE SPIN_LOOP

        ALLOCATE(fnls(nsanl,nx))

        igh = 0
        !
        IF (ts) THEN
          !
          igh = igh + 1
          iy  = 1
          !
          DO ig = gstart, ngw
            gspha(ig,iy) = gspha(ig,iy) / (g(ig)*tpiba2)
          END DO
          DO kk = 1, 6
            fnls     = 0.0d0
            iss = 1
            gwork(1) = 0.0d0
            DO ig = gstart, ngw
               gwork(ig) =  gagx_l(kk,ig) * gspha(ig,iy)
            END DO
            DO is = 1, nspnl
              ll = l2ind(1,is)
              IF(ll.GT.0) THEN

                ALLOCATE(auxc(ngw,na(is)))

                gwtmp(1) = 0.0d0
                DO ig = gstart, ngw
                  gwtmp(ig) = gwork(ig) * (wnl(ig,ll,is)-wnla(ig,ll,is))
                END DO

                DO ia = 1, na(is)
                  auxc(1,ia) = CMPLX(0.0d0,0.0d0)
                  DO ig = gstart, ngw
                    auxc(ig,ia) = csign(0) * gwtmp(ig) * eigr(ig,ia+iss-1)
                  END DO
                END DO
    
                CALL DGEMM( 'T', 'N', na(is), nx, 2*ngw, 1.0d0, auxc(1,1), &
                  2*ngw, c0(1,1,1,ispin_wfc), 2 * cdesc%ldg, 0.0d0, fnls(iss,1), nsanl )

                DEALLOCATE(auxc)

              END IF
              iss = iss + na(is)
            END DO

            CALL DSCAL(size(fnls),2.d0,fnls,1)
            DO i = 1, nx
              isa = 1
              DO is = 1, nspnl
                tt1 = DDOT(na(is), fnl(1,ispin)%r(isa,igh,i), 1, fnls(isa,i), 1)
                denl(kk) = denl(kk) +  2.0d0 * occ(i,1,ispin) * wsg(igh,is)  * tt1
                isa = isa + na(is)
              END DO
            END DO

          END DO
        END IF


        !
        IF(tp) THEN
          !
          ighp = igh
          !
          im( 1 ) = 3
          im( 2 ) = 1
          im( 3 ) = 2
          !
          CALL set_pmtm( pm, pmtm )
          !
          DO m = 1, 3

            iy  = 1    + im( m )

            DO ig = gstart, ngw
              gspha(ig,iy) = gspha(ig,iy) / (g(ig)*tpiba2)
            END DO

            DO kk=1,6

              fnls = 0.0d0
              iss = 1
              gwork(1) = 0.0d0
              DO ig = gstart, ngw
                gwork(ig)= gagx_l(kk,ig) * gspha(ig,iy)
              END DO

              DO is=1,nspnl

                ll = l2ind(2,is)
                IF(ll.GT.0) THEN
                  ALLOCATE(auxc(ngw,na(is)))

                  gwtmp(1) = 0.0d0
                  DO ig = gstart, ngw
                    gwtmp(ig) = gwork(ig) * ( 3.d0 * wnl(ig,ll,is) - wnla(ig,ll,is) )
                  END DO

                  DO ia = 1, na(is)
                    auxc(1,ia) = CMPLX(0.0d0,0.0d0)
                    DO ig = gstart, ngw
                      auxc(ig,ia) = csign(1) * gwtmp(ig) * eigr(ig,ia+iss-1)
                    END DO
                  END DO

                  CALL DGEMM( 'T', 'N', na(is), nx, 2*ngw, 1.0d0, &
                    auxc(1,1),2*ngw, c0(1,1,1,ispin_wfc), 2 * cdesc%ldg, &
                    0.0d0, fnls(iss,1), nsanl )

                  DEALLOCATE(auxc)
                END IF
                iss = iss + na(is)
              END DO
  
              isa=0
              DO is=1,nspnl
                temp = 2.d0 * wsg( ighp + im( m ), is)
                DO ia=1,na(is)
                  isa=isa+1
                  DO in=1,nx
                    IF(me.EQ.1) THEN
                      temp2=0.d0
                      DO mm=1,3
                        temp2=temp2 + pmtm(kk, m, mm )* &
                          fnl(1,ispin)%r(isa, ighp + im( mm ),in)
                      END DO
                      fnls(isa,in)= -temp2+2.d0*fnls(isa,in)
                    ELSE
                      fnls(isa,in)= 2.d0*fnls(isa,in)
                    END IF
                    tt1 = fnl(1,ispin)%r(isa, ighp + im( m ), in )
                    fac = occ(in,1,ispin) * temp
                    tt2 = fnls(isa,in)
                    denl(kk) = denl(kk) + fac * tt1 * tt2
                  END DO
                END DO
              END DO

            END DO
          END DO
          !
          igh = ighp + 3
          !
        END IF

        ! ... d-nonlocality

        IF(td) THEN

          ighd = igh
          !
          im( 1 ) = 5
          im( 2 ) = 3
          im( 3 ) = 1
          im( 4 ) = 2
          im( 5 ) = 4

          CALL set_dmqm( dm, dmqm )

          DO m = 1, 5

            iy  = 4 + im( m )

            !
            DO ig = gstart, ngw
              gspha(ig,iy) = gspha(ig,iy) / (g(ig)*tpiba2)
            END DO

            DO kk = 1, 6

              fnls = 0.0d0
              iss = 1
              gwork(1) = 0.0d0
              DO ig=gstart,ngw
                gwork(ig)= gagx_l(kk,ig) * gspha(ig,iy)
              END DO

              DO is = 1, nspnl

                ll = l2ind(3,is)
                IF(ll.GT.0) THEN
                  ALLOCATE(auxc(ngw,na(is)))
  
                  gwtmp(1) = 0.0d0
                  DO ig = gstart, ngw
                    gwtmp(ig) = gwork(ig) * ( 5.d0 * wnl(ig,ll,is) - wnla(ig,ll,is) )
                  END DO

                  DO ig = gstart, ngw
                    gwtmp(ig) = gwtmp(ig) - 2.0d0/3.0d0 * dm( kk, m ) * wnl(ig,ll,is)
                  END DO

                  DO ia= 1 , na(is)
                    auxc(1,ia) = CMPLX(0.0d0,0.0d0)
                    DO ig = gstart, ngw
                      auxc(ig,ia) = csign(2) * gwtmp(ig) * eigr(ig,ia+iss-1)
                    END DO
                  END DO

                  CALL DGEMM( 'T', 'N', na(is), nx, 2*ngw, 1.0d0, &
                    auxc(1,1), 2*ngw, c0(1,1,1,ispin_wfc), 2 * cdesc%ldg, &
                    0.0d0, fnls(iss,1), nsanl )

                  DEALLOCATE(auxc)

                END IF
                iss = iss + na(is)
              END DO

              isa=0
              DO is=1,nspnl
                temp = 2.d0 * wsg(ighd+im(m),is)
                DO ia=1,na(is)
                  isa=isa+1
                  DO in=1,nx
                    IF(me.EQ.1) THEN
                      temp2=0.d0
                      DO mm=1,5
                        temp2=temp2 + dmqm(kk, m, mm )* &
                          fnl(1,ispin)%r(isa, ighd + im(mm),in)
                      END DO
                      fnls(isa,in)= -2.d0*temp2+2.d0*fnls(isa,in)
                    ELSE
                      fnls(isa,in)= 2.d0*fnls(isa,in)
                    END IF
                    tt1 = fnl(1,ispin)%r(isa,ighd+im(m),in)
                    fac = occ(in,1,ispin) * temp
                    tt2 = fnls(isa,in)
                    denl(kk) = denl(kk) + fac * tt1 * tt2
                  END DO
                END DO
              END DO

            END DO
          END DO
          !
          igh = ighd + 5
          !
        END IF

        ! ... f-nonlocality

        IF(tf) THEN

          ighf = igh

          CALL set_fmrm(fm, fmrm)

          im( 1 ) = 7
          im( 2 ) = 5
          im( 3 ) = 3
          im( 4 ) = 1
          im( 5 ) = 2
          im( 6 ) = 4
          im( 7 ) = 6

          DO m=1,7

            iy  = 9 + im( m )

            DO ig = gstart, ngw
              gspha(ig,iy) = gspha(ig,iy) / (g(ig)*tpiba2)
            END DO

            DO kk=1,6

              fnls = 0.0d0
              iss = 1
              gwork(1) = 0.0d0
              DO ig = gstart, ngw
                gwork(ig)= gagx_l(kk,ig) * gspha(ig,iy)
              END DO

              DO is=1,nspnl

                ll = l2ind(4,is)

                IF(ll > 0) THEN
                  ALLOCATE(auxc(ngw,na(is)))
  
                  gwtmp(1) = 0.0d0
                  DO ig = gstart, ngw
                    gwtmp(ig) = gwork(ig) * ( 7.d0 * wnl(ig,ll,is) - wnla(ig,ll,is) )
                  END DO

                  al = alpha(kk)
                  be = beta(kk)
                  DO ig = gstart, ngw
                    fg = 0.0d0
                    gmod = SQRT( g(ig) )
                    DO s = 1, 3
                      fg = fg + 3.0d0/5.0d0 * fm(be,s,s,m) * gx(al,ig) / gmod
                    END DO
                    DO s = 1, 3
                      fg = fg + 6.0d0/5.0d0 * fm(be,s,al,m) * gx(s,ig) / gmod
                    END DO
                    gwtmp(ig) = gwtmp(ig) - fg * wnl(ig,ll,is)
                  END DO

                  DO ia= 1 , na(is)
                    auxc(1,ia) = CMPLX(0.0d0,0.0d0)
                    DO ig = gstart, ngw
                      auxc(ig,ia) = csign(3) * gwtmp(ig) * eigr(ig,ia+iss-1)
                    END DO
                  END DO

                  CALL DGEMM( 'T', 'N', na(is), nx, 2*ngw, 1.0d0, &
                    auxc(1,1), 2*ngw, c0(1,1,1,ispin_wfc), 2 * cdesc%ldg, &
                    0.0d0, fnls(iss,1), nsanl)

                  DEALLOCATE(auxc)

                END IF

                iss = iss + na(is)
              END DO

              isa=0
              DO is=1,nspnl
                temp = 2.d0 * wsg( ighf + im(m), is )
                DO ia=1,na(is)
                  isa=isa+1
                  DO in=1,nx
                    IF(me == 1) THEN
                      temp2=0.d0
                      DO mm=1,7
                        temp2=temp2 + fmrm(kk,m,mm) * fnl(1,ispin)%r(isa,ighf+im(mm),in)
                      END DO
                      fnls(isa,in)= -3.d0*temp2+2.d0*fnls(isa,in)
                    ELSE
                      fnls(isa,in)= 2.d0*fnls(isa,in)
                    END IF
                    tt1 = fnl(1,ispin)%r(isa,ighf+im(m),in)
                    fac = occ(in,1,ispin) * temp
                    tt2 = fnls(isa,in)
                    denl(kk) = denl(kk) + fac * tt1 * tt2
                  END DO
                END DO
              END DO

            END DO

          END DO
        END IF

        DEALLOCATE(fnls)

      END DO SPIN_LOOP

      DEALLOCATE(gwork)
      DEALLOCATE(gwtmp)
      DEALLOCATE(gspha)
      DEALLOCATE(wnla)

      RETURN
      END SUBROUTINE

!  ----------------------------------------------
!  ----------------------------------------------

      SUBROUTINE pseudo_stress(deps, epseu, gagx_l, sfac, dvps, rhoeg, ht)

!  (describe briefly what this routine does...)
!  ----------------------------------------------

! ... declare modules
      USE cell_module,        only: boxdimensions
      USE ions_base,          ONLY: nsp
      USE reciprocal_vectors, ONLY: gstart, gzero
      USE gvecp,              ONLY: ngm

! ... declare subroutine arguments
      TYPE (boxdimensions), INTENT(IN) :: ht
      REAL(dbl),     INTENT(OUT) :: deps(:)
      REAL(dbl),     INTENT(IN) ::  gagx_l(:,:)
      COMPLEX(dbl),  INTENT(IN) ::  rhoeg(:,:)
      COMPLEX(dbl),  INTENT(IN) ::  sfac(:,:)
      REAL(dbl),     INTENT(IN) ::  dvps(:,:)
      REAL(dbl),     INTENT(IN) ::  epseu

! ... declare other variables
      INTEGER :: ig,k,is, ispin, nspin
      REAL(dbl) :: omega
      COMPLEX(dbl) :: rhets, depst(6)

!  end of declarations
!  ----------------------------------------------
      omega    = ht%deth
      nspin    = SIZE(rhoeg,2)

      depst = (0.d0,0.d0)

      DO is = 1, nsp
        DO ig = gstart, ngm
          rhets = rhoeg(ig, 1)
          IF( nspin > 1) THEN
            rhets = rhets + rhoeg(ig, 2)
          END IF
          rhets = 2.d0 * sfac( ig, is ) * dvps(ig,is) * CONJG(rhets)
          depst(1) = depst(1) + rhets * gagx_l(1,ig)
          depst(2) = depst(2) + rhets * gagx_l(2,ig)
          depst(3) = depst(3) + rhets * gagx_l(3,ig)
          depst(4) = depst(4) + rhets * gagx_l(4,ig)
          depst(5) = depst(5) + rhets * gagx_l(5,ig)
          depst(6) = depst(6) + rhets * gagx_l(6,ig)
        END DO
      END DO

      IF(gzero) THEN
        deps = 2.0_dbl * omega * REAL(depst) - epseu * dalbe
      ELSE
        deps = 2.0_dbl * omega * REAL(depst)
      END IF

      RETURN
      END SUBROUTINE pseudo_stress


!  ----------------------------------------------
!  ----------------------------------------------

!  BEGIN manual

      SUBROUTINE stress_kin(dekin, c0, cdesc, occ, gagx_l) 

!  this routine computes the kinetic energy contribution to the stress 
!  tensor
!
!  dekin(:) = - 2 (sum over i) occ%s(i) * 
!    ( (sum over ig) gagx(:,ig) CONJG( c0%w(ig,ib) ) c0%w(ig,ib)
!                       
!  ----------------------------------------------
!  END manual

! ... declare modules
      USE gvecw, ONLY: ecsig, ecfix, ecutz
      USE wave_types, ONLY: wave_descriptor
      USE constants, ONLY: pi
      USE control_flags, ONLY: force_pairing
      USE reciprocal_vectors, ONLY: gstart, g
      USE cell_base, ONLY: tpiba2

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl), INTENT(OUT) :: dekin(:)
      COMPLEX(dbl), INTENT(IN) :: c0(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) :: occ(:,:,:)
      REAL(dbl) gagx_l(:,:)

! ... declare other variables
      REAL(dbl)  :: sk(6), scg, efac
      REAL(dbl), ALLOCATABLE :: arg(:)
      INTEGER    :: ib, ig, ispin, nspin, ispin_wfc

! ... end of declarations
!  ----------------------------------------------

      nspin = cdesc%nspin
      dekin = 0.0_dbl
      ALLOCATE( arg( cdesc%ldg ) ) 

      efac = 2.0d0 * ecutz / ecsig / SQRT(pi)
      IF( efac > 0.0d0 ) THEN
        DO ig = gstart, cdesc%ngwl
          arg(ig) = 1.0d0 + efac * exp( -( ( tpiba2 * g(ig) - ecfix ) / ecsig )**2 )
        END DO
      ELSE
        arg = 1.0d0
      END IF

! ... compute kinetic energy contribution
      DO ispin = 1, nspin
        ispin_wfc = ispin
        IF( force_pairing ) ispin_wfc = 1
        DO ib = 1, cdesc%nbl( ispin )
          sk = 0.0_dbl
          DO ig = gstart, cdesc%ngwl
            scg = arg(ig) * CONJG( c0(ig,ib,1,ispin_wfc) ) * c0(ig,ib,1,ispin_wfc)
            sk(1)  = sk(1) + scg * gagx_l(1,ig)
            sk(2)  = sk(2) + scg * gagx_l(2,ig)
            sk(3)  = sk(3) + scg * gagx_l(3,ig)
            sk(4)  = sk(4) + scg * gagx_l(4,ig)
            sk(5)  = sk(5) + scg * gagx_l(5,ig)
            sk(6)  = sk(6) + scg * gagx_l(6,ig)
          END DO
          dekin = dekin  + occ(ib,1,ispin) * sk
        END DO
      END DO
      dekin = - 2.0_dbl * dekin
      DEALLOCATE(arg) 
      RETURN
      END SUBROUTINE


!=======================================================================
!==          COMPUTES HARTREE ENERGY CONTRIBUTION                     ==
!=======================================================================

      SUBROUTINE STRESS_HAR(DEHT, EHR, sfac, PS, RHOEG, GAgx_L, box ) 

      use ions_base,          only: nsp
      USE cell_module,        only: boxdimensions
      use mp_global,          ONLY: mpime, nproc
      USE constants,          ONLY: fpi
      USE cell_base,          ONLY: tpiba2
      USE cp_types,           ONLY: pseudo, pseudo_ncpp
      USE reciprocal_vectors, ONLY: gstart, g
      USE gvecp,              ONLY: ngm

      IMPLICIT NONE

!---------------------------------------------------ARGUMENT

      type (boxdimensions) :: box
      TYPE (pseudo), INTENT(IN) :: ps
      REAL(dbl)    :: DEHT(:), EHR, GAgx_L(:,:)
      COMPLEX(dbl) :: RHOEG(:,:)
      COMPLEX(dbl), INTENT(IN) :: sfac(:,:)

!---------------------------------------------------LOCAL

      COMPLEX(dbl)    CHGM1,DEHC(6)
      COMPLEX(dbl)    RHOP,RHOPR,CFPIBG
      COMPLEX(dbl)    RHET,RHOG,RHETS,RHOGS
      COMPLEX(dbl)    CFACT
      REAL(dbl)        r2,hgm1
      REAL(dbl)        HG_TPIBA2,fpibg
      REAL(dbl)        ONE_BY_OMEGA
      REAL(dbl)        ONE_BY_TPIBA2
      REAL(dbl)        omega

      INTEGER       ig, is, k, ispin, nspin

!---------------------------------------------------SUBROUTINE BODY

      omega         = box%deth 
      ONE_BY_OMEGA  = 1.0d0/omega
      ONE_BY_TPIBA2 = 1.0d0/TPIBA2
      nspin         = SIZE(rhoeg,2)
      
      DEHC  = (0.D0,0.D0)
      DEHT  = 0.D0

      DO IG = gstart, ngm
        RHOP = (0.D0,0.D0)
        RHOPR= (0.D0,0.D0)
        DO IS = 1, NSP
          RHOP  = RHOP  + sfac( IG, is ) *  ps%RHOPS(IG,is)
          ! RHOPR = RHOPR + sfac( IG, is ) * ps%DRHOPS(IG,is) 
          RHOPR = RHOPR + sfac( IG, is ) * ps%RHOPS(IG,is) * ps%ap(is)%RAGGIO**2 * 0.5D0
        END DO
        HGM1   = 1.D0 / g(IG) / TPIBA2 
        RHET   = 0.0_dbl
        DO ispin = 1, nspin
          RHET   = RHET + RHOEG(ig,ispin)
        END DO
        RHOG   = RHET + RHOP
        CFACT  = FPI * HGM1 * CONJG(RHOG) * (RHOG * HGM1 + RHOPR)
        DEHC   = DEHC + CFACT * GAgx_L(:,IG)
      END DO

      if (mpime.EQ.0) then
        deht = 2.0_dbl * omega * REAL(dehc) - ehr * dalbe
      else
        deht = 2.0_dbl * omega * REAL(dehc)
      end if

      RETURN
      END SUBROUTINE



      SUBROUTINE stress_debug(dekin, deht, dexc, desr, deps, denl, htm1)
        USE io_global, ONLY: stdout
        REAL(dbl) :: dekin(:), deht(:), dexc(:), desr(:), deps(:), denl(:)
        REAL(dbl) :: detot( 6 ), htm1(3,3)
        REAL(dbl) :: detmp(3,3)
        INTEGER :: k, i, j
        detot = dekin + deht + dexc + desr + deps + denl
        WRITE( stdout,106) detot
        WRITE( stdout,100) dekin
        WRITE( stdout,101) deht
        WRITE( stdout,102) dexc
        WRITE( stdout,103) desr
        WRITE( stdout,104) deps
        WRITE( stdout,105) denl

        DO k=1,6
          detmp(alpha(k),beta(k)) = dekin(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(kin)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = deht(k) + desr(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(electrostatic)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = deht(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(h)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = desr(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(sr)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = deps(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(ps)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = denl(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(nl)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)

        DO k=1,6
          detmp(alpha(k),beta(k)) = dexc(k)
          detmp(beta(k),alpha(k)) = detmp(alpha(k),beta(k))
        END DO
        detmp = MATMUL( detmp(:,:), htm1(:,:) )
        WRITE( stdout,*) "derivative of e(xc)"
        WRITE( stdout,5555) ((detmp(i,j),j=1,3),i=1,3)
5555  format(1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5//)

  100   FORMAT(' dekin :',6F12.4)
  101   FORMAT(' deht  :',6F12.4)
  102   FORMAT(' dexc  :',6F12.4)
  103   FORMAT(' desr  :',6F12.4)
  104   FORMAT(' deps  :',6F12.4)
  105   FORMAT(' denl  :',6F12.4)
  106   FORMAT(' detot :',6F12.4)
      RETURN
      END SUBROUTINE


  END MODULE stress
