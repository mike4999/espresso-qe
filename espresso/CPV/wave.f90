!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"

!  ----------------------------------------------
!  BEGIN manual

!=----------------------------------------------------------------------------=!
   MODULE wave_functions
!=----------------------------------------------------------------------------=!

!  (describe briefly what this module does...)
!  ----------------------------------------------
!  routines in this module:
!  REAL(dbl) FUNCTION dft_kinetic_energy(c,hg,f,nb,rsum)
!  REAL(dbl) FUNCTION cp_kinetic_energy(cp,cm,pmss,emass,delt)
!  SUBROUTINE rande(cm,ampre)
!  SUBROUTINE gram(cp)
!  SUBROUTINE update_wave_functions(cm,c0,cp)
!  SUBROUTINE crot_gamma (c0,lambda,eig)
!  SUBROUTINE crot_kp (ik,c0,lambda,eig)
!  SUBROUTINE proj_gamma(a,b,lambda)
!  SUBROUTINE proj_kp(ik,a,b,lambda)
!  ----------------------------------------------
!  END manual


! ...   include modules
        USE kinds

        IMPLICIT NONE
        SAVE

        PRIVATE

          PUBLIC :: crot, proj, gram, rande, fixwave
          INTERFACE crot
            MODULE PROCEDURE crot_kp, crot_gamma
          END INTERFACE
          INTERFACE proj
            MODULE PROCEDURE proj_kp, proj_gamma, proj2
          END INTERFACE
          INTERFACE rande
            MODULE PROCEDURE rande_s, rande_v, rande_m
          END INTERFACE
          INTERFACE gram
            MODULE PROCEDURE gram_s, gram_v, gram_m
          END INTERFACE
          INTERFACE fixwave
            MODULE PROCEDURE fixwave_s, fixwave_v, fixwave_m
          END INTERFACE

          PUBLIC :: dft_kinetic_energy, cp_kinetic_energy
          PUBLIC :: update_wave_functions, wave_rand_init

!  end of module-scope declarations
!  ----------------------------------------------

!=----------------------------------------------------------------------------=!
      CONTAINS
!=----------------------------------------------------------------------------=!

!  subroutines
!  ----------------------------------------------
!  ----------------------------------------------


    REAL(dbl) FUNCTION dft_kinetic_energy(c0, cdesc, gv, kp, tecfix, f, rsum, xmkin)

!  This function compute the Total Quanto-Mechanical Kinetic Energy of the Kohn-Sham
!  wave function
!  ----------------------------------------------

        USE cell_base, ONLY: tpiba2
        USE brillouin, ONLY: kpoints
        USE wave_types, ONLY: wave_descriptor
        USE electrons_module, ONLY: pmss
        USE cp_types, ONLY: recvecs
        USE control_flags, ONLY: force_pairing

        IMPLICIT NONE

        COMPLEX(dbl), INTENT(IN) :: c0(:,:,:,:)       !  wave functions coefficients
        TYPE (wave_descriptor), INTENT(IN) :: cdesc   !  descriptor of c0
        REAL(dbl), INTENT(IN) :: f(:,:,:)             !  occupation numbers
        TYPE (recvecs), INTENT(IN) :: gv              !  reciprocal space vectors
        TYPE (kpoints), INTENT(IN) :: kp              !  k points
        LOGICAL, INTENT(IN) :: tecfix                 !  Constant Cut-off is used
        REAL(dbl), INTENT(OUT) :: rsum(:)             !  charge density
        REAL(dbl), OPTIONAL, INTENT(INOUT) :: xmkin

        INTEGER    :: ib, ig, ik, ispin, ispin_wfc
        REAL(dbl)  :: sk1, ss1, xkin, scg1, skm, fact, rsumk, xmkink, xkink
        REAL(dbl), POINTER :: gmod2(:)

! ... end of declarations
!  ----------------------------------------------

      IF( ( cdesc%nkl > SIZE( c0, 3 )       ) .OR. &
          ( cdesc%nkl > SIZE( kp%weight )   ) .OR. &
          ( cdesc%nkl > SIZE( gv%khg_l, 2 ) ) .OR. &
          ( cdesc%nkl > SIZE( f, 2 )        )    ) &
        CALL errore( ' dft_kinetic_energy ', ' wrong arrays sizes ', 1 )

      xkin = 0.d0

      DO ispin = 1, cdesc%nspin

        rsum( ispin ) = 0.d0

        ispin_wfc = ispin
        IF( force_pairing ) ispin_wfc = 1
         
        DO ik = 1, cdesc%nkl

          fact = kp%weight(ik)

          IF( cdesc%gamma ) THEN
            fact = fact * 2.d0
          END IF

          IF( tecfix ) THEN
            gmod2 => gv%khgcutz_l(:,ik)
          ELSE
            gmod2 => gv%khg_l(:,ik)
          ENDIF

          xkin  = xkin + fact * &
             dft_kinetic_energy_s( ispin, c0(:,:,ik,ispin_wfc), cdesc, gmod2, f(:,ik,ispin) )

          IF( PRESENT( xmkin ) ) THEN
            xmkin = xmkin + fact * &
               dft_weighted_kinene( ispin, c0(:,:,ik,ispin_wfc), cdesc, gmod2, f(:,ik,ispin) )
          END IF

          rsum( ispin ) = rsum( ispin ) + fact * &
             dft_total_charge( ispin, c0(:,:,ik,ispin_wfc), cdesc, f(:,ik,ispin) )

        END DO

      END DO

      dft_kinetic_energy = xkin

      RETURN
    END FUNCTION dft_kinetic_energy

