!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"

!  AB INITIO COSTANT PRESSURE MOLECULAR DYNAMICS
!  ----------------------------------------------
!  Car-Parrinello Parallel Program
!  Carlo Cavazzoni - Gerardo Ballabio
!  SISSA, Trieste, Italy - 1997-2000
!  Last modified: Fri Feb 11 14:03:32 MET 2000
!  ----------------------------------------------
!  BEGIN manual

      MODULE diis

!  (describe briefly what this module does...)
!  ----------------------------------------------
!  routines in this module:
!  SUBROUTINE allocate_diis(ngwxm,nx,nk)
!  SUBROUTINE deallocate_diis
!  SUBROUTINE diis_print_info(unit)
!  SUBROUTINE converg(c,gemax,cnorm,tprint)
!  SUBROUTINE converg_kp(c,weight,gemax,cnorm,tprint)
!  SUBROUTINE hesele(svar2,gv,vpp,wsg,wnl,eigr,vps,ik)
!  SUBROUTINE simupd(gemax,doions,gv,c0,cgrad,svar0,svarm,svar2,etot,f, &
!                    eigr,vps,wsg,wnl,treset,istate,cnorm,eold,ndiis,nowv)
!  SUBROUTINE simupd_kp(gemax,doions,gv,c0,cgrad,svar0,svarm,svar2, &
!                       etot,f,eigr,vps,wsg,wnl, treset,istate,cnorm, &
!                       eold,ndiis,nowv)
!  SUBROUTINE updis(ndiis,nowv,nsize,max_diis,iact)
!  SUBROUTINE solve(b,ldb,ndim,v)
!  SUBROUTINE solve_kp(b,ldb,ndim,v)
!  ----------------------------------------------
!  END manual

        USE kinds

        IMPLICIT NONE
        SAVE

        PRIVATE

! ...   declare module-scope variables

        LOGICAL :: o_diis, oqnr_diis, treset_diis
        LOGICAL :: tfortr_diis
        INTEGER :: max_diis, nreset, maxnstep
        REAL(dbl) :: hthrs_diis, tol_diis, delt_diis

        REAL(dbl) :: diis_fthr

        ! ...   declare module-scope variables
        INTEGER    :: srot0, srot, sroti, srotf
        REAL(dbl)  :: tolene, tolrho, tolrhof, tolrhoi
        REAL(dbl)  :: temp_elec


        REAL(dbl) :: dethr

        COMPLEX(sgl), ALLOCATABLE :: parame(:,:,:,:)
        COMPLEX(sgl),  ALLOCATABLE :: grade(:,:,:,:)

        LOGICAL    :: updstrfac
        REAL(dbl)  :: gemax

        PUBLIC :: diis_setup, diis_print_info, allocate_diis
        PUBLIC :: delt_diis, deallocate_diis
        PUBLIC :: simupd_kp, simupd
        PUBLIC :: tolrhoi, sroti, tolrho, maxnstep, nreset
        PUBLIC :: srotf, tolene, srot0, srot, treset_diis
        PUBLIC :: tolrhof, temp_elec

! ...   end of module-scope declarations
!  ----------------------------------------------

      CONTAINS

!  subroutines
!  ----------------------------------------------
!  ----------------------------------------------
        SUBROUTINE diis_setup( diis_fthr_inp, oqnr_diis_inp, o_diis_inp, &
            max_diis_inp, hthrs_diis_inp, tol_diis_inp, &
            maxnstep_inp, reset_diis_inp, delt_diis_inp, & 
            temp_inp, srot0_inp, sroti_inp, srotf_inp, &
            tolrho_inp, tolrhoi_inp, tolrhof_inp, tolene_inp)

            LOGICAL, INTENT(IN) :: o_diis_inp, oqnr_diis_inp
            REAL(dbl), INTENT(IN) :: diis_fthr_inp
            INTEGER, INTENT(IN) :: max_diis_inp, reset_diis_inp, maxnstep_inp
            REAL(dbl), INTENT(IN) :: hthrs_diis_inp, tol_diis_inp, delt_diis_inp
            INTEGER, INTENT(IN) :: srot0_inp, sroti_inp, srotf_inp
            REAL(dbl), INTENT(IN) ::  temp_inp
            REAL(dbl), INTENT(IN) ::  tolene_inp, tolrho_inp, tolrhof_inp, tolrhoi_inp

            temp_elec = temp_inp
            srot0 = srot0_inp
            sroti = sroti_inp
            srotf = srotf_inp
            tolrho = tolrho_inp
            tolrhoi = tolrhoi_inp
            tolrhof = tolrhof_inp
            tolene = tolene_inp

            tfortr_diis = .FALSE.
            diis_fthr = diis_fthr_inp
            IF( diis_fthr > 0.0d0 ) THEN
              tfortr_diis = .TRUE.
              tol_diis = diis_fthr_inp
            ELSE
              tol_diis = tol_diis_inp
            END IF

            o_diis = o_diis_inp
            oqnr_diis = oqnr_diis_inp
            max_diis = max_diis_inp
            nreset = reset_diis_inp
            maxnstep = maxnstep_inp
            hthrs_diis = hthrs_diis_inp
            delt_diis = delt_diis_inp
            dethr = 1.d-6

          RETURN
        END SUBROUTINE diis_setup

!  ----------------------------------------------
!  ----------------------------------------------
        SUBROUTINE allocate_diis(ngwxm,nx,nk)
          INTEGER, INTENT(IN) :: ngwxm,nx,nk
          INTEGER :: ierr
          ALLOCATE( parame( ngwxm, nx, nk, max_diis ), STAT=ierr)
          IF( ierr/=0 ) CALL errore(' allocate_diis ', ' allocating parame ', ierr)
          ALLOCATE( grade( ngwxm, nx, nk, max_diis ), STAT=ierr)
          IF( ierr/=0 ) CALL errore(' allocate_diis ', ' allocating grade ', ierr)
          RETURN
        END SUBROUTINE allocate_diis

!  ----------------------------------------------
!  ----------------------------------------------
        SUBROUTINE deallocate_diis
          INTEGER :: ierr
          IF(ALLOCATED(parame)) THEN
            DEALLOCATE(parame, STAT=ierr)
            IF( ierr/=0 ) CALL errore(' allocate_diis ', ' deallocating parame ', ierr)
          END IF
          IF(ALLOCATED(grade))  THEN
            DEALLOCATE(grade, STAT=ierr)
            IF( ierr/=0 ) CALL errore(' allocate_diis ', ' deallocating grade ', ierr)
          END IF
          RETURN
        END SUBROUTINE deallocate_diis

!  ----------------------------------------------
!  ----------------------------------------------
        SUBROUTINE diis_print_info(unit)
          USE control_flags, ONLY: t_diis, t_diis_simple, t_diis_rot
          USE charge_mix, ONLY: charge_mix_print_info
          INTEGER, INTENT(IN) :: unit
            WRITE(unit,100)
            IF( t_diis_simple ) THEN
              WRITE(unit,200)
            ELSE
              WRITE(unit,300)
            END IF
            WRITE(unit,400) max_diis
            WRITE(unit,410) maxnstep
            WRITE(unit,420) delt_diis
            WRITE(unit,430) tol_diis
            WRITE(unit,450) temp_elec
            IF( .NOT. t_diis_simple ) THEN
              CALL charge_mix_print_info(unit)
              WRITE(unit,440) tolrho, tolrhoi, tolrhof
              WRITE(unit,460) srot0, sroti, srotf
              WRITE(unit,470) tolene
            END IF

 100      FORMAT(/,3X,'Using DIIS for electronic minimization')
 200      FORMAT(  3X,'DIIS without charge mixing and wave-function rotation')
 300      FORMAT(  3X,'DIIS with charge mixing and wave-function rotation')
 400      FORMAT(  3X,'order ............................ = ',1I6)
 410      FORMAT(  3X,'maximum number of iterations ..... = ',1I6)
 420      FORMAT(  3X,'time step used for a steepest step = ',1D10.4)
 430      FORMAT(  3X,'threshold for convergence ........ = ',1D10.4)
 450      FORMAT(  3X,'electronic temperature ........... = ',1D10.4)
 440      FORMAT(  3X,'tolerances on rho change ......... = ',3D10.4)
 460      FORMAT(  3X,'steps without new potentials ..... = ',3I5)
 470      FORMAT(  3X,'tolerances on energy change ...... = ',1D10.4)

          RETURN
        END SUBROUTINE diis_print_info

!  ----------------------------------------------
!  ----------------------------------------------
#if defined __T3E
#  define izamax icamax
#  define zdotc cdotc
#endif

      SUBROUTINE converg( c, cdesc, gemax, cnorm, tprint )