!=----------------------------------------------------------------------------=!


      REAL(dbl) FUNCTION dft_total_charge( ispin, c, cdesc, fi )

!  This subroutine compute the Total Charge in reciprocal space
!  ------------------------------------------------------------

        USE wave_types, ONLY: wave_descriptor

        IMPLICIT NONE

        COMPLEX(dbl), INTENT(IN) :: c(:,:)
        INTEGER, INTENT(IN) :: ispin
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        REAL (dbl),  INTENT(IN) :: fi(:)
        INTEGER   :: ib, igs
        REAL(dbl) :: rsum
        COMPLEX(dbl) :: wdot
        COMPLEX(dbl) :: ZDOTC
        EXTERNAL ZDOTC

! ... end of declarations

        IF( ( cdesc%nbl( ispin ) > SIZE( c, 2 ) ) .OR. &
            ( cdesc%nbl( ispin ) > SIZE( fi )     )    ) &
          CALL errore( ' dft_total_charge ', ' wrong sizes ', 1 )

        rsum = 0.0d0

        IF( cdesc%gamma .AND. cdesc%gzero ) THEN

          DO ib = 1, cdesc%nbl( ispin )
            wdot = ZDOTC( ( cdesc%ngwl - 1 ), c(2,ib), 1, c(2,ib), 1 )
            wdot = wdot + REAL( c(1,ib), dbl )**2 / 2.0d0 
            rsum = rsum + fi(ib) * REAL( wdot )
          END DO

        ELSE

          DO ib = 1, cdesc%nbl( ispin )
            wdot = ZDOTC( cdesc%ngwl, c(1,ib), 1, c(1,ib), 1 )
            rsum = rsum + fi(ib) * REAL( wdot )
          END DO

        END IF

        dft_total_charge = rsum
        
        RETURN
      END FUNCTION dft_total_charge

!=----------------------------------------------------------------------------=!

      REAL(dbl) FUNCTION dft_weighted_kinene( ispin, c, cdesc, g2, fi)

!  (describe briefly what this routine does...)
!  ----------------------------------------------

        USE wave_types, ONLY: wave_descriptor
        USE electrons_module, ONLY: pmss

        COMPLEX(dbl), INTENT(IN) :: c(:,:)
        INTEGER, INTENT( IN ) :: ispin
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        REAL (dbl), INTENT(IN) :: fi(:), g2(:)
        INTEGER    ib, ig
        REAL(dbl)  skm, xmkin
! ... end of declarations

        xmkin = 0.0d0

        IF( cdesc%nbl( ispin ) > SIZE( c, 2 ) .OR. &
            cdesc%nbl( ispin ) > SIZE( fi )        ) &
          CALL errore( ' dft_weighted_kinene ', ' wrong sizes ', 1 )
        IF( cdesc%ngwl > SIZE( c, 1 ) .OR. &
            cdesc%ngwl > SIZE( g2 )     .OR. &
            cdesc%ngwl > SIZE( pmss )      ) &
          CALL errore( ' dft_weighted_kinene ', ' wrong sizes ', 2 )

        IF( cdesc%gamma .AND. cdesc%gzero ) THEN

          DO ib = 1, cdesc%nbl( ispin )
            skm = 0.d0
            DO ig = 2, cdesc%ngwl
              skm  = skm + g2(ig) * REAL( CONJG( c(ig,ib) ) * c(ig,ib), dbl) * pmss(ig)
            END DO
            skm = skm + g2(1) * REAL( c(1,ib), dbl )**2 * pmss(1) / 2.0d0
            xmkin = xmkin + fi(ib) * skm * 0.5d0
          END DO

        ELSE

          DO ib = 1, cdesc%nbl( ispin )
            skm = 0.d0
            DO ig = 1, cdesc%ngwl
              skm  = skm + g2(ig) * REAL( CONJG( c( ig, ib ) ) * c( ig, ib ) ) * pmss(ig)
            END DO
            xmkin = xmkin + fi(ib) * skm * 0.5d0
          END DO

        END IF

        dft_weighted_kinene = xmkin

        RETURN
      END FUNCTION dft_weighted_kinene

!=----------------------------------------------------------------------------=!

      REAL(dbl) FUNCTION dft_kinetic_energy_s( ispin, c, cdesc, g2, fi)

!  (describe briefly what this routine does...)
!  ----------------------------------------------

        USE wave_types, ONLY: wave_descriptor
        COMPLEX(dbl), INTENT(IN) :: c(:,:)
        INTEGER, INTENT( IN ) :: ispin
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        REAL (dbl),  INTENT(IN) :: fi(:), g2(:)
        INTEGER    ib, ig, igs
        REAL(dbl)  sk1, xkin
! ... end of declarations

        xkin = 0.0d0

        IF( cdesc%nbl( ispin ) > SIZE( c, 2 ) .OR. &
            cdesc%nbl( ispin ) > SIZE( fi )        ) &
          CALL errore( ' dft_total_charge ', ' wrong sizes ', 1 )
        IF( cdesc%ngwl > SIZE( c, 1 ) .OR. &
            cdesc%ngwl > SIZE( g2 )      ) &
          CALL errore( ' dft_total_charge ', ' wrong sizes ', 2 )

        IF( cdesc%gamma .AND. cdesc%gzero ) THEN

          DO ib = 1, cdesc%nbl( ispin )
            sk1 = 0.d0
            DO ig = 2, cdesc%ngwl
              sk1 = sk1 + g2(ig) * REAL( CONJG( c(ig,ib) ) * c(ig,ib), dbl )
            END DO
            sk1  = sk1 + g2(1) * REAL( c(1,ib), dbl )**2 / 2.0d0
            xkin = xkin + fi(ib) * sk1 * 0.5d0
          END DO

        ELSE

          DO ib = 1, cdesc%nbl( ispin )
            sk1 = 0.d0
            DO ig = 1, cdesc%ngwl
              sk1 = sk1 + g2(ig) * REAL( CONJG( c(ig,ib) ) * c(ig,ib), dbl )
            END DO
            xkin = xkin + fi(ib) * sk1 * 0.5d0
          END DO

        END IF

        dft_kinetic_energy_s = xkin

        RETURN
      END FUNCTION dft_kinetic_energy_s


!=----------------------------------------------------------------------------=!

   SUBROUTINE rande_v( ispin, cm, cdesc, ampre )