!  this routine checks for convergence, by computing the norm of the
!  gradients of wavefunctions
!  version for the Gamma point
!  ----------------------------------------------

        USE wave_base, ONLY: dotp
        USE wave_types, ONLY: wave_descriptor
        USE mp_global, ONLY: group
        USE io_global, ONLY: stdout
        USE mp, ONLY: mp_max
        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(dbl), INTENT(IN) :: c(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        LOGICAL, INTENT(IN) :: tprint
        REAL(dbl), INTENT(OUT) :: gemax, cnorm

! ...   declare other variables
        INTEGER    :: iabs, izamax, i, nb, ngw
        REAL(dbl)  :: gemax_l

! ...   end of declarations
!  ----------------------------------------------

        ngw     = cdesc%ngwl
        nb      = cdesc%nbl( 1 )
        gemax_l = 0.d0
        cnorm   = 0.d0
        DO i = 1, nb
          iabs = izamax( ngw, c(1,i), 1)
          IF( gemax_l < ABS( c(iabs,i) ) ) THEN
            gemax_l = ABS ( c(iabs,i) )
          END IF
          cnorm = cnorm + dotp( cdesc%gzero, ngw, c(:,i), c(:,i) )
        END DO
        CALL mp_max(gemax_l, group)
        gemax = gemax_l
        cnorm = SQRT( cnorm / ( cdesc%nbt( 1 ) * cdesc%ngwt ) )

        IF(tprint) WRITE( stdout,100) gemax, cnorm
 100    FORMAT(' Electrons: max. comp:',g16.10,'  rms norm :',g16.10)

        RETURN
      END SUBROUTINE converg

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE converg_kp( c, cdesc, weight, gemax, cnorm, tprint )

!  this routine checks for convergence, by computing the norm of the
!  gradients of wavefunctions
!  version for generic k-points
!  ----------------------------------------------

        USE wave_types, ONLY: wave_descriptor
        USE mp_global, ONLY: group
        USE io_global, ONLY: stdout
        USE mp, ONLY: mp_sum, mp_max
        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(dbl), INTENT(IN) :: c(:,:,:)
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        REAL(dbl), INTENT(IN)  :: weight(:)
        REAL(dbl), INTENT(OUT) :: gemax, cnorm
        LOGICAL,   INTENT(IN)  :: tprint

! ...   declare other variables
        INTEGER    :: iabs, izamax, i, ik
        REAL(dbl)  :: gemax_l, cnormk
        COMPLEX(dbl) :: zdotc

! ...   end of declarations
!  ----------------------------------------------

        gemax_l = 0.d0
        cnorm   = 0.d0
        DO ik = 1, cdesc%nkl
          cnormk  = 0.d0
          DO i = 1, cdesc%nbl( 1 )
            iabs = izamax( cdesc%ngwl, c(1,i,ik), 1)
            IF( gemax_l < ABS( c(iabs,i,ik) ) ) THEN
              gemax_l = ABS( c(iabs,i,ik) )
            END IF
            cnormk = cnormk + REAL( zdotc( cdesc%ngwl, c(1,i,ik), 1, c(1,i,ik), 1) )
          END DO
          cnormk = cnormk * weight(ik)
          cnorm = cnorm + cnormk
        END DO
        CALL mp_max(gemax_l, group)
        CALL mp_sum(cnorm, group)
        gemax = gemax_l
        cnorm = SQRT( cnorm / ( cdesc%nbt( 1 ) * cdesc%ngwt ) )

        IF(tprint) WRITE( stdout,100) gemax, cnorm
 100    FORMAT(' Electrons: max. comp:',g16.10,'  rms norm :',g16.10)

        RETURN
      END SUBROUTINE converg_kp

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE hesele(svar2, gv, vpp, wsg, wnl, eigr, sfac, vps, ik)

!  (describe briefly what this routine does...)
!  ----------------------------------------------

! ...  declare modules
       USE cell_base, ONLY: tpiba2
       USE gvecw, ONLY: tecfix
       USE pseudopotential, ONLY: tl, l2ind, nspnl, lm1x
       USE cp_types, ONLY: recvecs
       USE ions_base, ONLY: nsp, na
       USE mp_global, ONLY: group
       USE mp, ONLY: mp_sum, mp_max

      IMPLICIT NONE

! ... declare subroutine arguments
      REAL(dbl) :: svar2
      TYPE (recvecs) :: gv
      REAL(dbl) :: wnl(:,:,:,:), wsg(:,:), vps(:,:)
      REAL(dbl) :: vpp(:)
      COMPLEX(dbl) :: sfac(:,:)
      COMPLEX(dbl) :: eigr(:,:)
      INTEGER, OPTIONAL, INTENT(IN) :: ik

! ... declare other variables
      REAL(dbl)  vp,ftpi,arg
      INTEGER l,ll,i,ig,igh,is,m,j, ikk

! ... end of declarations
!  ----------------------------------------------

      ikk = 1
      IF( PRESENT(ik) ) ikk = ik

      IF( SIZE(vpp) > SIZE(wnl, 1) ) THEN
        CALL errore(' hesele ', ' inconsistent size for vpp ', SIZE(vpp) )
      END IF

! ... calculate H0 :The diagonal approximation to the 2nd derivative matrix

! ... local potential
      vp = 0.0d0
      IF( .NOT. PRESENT(ik) ) THEN
        IF(gv%gzero) THEN
          DO i = 1, nsp
            vp = vp + REAL( sfac(i,1) ) * vps(1,i)
          END DO
        END IF
        CALL mp_sum(vp, group)
      END IF

      vpp = vp

! ... nonlocal potential
      igh = 0
      DO l = 0, lm1x
        IF(tl(l)) THEN
          DO m = -l, l
            igh = igh + 1
            DO is = 1, nspnl
              ll = l2ind( l+1, is)
              IF( ll > 0 ) THEN
                vpp(:) = vpp(:) + na(is) * wsg(igh,is) * wnl(:,ll,is,ikk)**2
              END IF
            END DO
          END DO
        END IF
      END DO

! ... kinetic energy
      ftpi = 0.5d0 * tpiba2
      ikk = 1
      IF( PRESENT(ik) ) ikk = ik

      IF(tecfix) THEN
        vpp(:) = vpp(:) + ftpi * gv%khgcutz_l( 1:SIZE(vpp), ikk )
      ELSE
        vpp(:) = vpp(:) + ftpi * gv%khg_l( 1:SIZE(vpp), ikk )
      END IF

      WHERE ( ABS( vpp ) .LT. hthrs_diis ) vpp = hthrs_diis
      vpp = 1.0d0 / vpp

      IF ( PRESENT(ik) ) vpp(:) = svar2 * gv%kg_mask_l(:,ik)

      RETURN
      END SUBROUTINE hesele

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE fermi_diis( ent, gv, kp, occ, nb, nel, eig, wke, efermi, sume, temp)
        USE brillouin, ONLY: kpoints
        USE electrons_module, ONLY: fermi_energy
        USE cp_types, ONLY: recvecs
        TYPE (recvecs), INTENT(IN) ::  gv
        TYPE (kpoints), INTENT(IN) ::  kp
        REAL(dbl)   :: occ(:,:,:)
        REAL(dbl)   :: wke(:,:,:)
        REAL(dbl)   :: eig(:,:,:), efermi, sume, ent, temp, entk, qtot
        INTEGER :: ik, ispin, nel, nb

        qtot = REAL( nel ) 
        CALL fermi_energy(kp, eig, occ, wke, efermi, qtot, temp, sume)

! ...   compute the enthropic correction
        ent = 0.0d0
        DO ispin = 1, SIZE( occ, 3 )
          DO ik = 1, SIZE( occ, 2 )
            CALL enthropy( occ(:,ik,ispin), temp, nb, entk )
            ent = ent + kp%weight(ik) * entk
          END DO
        END DO
      RETURN
      END SUBROUTINE fermi_diis

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE simupd(gemax,doions,gv,c0,cgrad,cdesc,svar0,svarm,svar2,etot,f, &
                        eigr,sfac,vps,wsg,wnl,treset,istate,cnorm,eold,ndiis,nowv)

!  this routine performs a DIIS step
!  version for the Gamma point
!  ----------------------------------------------

! ... declare modules
      USE cp_types, ONLY: recvecs
      USE wave_types, ONLY: wave_descriptor
      USE mp_global, ONLY: group
      USE io_global, ONLY: stdout
      USE mp, ONLY: mp_sum, mp_max

      IMPLICIT NONE

! ... declare subroutine arguments

! max_diis (integer ) max number of stored wave functions
! oqnr_diis   (logical ) if .true. use an appx. ham. as guess
! treset (logical ) if .true. reset DIIS
! tol_diis   (REAL(dbl)  ) convergence tolerance
! hthrs_diis  (REAL(dbl)  ) minimum value for a hessel matrix elm.
! etot   (REAL(dbl)  ) Kohn-Sham energy

      TYPE (recvecs) :: gv
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:), cgrad(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      COMPLEX(dbl) :: sfac(:,:) 
      COMPLEX(dbl) :: eigr(:,:) 
      LOGICAL, INTENT(OUT) :: doions
      LOGICAL, INTENT(INOUT) :: treset
      REAL(dbl) :: gemax, etot, svar0, svarm, svar2
      REAL(dbl) :: f(:), vps(:,:), wnl(:,:,:,:), wsg(:,:)
      REAL(dbl) :: eold
      INTEGER ::  ndiis, nowv

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: cm(:,:) !  cm(gv%ngw_l,c0(1)%nb_l)
      REAL(dbl),    ALLOCATABLE :: bc(:,:) !  bc(max_diis+1,max_diis+1)
      REAL(dbl),    ALLOCATABLE :: vc(:)   !  vc(max_diis+1)
      REAL(dbl),    ALLOCATABLE :: fm1(:)
      REAL(dbl),    ALLOCATABLE :: vpp(:)  !  vpp(gv%ngw_l)
      REAL(dbl)    cnorm
      REAL(dbl)    var2,rc0rc0,ff,vvpp,fff,rri
      REAL(dbl)    rrj,rii,rij,r1,r2
      LOGICAL   teinc
      INTEGER   istate, nsize, i, j, l, k, ik, ierr
      INTEGER, SAVE :: prevv

! ... end of declarations
!  ----------------------------------------------

! c0 : current wavefunction, on output new estimated G.S. wave functions
! cgrad : current wavefunction gradient --> common fowf
! cm : scratch space; out --> old wavefunction

      IF( treset ) istate = 0

      ALLOCATE( fm1( SIZE(f) ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd ', ' allocating fm1 ', ierr)
      ALLOCATE( cm( cdesc%ldg, cdesc%ldb ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd ', ' allocating cm ', ierr)
      ALLOCATE( vpp( cdesc%ldg ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd ', ' allocating vpp ', ierr)
      ALLOCATE( bc(max_diis+1, max_diis+1), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd ', ' allocating bc ', ierr)
      ALLOCATE( vc(max_diis+1), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd ', ' allocating vc ', ierr)

      WHERE ( ABS(f) .GT. 1.0D-10 )  
        fm1 = 1.0d0 / f
      ELSEWHERE
        fm1 = 1.0d-10
      END WHERE

! ... test for convergence
      CALL converg( cgrad(:,:,1), cdesc, gemax, cnorm, .FALSE.)
      doions = cnorm .LT. tol_diis
      IF( doions ) THEN
        GOTO 999
      END IF

! ... check for an increase in energy
! ... in a good step etot < eold and therefore (etot-eold) < 0 < dethr
      teinc = .FALSE. ;  IF( ( etot - eold ) > dethr ) teinc = .TRUE.

! ... statemachine
      SELECT CASE (istate)
      CASE (2)
! ...   if the energy has increased, reject the last step and then reset the DIIS 
        istate = 2 ; IF( teinc ) istate = 1
      CASE DEFAULT
! ...   reset DIIS
        istate = 2
        CALL updis(ndiis, nowv, prevv, nsize, max_diis, 0)
      END SELECT

      IF ( istate == 1 ) THEN

        treset = .TRUE.

        WRITE( stdout,*) 'Steepest descent step; DIIS reset!'

! ...   reject last move, if it wasn't a reset
        IF( ndiis .NE. 0 ) THEN
          DO ik = 1, cdesc%nkl
            c0(:,:,ik)    = parame(:,:,ik,nowv)
            cgrad(:,:,ik) = grade(:,:,ik,nowv)
          END DO
          var2 = -svar2
        ELSE
          var2 = svar2
        END IF

! ...   do a steepest-descent step
        CALL diis_steepest(c0, cgrad, cdesc, var2)

      ELSE

        treset = .FALSE.

! ...   perform a electronic DIIS step
        CALL updis(ndiis, nowv, prevv, nsize, max_diis, 1)

! ...   update DIIS buffers
        CALL update_diis_buffers( c0, cgrad, cdesc, nowv)

! ...   calculate the new Hessian
        CALL hesele(svar2,gv,vpp,wsg,wnl,eigr,sfac,vps)

! ...   set up DIIS matrix
        ff=1.0d0
        bc(1:nsize,1:nsize) = 0.0d0

        DO l=gv%gstart,gv%ngw_l
          vvpp=vpp(l)*vpp(l)
          DO k=1, cdesc%nbl( 1 )
            IF(oqnr_diis ) ff = fm1(k)
            fff=2.0d0*ff*ff*vvpp
            DO i=1,nsize-1
              rri=REAL(grade(l,k,1,i))
              rii=AIMAG(grade(l,k,1,i))
              DO j=1,i
                rrj=REAL(grade(l,k,1,j))
                rij=AIMAG(grade(l,k,1,j))
                bc(i,j)=bc(i,j)+(rri*rrj+rii*rij)*fff
              END DO
            END DO
          END DO
        END DO

        IF(gv%gzero) THEN
          DO k = 1, cdesc%nbl( 1 )
            IF(oqnr_diis ) ff = fm1(k)
            fff=ff*ff*vpp(1)*vpp(1)
            DO i=1,nsize-1
              r1=REAL(grade(1,k,1,i))
              DO j=1,i
                r2=REAL(grade(1,k,1,j))
                bc(i,j)=bc(i,j)+r1*r2*fff
              END DO
            END DO
          END DO
        END IF

        DO i=1,nsize-1
          DO j=1,i
            bc(j,i)=bc(i,j)
          END DO
        END DO
        DO i=1,nsize-1
          CALL mp_sum( bc(1:nsize,i), group)
        END DO

        DO i=1,nsize-1
          vc(i)=0.d0
          bc(i,nsize)=-1.d0
          bc(nsize,i)=-1.d0
        END DO
        vc(nsize)=-1.d0
        bc(nsize,nsize)=0.d0

! ...   solve system of linear equations
        CALL solve(bc,max_diis+1,nsize,vc)

! ...   compute interpolated coefficient and gradient vectors
        cm           = CMPLX(0.0d0,0.0d0)
        c0(:,:,1)    = CMPLX(0.0d0,0.0d0)
        DO i = 1, nsize-1
          DO j = 1, cdesc%nbl( 1 )
            cm(:,j)   = cm(:,j)   + vc(i) *  grade(:,j,1,i)
            c0(:,j,1) = c0(:,j,1) + vc(i) * parame(:,j,1,i)
          END DO
        END DO

! ...   estimate new parameter vectors
        ff = 1.0d0
        DO i = 1, cdesc%nbl( 1 )
          IF(oqnr_diis ) ff = fm1(i)
          c0(:,i,1) = c0(:,i,1) - ff * vpp(:) * cm(:,i)
        END DO

        eold = etot

      END IF

 999  CONTINUE

      DEALLOCATE(fm1, cm, vpp, bc, vc, STAT=ierr)
      IF( ierr/=0 ) CALL errore(' simupd ', ' deallocating arrays ', ierr)

      RETURN
      END SUBROUTINE simupd

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE simupd_kp(gemax,doions,gv,kp,c0,cgrad,cdesc,svar0,svarm,svar2, &
                 etot,occ,eigr,sfac,vps,wsg,wnl, treset,istate,cnorm, &
                 eold,ndiis,nowv)

!  this routine performs a DIIS step
!  version for generic k-points
!  ----------------------------------------------

! ... declare modules
      USE cp_types, ONLY: recvecs
      USE wave_types, ONLY: wave_descriptor
      USE brillouin, ONLY: kpoints
      USE mp_global, ONLY: group
      USE io_global, ONLY: stdout
      USE mp, ONLY: mp_sum

      IMPLICIT NONE

! ... declare subroutine arguments

! max_diis (integer ) maximum number of stored wave functions
! oqnr_diis   (logical ) if .TRUE. use an approximated Hamiltonian as guess
! treset (logical ) if .TRUE. reset DIIS
! tol_diis   (REAL(dbl)  ) convergence tolerance
! hthrs_diis  (REAL(dbl)  ) minimum value for a Hessian matrix element
! etot   (REAL(dbl)  ) Kohn-Sham energy

      TYPE (recvecs) gv
      TYPE (kpoints) kp
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:), cgrad(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      COMPLEX(dbl) :: sfac(:,:) 
      COMPLEX(dbl) :: eigr(:,:) 
      LOGICAL, INTENT(OUT) :: doions
      LOGICAL, INTENT(INOUT) :: treset
      REAL(dbl)  gemax, etot, svar0, svarm, svar2
      REAL(dbl)  occ(:,:)
      REAL(dbl)  vps(:,:),wnl(:,:,:,:),wsg(:,:)
      REAL(dbl)  eold
      INTEGER    istate,ndiis,nowv

! ... declare other variables
      COMPLEX(dbl), ALLOCATABLE :: cm(:,:)
      COMPLEX(dbl), ALLOCATABLE :: bc(:,:), vc(:)
      REAL(dbl), ALLOCATABLE :: vpp(:), fm1(:)
      REAL(dbl)    cnorm
      REAL(dbl)    var2,rc0rc0,ff,vvpp,fff,rri
      REAL(dbl)    rrj,rii,rij,r1,r2
      LOGICAL :: teinc
      INTEGER   nsize, i, j, l, k, ik, ierr
      INTEGER, SAVE :: prevv

! ... end of declarations
!  ----------------------------------------------

! ... c0 : current wavefunction, on output new estimated G.S. wave functions
! ... cgrad : current wavefunction gradient --> common fowf
! ... cm : scratch space; out --> old wavefunction

      IF( treset ) istate = 0

      ALLOCATE( fm1( SIZE(occ, 1) ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' allocating fm1 ', ierr)
      ALLOCATE( cm( cdesc%ldg, cdesc%ldb ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' allocating cm ', ierr)
      ALLOCATE( vpp( cdesc%ldg ), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' allocating vpp ', ierr)
      ALLOCATE( bc(max_diis+1, max_diis+1), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' allocating bc ', ierr)
      ALLOCATE( vc(max_diis+1), STAT=ierr )
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' allocating vc ', ierr)

! ... test for convergence
      CALL converg_kp(cgrad, cdesc, kp%weight, gemax, cnorm, .TRUE.)
      doions = cnorm .LT. tol_diis
      IF( doions ) THEN
        GOTO 999
      END IF

! ... check for an increase in energy
! ... in a good step etot < eold and therefore (etot-eold) < 0 < dethr
      teinc = .FALSE. ; IF( ( etot - eold ) > dethr ) teinc = .TRUE.

! ... statemachine
      SELECT CASE (istate)
      CASE (2)
! ...   if the energy has increased, reject the last step and then reset the DIIS
        istate = 2 ;  IF ( teinc ) istate = 1
      CASE DEFAULT
! ...   reset DIIS
        istate = 2
        CALL updis(ndiis, nowv, prevv, nsize, max_diis, 0)
      END SELECT


      IF ( istate == 1 ) THEN

        treset = .TRUE.

! ...   electronic steepest descent
        WRITE( stdout,*) 'Steepest descent step; DIIS reset!'

        IF(ndiis.NE.0) THEN
          DO ik = 1, cdesc%nkl
            c0(:,:,ik)    = parame(:,:,ik,nowv)
            cgrad(:,:,ik) = grade(:,:,ik,nowv)
          END DO
          var2 = -svar2
        ELSE
          var2 =  svar2
        END IF

! ...   do a steepest-descent step
        CALL diis_steepest(c0, cgrad, cdesc, var2)

      ELSE

        treset = .FALSE.

! ...   perform an electronic DIIS step
        CALL updis(ndiis,nowv,prevv,nsize,max_diis,1)

! ...   update DIIS buffers
        CALL update_diis_buffers( c0, cgrad, cdesc, nowv)

        DO ik = 1, kp%nkpt

          WHERE ( ABS( occ(:,ik) ) .GT. 1.0D-10 )  
            fm1 = 1.0d0 / occ(:,ik)
          ELSEWHERE
            fm1 = 1.0d-10
          END WHERE

! ...     calculate the new Hessian
          CALL hesele(svar2,gv,vpp,wsg,wnl,eigr,sfac,vps,ik)

! ...       set up DIIS matrix
            ff=1.0d0
            bc(1:nsize,1:nsize) = CMPLX(0.0d0,0.0d0)

            DO l=1,gv%ngw_l
              vvpp = vpp(l)*vpp(l)
              DO k=1, cdesc%nbl( 1 )
                IF(oqnr_diis) ff = fm1(k)
                fff = ff*ff*vvpp
                DO i=1,nsize-1
                  DO j=1,i
                    bc(i,j) = bc(i,j) + CONJG(grade(l,k,ik,i)) * grade(l,k,ik,j) * fff
                  END DO
                END DO
              END DO
            END DO

            DO i=1,nsize-1
              CALL mp_sum( bc(1:nsize, i), group )
            END DO

            DO i=1,nsize-1
              DO j=1,i
                bc(j,i) = CONJG(bc(i,j))
              END DO
            END DO

            DO i=1,nsize-1
              vc(i)=CMPLX(0.d0,0.d0)
              bc(i,nsize)=CMPLX(-1.d0,0.d0)
              bc(nsize,i)=CMPLX(-1.d0,0.d0)
            END DO
            vc(nsize)=CMPLX(-1.d0,0.d0)
            bc(nsize,nsize)=CMPLX(0.d0,0.d0)

! ...       compute eigenvectors
            CALL solve_kp(bc,max_diis+1,nsize,vc)

! ...       compute interpolated coefficient and gradient vectors
            cm = CMPLX(0.0d0,0.0d0)
            c0(:,:,ik) = CMPLX(0.0d0,0.0d0)
            DO i=1,nsize-1
              DO j=1,cdesc%nbl( 1 )
                DO k=1,gv%ngw_l
                  cm(k,j)    = cm(k,j)    + CONJG(vc(i)) * grade(k,j,ik,i)
                  c0(k,j,ik) = c0(k,j,ik) + CONJG(vc(i)) * parame(k,j,ik,i)
                END DO
              END DO
            END DO

! ...       estimate new parameter vectors
            ff=1.0d0
            DO i=1,cdesc%nbl( 1 )
              IF(oqnr_diis) ff = fm1(i)
              c0(:,i,ik) = c0(:,i,ik) - ff*vpp(:)*cm(:,i)
            END DO

        END DO

        eold = etot

      END IF

 999  CONTINUE

      DEALLOCATE(fm1, cm, vpp, bc, vc, STAT=ierr)
      IF( ierr/=0 ) CALL errore(' simupd_kp ', ' deallocating arrais ', ierr)

      RETURN
      END SUBROUTINE simupd_kp

!  ----------------------------------------------
!  ----------------------------------------------
      SUBROUTINE updis(ndiis,nowv,prevv,nsize,max_diis,iact)

!  this routine sets up parameters for the next DIIS step
!  ----------------------------------------------

      IMPLICIT NONE
      INTEGER ndiis,nowv,nsize,max_diis,iact,prevv

      IF(iact.EQ.1) THEN
        prevv = nowv
        nowv = mod(ndiis, max_diis) + 1  ! index of current wavefunction
        ndiis = ndiis +  1               ! DIIS steps since last reset
        nsize = ndiis +  1               ! number of states stored
        IF( nsize .GT. max_diis ) nsize = max_diis + 1
      ELSE
! ...   reset DIIS
        ndiis=0
        nowv =1
        prevv =1
        nsize=0
      END IF

      RETURN
      END SUBROUTINE updis

!=----------------------------------------------------------------------------=!

        SUBROUTINE update_diis_buffers( c, cgrad, cdesc, nowv)
          USE wave_types, ONLY: wave_descriptor
          IMPLICIT NONE
          COMPLEX(dbl), INTENT(IN) :: cgrad(:,:,:)
          COMPLEX(dbl), INTENT(INOUT) :: c(:,:,:)
          TYPE (wave_descriptor), INTENT(IN) :: cdesc
          INTEGER, INTENT(IN) :: nowv
          INTEGER :: ik, ib
          DO ik = 1, cdesc%nkl
            DO ib = 1, cdesc%nbl( 1 )
              CALL ZDSCAL( cdesc%ngwl, -1.0d0, cgrad(1,ib,ik), 1 )
            END DO
            grade(:,:,ik,nowv)  = cgrad(:,:,ik)
            parame(:,:,ik,nowv) = c(:,:,ik)
          END DO
          RETURN
        END SUBROUTINE

!=----------------------------------------------------------------------------=!

        SUBROUTINE diis_steepest(c, cgrad, cdesc, var2)
          USE wave_types, ONLY: wave_descriptor
          IMPLICIT NONE
          COMPLEX(dbl), INTENT(IN) :: cgrad(:,:,:)
          COMPLEX(dbl), INTENT(INOUT) :: c(:,:,:)
          TYPE (wave_descriptor), INTENT(IN) :: cdesc
          REAL(dbl), INTENT(IN) :: var2
          INTEGER :: ik
          DO ik = 1, cdesc%nkl
            c(:,:,ik) = c(:,:,ik) + var2 * cgrad(:,:,ik)
            IF ( cdesc%gzero ) THEN
              c(1,:,ik) = CMPLX( REAL( c(1,:,ik) ), 0.d0 )
            END IF
          END DO
          RETURN
        END SUBROUTINE

!=----------------------------------------------------------------------------=!

#if defined __T3E
#  define zhptrf chptrf
#  define zhptrs chptrs
#  define dsptrf ssptrf
#  define dsptrs ssptrs
#endif

!  ----------------------------------------------
!  BEGIN manual

      SUBROUTINE solve(b, ldb, ndim, v)

!  (describe briefly what this routine does...)
!  version for Gamma-point calculations
!  ----------------------------------------------
!  END manual

      USE mp_global, ONLY: root, group
      USE mp, ONLY: mp_bcast
      IMPLICIT NONE

! ... declare subroutine arguments
      INTEGER, INTENT(IN) :: ldb, ndim
      REAL(dbl) :: b(:,:), v(:)

! ... declare other variables

      INTEGER :: i, j, k, info
      REAL(dbl) :: ap(ndim*(ndim+1)/2)
      INTEGER :: ipiv(ndim)

! ... end of declarations
!  ----------------------------------------------

      k = 0
      DO j = 1,ndim
        DO i = j,ndim
          k = k + 1
          ap(k) = b(i,j)
        END DO
      END DO
      CALL dsptrf( 'L', ndim, ap, ipiv, info )
      IF(info .NE. 0) THEN
        CALL errore(' solve ',' dsptrf has failed ', info)
      END IF
      CALL dsptrs( 'L', ndim, 1, ap, ipiv, v, ndim, info )
      IF(info .NE. 0) THEN
        CALL errore(' solve ',' dsptrs has failed ', info)
      END IF

      CALL mp_bcast(v, root, group)

      RETURN
      END SUBROUTINE solve

!  ----------------------------------------------
!  BEGIN manual

      SUBROUTINE solve_kp(b,ldb,ndim,v)

!  (describe briefly what this routine does...)
!  version for generic k-points calculations
!  ----------------------------------------------
!  END manual

      USE mp_global, ONLY: root, group
      USE mp, ONLY: mp_bcast

      IMPLICIT NONE

! ... declare subroutine arguments
      INTEGER, INTENT(IN) :: ldb, ndim
      COMPLEX(dbl) :: b(:,:), v(:)

! ... declare other variables

      INTEGER :: ipvt(ndim)
      INTEGER :: ipiv(ndim)
      COMPLEX(dbl) :: ap(ndim*(ndim+1)/2)
      INTEGER :: i,j,k,info

! ... end of declarations
!  ----------------------------------------------

      k = 0
      DO j = 1,ndim
        DO i = j,ndim
          k = k + 1
          ap(k) = b(i,j)
        END DO
      END DO
      CALL zhptrf( 'L', ndim, ap, ipiv, info )
      IF ( info .NE. 0 ) THEN
        CALL errore(' solve_kp ',' zhptrf has failed ', info)
      END IF
      CALL zhptrs( 'L', ndim, 1, ap, ipiv, v, ndim, info )
      IF ( info .NE. 0 ) THEN
        CALL errore(' solve_kp ',' zhptrs has failed ', info)
      END IF

      CALL mp_bcast(v, root, group)

      RETURN
      END SUBROUTINE solve_kp


!=----------------------------------------------------------------------------=!
!=----------------------------------------------------------------------------=!
      END MODULE diis
!=----------------------------------------------------------------------------=!
!=----------------------------------------------------------------------------=!