!  randomize wave functions coefficients
!  then orthonormalize them

      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: rande_base

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(INOUT) :: cm(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER, INTENT(IN) :: ispin
      REAL(dbl) ampre

! ... declare other variables
      INTEGER ik

      DO ik = 1, cdesc%nkl
        call rande_base( cm(:,:,ik), ampre )
      END DO

      CALL gram( ispin, cm, cdesc )

      RETURN
   END SUBROUTINE rande_v

!=----------------------------------------------------------------------------=!

   SUBROUTINE rande_m( cm, cdesc, ampre )

!  randomize wave functions coefficients
!  then orthonormalize them
! 
      USE wave_base, ONLY: rande_base
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: force_pairing

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(INOUT) :: cm(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl) ampre

! ... declare other variables
      INTEGER :: ik, ispin, nspin

      nspin = cdesc%nspin
      IF( force_pairing ) nspin = 1

      DO ispin = 1, nspin
        DO ik = 1, cdesc%nkl
          call rande_base( cm( :, :, ik, ispin), ampre )
        END DO
      END DO

      CALL gram( cm, cdesc )

      RETURN
   END SUBROUTINE rande_m

!=----------------------------------------------------------------------------=!

   SUBROUTINE rande_s( ispin, cm, cdesc, ampre )

!  randomize wave functions coefficients
!  then orthonormalize them
!
      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: rande_base

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(INOUT) :: cm(:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER, INTENT(IN) :: ispin
      REAL(dbl) ampre

      CALL rande_base( cm(:,:), ampre )

      CALL gram( ispin, cm, cdesc )

      RETURN
   END SUBROUTINE rande_s

!=----------------------------------------------------------------------------=!

   SUBROUTINE fixwave_s ( ispin, c, cdesc, kmask )

      USE wave_types, ONLY: wave_descriptor

      IMPLICIT NONE

      COMPLEX(dbl), INTENT(INOUT) :: c(:,:)
      INTEGER, INTENT(IN) :: ispin
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) :: kmask(:)
      INTEGER :: i

        IF( .NOT. cdesc%gamma ) THEN

          IF( SIZE( c, 1 ) /= SIZE( kmask ) ) &
            CALL errore( ' fixwave_s ', ' wrong dimensions ', 3 )

          DO i = 1, cdesc%nbl( ispin )
            c(:,i) = c(:,i) * kmask(:)
          END DO

        ELSE 

          IF( cdesc%gzero ) THEN
            DO i = 1, cdesc%nbl( ispin )
              c( 1, i ) = REAL( c( 1, i ), dbl )
            END DO
          END IF

        END IF

      RETURN
   END SUBROUTINE fixwave_s

!=----------------------------------------------------------------------------=!

   SUBROUTINE fixwave_v ( ispin, c, cdesc, kmask )
      USE wave_types, ONLY: wave_descriptor
      IMPLICIT NONE
      COMPLEX(dbl), INTENT(INOUT) :: c(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) :: kmask(:,:)
      INTEGER, INTENT(IN) :: ispin
      INTEGER :: i
        DO i = 1, cdesc%nkl
          CALL fixwave_s ( ispin, c(:,:,i), cdesc, kmask(:,i) )
        END DO
      RETURN
   END SUBROUTINE fixwave_v

!=----------------------------------------------------------------------------=!

   SUBROUTINE fixwave_m ( c, cdesc, kmask )
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: force_pairing
      IMPLICIT NONE
      COMPLEX(dbl), INTENT(INOUT) :: c(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) :: kmask(:,:)
      INTEGER :: i, j, nspin
      !
      nspin = cdesc%nspin
      IF( force_pairing ) nspin = 1
      !
      DO j = 1, nspin
        DO i = 1, cdesc%nkl
          CALL fixwave_s ( j, c(:,:,i,j), cdesc, kmask(:,i) )
        END DO
      END DO
      RETURN
   END SUBROUTINE fixwave_m

!=----------------------------------------------------------------------------=!

   REAL(dbl) FUNCTION cp_kinetic_energy( ispin, cp, cm, cdesc, kp, kmask, pmss, delt)

!  (describe briefly what this routine does...)
!  if ekinc_fp will hold the full electron kinetic energy (paired and unpaired) and
!  the function returns the paired electrons' kinetic energy only
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_sum
      USE mp_global, ONLY:  group
      USE brillouin, ONLY: kpoints
      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: wave_speed2

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(IN) :: cp(:,:,:), cm(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      TYPE (kpoints), INTENT(IN) :: kp
      INTEGER, INTENT( IN ) :: ispin
      REAL(dbl), INTENT(IN) :: delt
      REAL(dbl), INTENT(IN) :: kmask(:,:)
      REAL(dbl) :: pmss(:)

! ... declare other variables
      COMPLEX(dbl) speed
      REAL(dbl)  ekinc, ekinct, dt2, fact
      INTEGER    ib, j, ik

! ... end of declarations
!  ----------------------------------------------

      ekinct  = 0.d0
      dt2     = delt * delt 

      DO ik = 1, cdesc%nkl 

        ekinc  = 0.d0
        fact   = 1.0d0
        IF( cdesc%gamma .AND. cdesc%gzero ) fact =  0.5d0

        DO ib = 1, cdesc%nbl( ispin )
          ekinc = ekinc + wave_speed2( cp(:,ib,ik),  cm(:,ib,ik), pmss, fact )
        END DO

        IF( cdesc%gamma ) ekinc = ekinc * 2.0d0

        ekinct = ekinct + kp%weight(ik) * ekinc

      END DO

      CALL mp_sum( ekinct, group )

      cp_kinetic_energy = ekinct / (4.0d0 * dt2)

      RETURN
   END FUNCTION cp_kinetic_energy

!=----------------------------------------------------------------------------=!

   SUBROUTINE gram_m( cp, cdesc )

! ... declare modules
      USE mp_global, ONLY: group
      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: gram_gamma_base, gram_kp_base
      USE control_flags, ONLY: force_pairing

      IMPLICIT NONE

! ... declare other variables
      COMPLEX(dbl), INTENT(INOUT) :: cp(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER :: ik, ispin, n, nspin

! ... end of declarations

      nspin = cdesc%nspin
      IF( force_pairing ) nspin = 1

      DO ispin = 1, nspin
        DO ik = 1, cdesc%nkl
          n = cdesc%nbl( ispin )
          IF( cdesc%gamma ) THEN
            CALL gram_gamma_base( cp( :, 1:n, ik, ispin), cdesc%gzero, group )
          ELSE
            CALL gram_kp_base( cp( :, 1:n, ik,ispin), group )
          END IF
        END DO
      END DO

      RETURN
   END SUBROUTINE gram_m

!=----------------------------------------------------------------------------=!

   SUBROUTINE gram_v( ispin, cp, cdesc )

! ... declare modules
      USE mp_global, ONLY: group
      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: gram_gamma_base, gram_kp_base

      IMPLICIT NONE

! ... declare other variables
      COMPLEX(dbl), INTENT(INOUT) :: cp(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER, INTENT(IN) :: ispin
      INTEGER :: ik
      INTEGER :: n

! ... end of declarations

      n = cdesc%nbl( ispin )

      DO ik = 1, cdesc%nkl
        IF( cdesc%gamma ) THEN
          CALL gram_gamma_base( cp( :, 1:n, ik), cdesc%gzero, group )
        ELSE
          CALL gram_kp_base( cp( :, 1:n, ik), group )
        END IF
      END DO

      RETURN
   END SUBROUTINE gram_v

!=----------------------------------------------------------------------------=!

   SUBROUTINE gram_s( ispin, cp, cdesc )

! ... declare modules
      USE mp_global, ONLY: group
      USE wave_types, ONLY: wave_descriptor
      USE wave_base, ONLY: gram_gamma_base, gram_kp_base

      IMPLICIT NONE

! ... declare other variables
      COMPLEX(dbl), INTENT(INOUT) :: cp(:,:)
      INTEGER, INTENT(IN) :: ispin
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER :: n

! ... end of declarations

      n = cdesc%nbl( ispin )

      IF( cdesc%gamma ) THEN
        CALL gram_gamma_base( cp( :, 1:n ), cdesc%gzero, group )
      ELSE
        CALL gram_kp_base( cp( :, 1:n ), group )
      END IF

      RETURN
   END SUBROUTINE gram_s

!=----------------------------------------------------------------------------=!

   SUBROUTINE update_wave_functions(cm, c0, cp, cdesc)

      USE energies, ONLY: dft_energy_type
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: force_pairing

      IMPLICIT NONE

      COMPLEX(dbl), INTENT(IN) :: cp(:,:,:,:)
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:,:)
      COMPLEX(dbl), INTENT(OUT) :: cm(:,:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc

      INTEGER :: ispin, ik, nspin

      nspin = cdesc%nspin
      IF( force_pairing ) nspin = 1
      
      DO ispin = 1, nspin
        DO ik = 1, cdesc%nkl
          cm(:,:,ik,ispin) = c0(:,:,ik,ispin)
          c0(:,:,ik,ispin) = cp(:,:,ik,ispin)
        END DO
      END DO

      RETURN
   END SUBROUTINE update_wave_functions

!=----------------------------------------------------------------------------=!

   SUBROUTINE crot_gamma ( ispin, c0, cdesc, lambda, eig )

!  this routine rotates the wave functions to the Kohn-Sham base
!  it works with a block-like distributed matrix
!  of the Lagrange multipliers ( lambda ).
!  no replicated data are used, allowing scalability for large problems.
!  the layout of lambda is as follows :
!
!  (PE 0)                 (PE 1)               ..  (PE NPE-1)
!  lambda(1      ,1:nx)   lambda(2      ,1:nx) ..  lambda(NPE      ,1:nx)
!  lambda(1+  NPE,1:nx)   lambda(2+  NPE,1:nx) ..  lambda(NPE+  NPE,1:nx)
!  lambda(1+2*NPE,1:nx)   lambda(2+2*NPE,1:nx) ..  lambda(NPE+2*NPE,1:nx)
!
!  distributes lambda's rows across processors with a blocking factor
!  of 1, ( row 1 to PE 1, row 2 to PE 2, .. row NPROC+1 to PE 1 and
!  so on).
!  nrl = local number of rows
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_bcast
      USE mp_global, ONLY: nproc, mpime, group
      USE wave_types, ONLY: wave_descriptor
      USE parallel_toolkit, ONLY: pdspev_drv, dspev_drv

      IMPLICIT NONE

! ... declare subroutine arguments
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      INTEGER, INTENT(IN) :: ispin
      REAL(dbl) :: lambda(:,:)
      REAL(dbl) :: eig(:)

! ... declare other variables
      INTEGER   ::  nx, ngw, nrl
      COMPLEX(dbl), ALLOCATABLE :: c0rot(:,:)
      REAL(dbl), ALLOCATABLE :: uu(:,:), vv(:,:)
      INTEGER   :: i, j, k, ip
      INTEGER   :: jl, nrl_ip

! ... end of declarations
!  ----------------------------------------------

      nx  = cdesc%nbl( ispin )
  
      IF( nx < 1 ) THEN
        RETURN
      END IF

      ngw = cdesc%ngwl
      nrl = SIZE(lambda, 1)
      ALLOCATE(uu(nrl,nx))
      ALLOCATE(vv(nrl,nx))
      ALLOCATE(c0rot(ngw,nx))

      c0rot = 0.0d0
      uu    = lambda

      CALL pdspev_drv( 'V', uu, nrl, eig, vv, nrl, nrl, nx, nproc, mpime)

      DEALLOCATE(uu)

      DO ip = 1, nproc

        nrl_ip = nx/nproc
        IF((ip-1).LT.mod(nx,nproc)) THEN
          nrl_ip = nrl_ip + 1
        END IF

        ALLOCATE(uu(nrl_ip,nx))
        IF(mpime.EQ.(ip-1)) THEN
          uu = vv
        END IF
        CALL mp_bcast(uu, (ip-1), group)

        j      = ip
        DO jl = 1, nrl_ip
          DO i = 1, nx
            CALL DAXPY(2*ngw,uu(jl,i),c0(1,j),1,c0rot(1,i),1)
          END DO
          j = j + nproc
        END DO
        DEALLOCATE(uu)

      END DO

      c0(:,:) = c0rot(:,:)

      DEALLOCATE(vv)
      DEALLOCATE(c0rot)

      RETURN
   END SUBROUTINE crot_gamma

!=----------------------------------------------------------------------------=!

   SUBROUTINE crot_kp ( ispin, ik, c0, cdesc, lambda, eig )

!  (describe briefly what this routine does...)
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_bcast
      USE mp_global, ONLY: nproc, mpime, group
      USE wave_types, ONLY: wave_descriptor
      USE parallel_toolkit, ONLY: pzhpev_drv, zhpev_drv

      IMPLICIT   NONE

! ... declare subroutine arguments
      INTEGER, INTENT(IN) :: ik
      INTEGER, INTENT(IN) :: ispin
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      COMPLEX(dbl)  :: lambda(:,:)
      REAL(dbl)      :: eig(:)

! ... declare other variables
      INTEGER   ngw, nx
      COMPLEX(dbl), ALLOCATABLE :: c0rot(:,:)
      COMPLEX(dbl), ALLOCATABLE :: vv(:,:)
      COMPLEX(dbl), ALLOCATABLE :: uu(:,:)
      INTEGER   i,j,jl,nrl,ip,nrl_ip

! ... end of declarations
!  ----------------------------------------------

        nx  = cdesc%nbl( ispin )

        IF( nx < 1 ) THEN
          RETURN
        END IF

        ngw = cdesc%ngwl 
        nrl = SIZE(lambda,1)

        ALLOCATE( vv(nrl, nx), c0rot(ngw, nx) )
        c0rot = (0.d0,0.d0)

        ALLOCATE(uu(nrl,nx))
        uu    = lambda
        CALL pzhpev_drv( 'V', uu, nrl, eig, vv, nrl, nrl, nx, nproc, mpime)
        DEALLOCATE(uu)

        DO ip = 1,nproc
          j = ip
          nrl_ip = nx/nproc
          IF((ip-1).LT.mod(nx,nproc)) THEN
            nrl_ip = nrl_ip + 1
          END IF
          ALLOCATE(uu(nrl_ip,nx))
          IF(mpime.EQ.(ip-1)) THEN
            uu = vv
          END IF
          CALL mp_bcast(uu, (ip-1), group)
          DO jl=1,nrl_ip
            DO i=1,nx
              CALL ZAXPY(ngw,uu(jl,i),c0(1,j,ik),1,c0rot(1,i),1)
            END DO
            j = j + nproc
          END DO
          DEALLOCATE(uu)
        END DO

        c0(:,:,ik) = c0rot(:,:)

        DEALLOCATE(c0rot, vv)

        RETURN
   END SUBROUTINE crot_kp

!=----------------------------------------------------------------------------=!

   SUBROUTINE proj_gamma( ispin, a, adesc, b, bdesc, lambda)

!  projection A=A-SUM{B}<B|A>B
!  no replicated data are used, allowing scalability for large problems.
!  The layout of lambda is as follows :
!
!  (PE 0)                 (PE 1)               ..  (PE NPE-1)
!  lambda(1      ,1:nx)   lambda(2      ,1:nx) ..  lambda(NPE      ,1:nx)
!  lambda(1+  NPE,1:nx)   lambda(2+  NPE,1:nx) ..  lambda(NPE+  NPE,1:nx)
!  lambda(1+2*NPE,1:nx)   lambda(2+2*NPE,1:nx) ..  lambda(NPE+2*NPE,1:nx)
!
!  distribute lambda's rows across processors with a blocking factor
!  of 1, ( row 1 to PE 1, row 2 to PE 2, .. row NPROC+1 to PE 1 and so on).
!  ----------------------------------------------

! ...   declare modules
        USE mp_global, ONLY: nproc,mpime,group
        USE wave_types, ONLY: wave_descriptor
        USE wave_base, ONLY: dotp

        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(dbl), INTENT(INOUT) :: a(:,:), b(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: adesc, bdesc
        REAL(dbl), OPTIONAL :: lambda(:,:)
        INTEGER, INTENT( IN ) :: ispin

! ...   declare other variables
        REAL(dbl), ALLOCATABLE :: ee(:)
        INTEGER :: i, j, ngwc, jl
        INTEGER :: nstate_a, nstate_b
        COMPLEX(dbl) :: alp

! ... end of declarations
!  ----------------------------------------------

        ngwc     = adesc%ngwl
        nstate_a = adesc%nbl( ispin )
        nstate_b = bdesc%nbl( ispin )

        IF( nstate_b < 1 ) THEN
          RETURN
        END IF

        ALLOCATE( ee( nstate_b ) )
        DO i = 1, nstate_a
          DO j = 1, nstate_b
            ee(j) = -dotp(adesc%gzero, ngwc, b(:,j), a(:,i))
          END DO
          IF( PRESENT(lambda) ) THEN
            IF( MOD( (i-1), nproc ) == mpime ) THEN
              DO j = 1, MIN( SIZE( lambda, 2 ), SIZE( ee ) )
                lambda( (i-1) / nproc + 1, j ) = ee(j)
              END DO
            END IF
          END IF
          DO j = 1, nstate_b
            alp = CMPLX(ee(j),0.0d0)
            CALL ZAXPY(ngwc,alp,b(1,j),1,a(1,i),1)
          END DO
        END DO
        DEALLOCATE(ee)

        RETURN
   END SUBROUTINE proj_gamma

!=----------------------------------------------------------------------------=!

   SUBROUTINE proj2( ispin, a, adesc, b, bdesc, c, cdesc)

!  projection A=A-SUM{B}<B|A>B-SUM{C}<C|A>
!
!  ----------------------------------------------

! ...   declare modules
        USE mp_global, ONLY: nproc,mpime,group
        USE wave_types, ONLY: wave_descriptor
        USE wave_base, ONLY: dotp

        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(dbl), INTENT(INOUT) :: a(:,:), b(:,:), c(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: adesc, bdesc, cdesc
        INTEGER, INTENT( IN ) :: ispin

! ...   declare other variables
        COMPLEX(dbl), ALLOCATABLE :: ee(:)
        INTEGER :: i, j, ngwc, jl
        INTEGER :: nstate_a, nstate_b, nstate_c

! ... end of declarations
!  ----------------------------------------------

        ngwc     = adesc%ngwl
        nstate_a = adesc%nbl( ispin )
        nstate_b = bdesc%nbl( ispin )
        nstate_c = cdesc%nbl( ispin )

        ALLOCATE( ee( MAX( nstate_b, nstate_c, 1 ) ) )

        DO i = 1, nstate_a
          DO j = 1, nstate_b
            IF( adesc%gamma ) THEN
              ee(j) = -dotp(adesc%gzero, ngwc, b(:,j), a(:,i))
            ELSE
              ee(j) = -dotp(ngwc, b(:,j), a(:,i))
            END IF
          END DO
! ...     a(:,i) = a(:,i) - (sum over j) e(i,j) b(:,j)
          DO j = 1, nstate_b
            CALL ZAXPY(ngwc, ee(j), b(1,j), 1, a(1,i), 1)
          END DO
        END DO

        DO i = 1, nstate_a
          DO j = 1, nstate_c
            IF( adesc%gamma ) THEN
              ee(j) = -dotp(adesc%gzero, ngwc, c(:,j), a(:,i))
            ELSE
              ee(j) = -dotp(ngwc, c(:,j), a(:,i))
            END IF
          END DO
          DO j = 1, nstate_c
            CALL ZAXPY(ngwc, ee(j), c(1,j), 1, a(1,i), 1)
          END DO
        END DO
        DEALLOCATE(ee)
        RETURN
   END SUBROUTINE proj2

!=----------------------------------------------------------------------------=!

   SUBROUTINE proj_kp( ispin, ik, a, adesc, b, bdesc, lambda)

!  (describe briefly what this routine does...)
!  ----------------------------------------------

! ...   declare modules
        USE mp_global, ONLY: mpime, nproc
        USE wave_types, ONLY: wave_descriptor
        USE wave_base, ONLY: dotp

        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(dbl), INTENT(INOUT) :: a(:,:,:), b(:,:,:)
        TYPE (wave_descriptor), INTENT(IN) :: adesc, bdesc
        COMPLEX(dbl), OPTIONAL  :: lambda(:,:)
        INTEGER, INTENT(IN) :: ik
        INTEGER, INTENT(IN) :: ispin

! ...   declare other variables
        COMPLEX(dbl), ALLOCATABLE :: ee(:)
        INTEGER      :: ngwc, i, j
        INTEGER      :: nstate_a, nstate_b

! ... end of declarations
!  ----------------------------------------------

        ngwc     = adesc%ngwl
        nstate_a = adesc%nbl( ispin )
        nstate_b = bdesc%nbl( ispin )

        IF( nstate_b < 1 ) THEN
          RETURN
        END IF

! ...   lambda(i,j) = b(:,i,ik) dot a(:,j,ik)
        ALLOCATE(ee(nstate_b))
        DO i = 1, nstate_a
          DO j = 1, nstate_b
            ee(j) = -dotp(ngwc, b(:,j,ik), a(:,i,ik))
          END DO
          IF( PRESENT( lambda ) ) THEN
            IF(mod((i-1),nproc).EQ.mpime) THEN
              DO j = 1, MIN( SIZE( lambda, 2 ), SIZE( ee ) )
                lambda((i-1)/nproc+1,j) = ee(j)
              END DO
            END IF
          END IF
! ...     a(:,i,ik) = a(:,i,ik) - (sum over j) lambda(i,j) b(:,j,ik)
          DO j = 1, nstate_b
            CALL ZAXPY(ngwc, ee(j), b(1,j,ik), 1, a(1,i,ik), 1)
          END DO
        END DO
        DEALLOCATE(ee)

        RETURN
   END SUBROUTINE proj_kp



   SUBROUTINE wave_rand_init( cm )

!  this routine sets the initial wavefunctions at random
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_sum
      USE mp_wave, ONLY: splitwf
      USE mp_global, ONLY: mpime, nproc, root
      USE reciprocal_vectors, ONLY: ig_l2g, ngw, ngwt, gzero
      USE io_base, ONLY: stdout
      
      IMPLICIT NONE

! ... declare module-scope variables

! ... declare subroutine arguments 
      COMPLEX(dbl), INTENT(OUT) :: cm(:,:)
      
      REAL(dbl) :: rranf
      EXTERNAL rranf

! ... declare other variables
      INTEGER :: ntest, ig, ib
      REAL(dbl) ::  rranf1, rranf2, ampre
      COMPLEX(dbl), ALLOCATABLE :: pwt( : )

! ... end of declarations
!  ----------------------------------------------

! 
! ... Check array dimensions
      IF( SIZE( cm, 1 ) < ngw ) THEN 
        CALL errore(' wave_rand_init ', ' wrong dimensions ', 3)
      END IF

! ... Reset them to zero
!
      cm = 0.0d0

! ... initialize the wave functions in such a way that the values
! ... of the components are independent on the number of processors
!

      ampre = 0.01d0
      ALLOCATE( pwt( ngwt ) )

      ntest = ngwt / 4
      IF( ntest < SIZE( cm, 2 ) ) THEN
         ntest = ngwt
      END IF
      !
      ! ... assign random values to wave functions
      !
      DO ib = 1, SIZE( cm, 2 )
        pwt( : ) = 0.0d0
        DO ig = 3, ntest
          rranf1 = 0.5d0 - rranf()
          rranf2 = rranf()
          pwt( ig ) = ampre * DCMPLX(rranf1, rranf2)
        END DO
        CALL splitwf ( cm( :, ib ), pwt, ngw, ig_l2g, mpime, nproc, 0 )
      END DO
      IF ( gzero ) THEN
        cm( 1, : ) = (0.0d0, 0.0d0)
      END IF

      DEALLOCATE( pwt )

      RETURN
    END SUBROUTINE wave_rand_init


!=----------------------------------------------------------------------------=!
   END MODULE wave_functions
!=----------------------------------------------------------------------------=!


!=----------------------------------------------------------------------------=!
   MODULE wave_constrains
!=----------------------------------------------------------------------------=!

     ! ...   include modules
     USE kinds

     IMPLICIT NONE
     SAVE

     PRIVATE

     PUBLIC :: interpolate_lambda, update_lambda

     INTERFACE update_lambda
       MODULE PROCEDURE update_rlambda, update_clambda
     END INTERFACE

!=----------------------------------------------------------------------------=!
   CONTAINS
!=----------------------------------------------------------------------------=!

     SUBROUTINE interpolate_lambda( lambdap, lambda, lambdam )
       IMPLICIT NONE
       REAL(dbl) :: lambdap(:,:), lambda(:,:), lambdam(:,:) 
       !
       ! interpolate new lambda at (t+dt) from lambda(t) and lambda(t-dt):
       !
       lambdap(:,:) = 2.d0*lambda(:,:)-lambdam(:,:)
       lambdam(:,:)=lambda (:,:)
       lambda (:,:)=lambdap(:,:)
       RETURN
     END SUBROUTINE


     SUBROUTINE update_rlambda( i, lambda, c0, cdesc, c2 )
       USE electrons_module, ONLY: ib_owner, ib_local
       USE mp_global, ONLY: mpime
       USE mp, ONLY: mp_sum
       USE wave_base, ONLY: hpsi
       USE wave_types, ONLY: wave_descriptor
       IMPLICIT NONE
       REAL(dbl) :: lambda(:,:)
       COMPLEX(dbl) :: c0(:,:), c2(:)
       TYPE (wave_descriptor), INTENT(IN) :: cdesc
       INTEGER :: i
       !
       REAL(dbl), ALLOCATABLE :: prod(:)
       INTEGER :: ibl
       !
       ALLOCATE( prod( SIZE( c0, 2 ) ) )
       prod = hpsi( cdesc%gzero, c0(:,:), c2 )
       CALL mp_sum( prod )
       IF( mpime == ib_owner( i ) ) THEN
           ibl = ib_local( i )
           lambda( ibl, : ) = prod( : )
       END IF
       DEALLOCATE( prod )
       RETURN
     END SUBROUTINE

     SUBROUTINE update_clambda( i, lambda, c0, cdesc, c2 )
       USE electrons_module, ONLY: ib_owner, ib_local
       USE mp_global, ONLY: mpime
       USE mp, ONLY: mp_sum
       USE wave_base, ONLY: hpsi
       USE wave_types, ONLY: wave_descriptor
       IMPLICIT NONE
       COMPLEX(dbl) :: lambda(:,:)
       COMPLEX(dbl) :: c0(:,:), c2(:)
       TYPE (wave_descriptor), INTENT(IN) :: cdesc
       INTEGER :: i
       !
       COMPLEX(dbl), ALLOCATABLE :: prod(:)
       INTEGER :: ibl
       !
       ALLOCATE( prod( SIZE( c0, 2 ) ) )
       prod = hpsi( cdesc%gzero, c0(:,:), c2 )
       CALL mp_sum( prod )
       IF( mpime == ib_owner( i ) ) THEN
           ibl = ib_local( i )
           lambda( ibl, : ) = prod( : )
       END IF
       DEALLOCATE( prod )
       RETURN
     END SUBROUTINE



!=----------------------------------------------------------------------------=!
   END MODULE 
!=----------------------------------------------------------------------------=!
