!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"


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
       REAL(DP) :: lambdap(:,:,:), lambda(:,:,:), lambdam(:,:,:) 
       !
       ! interpolate new lambda at (t+dt) from lambda(t) and lambda(t-dt):
       !
       lambdap= 2.d0*lambda - lambdam
       lambdam=lambda 
       lambda =lambdap
       RETURN
     END SUBROUTINE interpolate_lambda


     SUBROUTINE update_rlambda( i, lambda, c0, cdesc, c2 )
       USE electrons_module, ONLY: ib_owner, ib_local
       USE mp_global, ONLY: me_image, intra_image_comm
       USE mp, ONLY: mp_sum
       USE wave_base, ONLY: hpsi
       USE wave_types, ONLY: wave_descriptor
       IMPLICIT NONE
       REAL(DP) :: lambda(:,:)
       COMPLEX(DP) :: c0(:,:), c2(:)
       TYPE (wave_descriptor), INTENT(IN) :: cdesc
       INTEGER :: i
       !
       REAL(DP), ALLOCATABLE :: prod(:)
       INTEGER :: ibl
       !
       ALLOCATE( prod( SIZE( c0, 2 ) ) )
       prod = hpsi( cdesc%gzero, c0(:,:), c2 )
       CALL mp_sum( prod, intra_image_comm )
       IF( me_image == ib_owner( i ) ) THEN
           ibl = ib_local( i )
           lambda( ibl, : ) = prod( : )
       END IF
       DEALLOCATE( prod )
       RETURN
     END SUBROUTINE update_rlambda

     SUBROUTINE update_clambda( i, lambda, c0, cdesc, c2 )
       USE electrons_module, ONLY: ib_owner, ib_local
       USE mp_global, ONLY: me_image, intra_image_comm
       USE mp, ONLY: mp_sum
       USE wave_base, ONLY: hpsi
       USE wave_types, ONLY: wave_descriptor
       IMPLICIT NONE
       COMPLEX(DP) :: lambda(:,:)
       COMPLEX(DP) :: c0(:,:), c2(:)
       TYPE (wave_descriptor), INTENT(IN) :: cdesc
       INTEGER :: i
       !
       COMPLEX(DP), ALLOCATABLE :: prod(:)
       INTEGER :: ibl
       !
       ALLOCATE( prod( SIZE( c0, 2 ) ) )
       prod = hpsi( cdesc%gzero, c0(:,:), c2 )
       CALL mp_sum( prod, intra_image_comm )
       IF( me_image == ib_owner( i ) ) THEN
           ibl = ib_local( i )
           lambda( ibl, : ) = prod( : )
       END IF
       DEALLOCATE( prod )
       RETURN
     END SUBROUTINE update_clambda

!=----------------------------------------------------------------------------=!
   END MODULE wave_constrains
!=----------------------------------------------------------------------------=!



!=----------------------------------------------------------------------------=!
   MODULE wave_functions
!=----------------------------------------------------------------------------=!

! ...   include modules
        USE kinds

        IMPLICIT NONE
        SAVE

        PRIVATE

          PUBLIC :: crot, proj
          INTERFACE crot
            MODULE PROCEDURE  crot_gamma
          END INTERFACE
          INTERFACE proj
            MODULE PROCEDURE  proj_gamma, proj2
          END INTERFACE

          PUBLIC :: elec_fakekine
          PUBLIC :: update_wave_functions, wave_rand_init, kohn_sham

!=----------------------------------------------------------------------------=!
      CONTAINS
!=----------------------------------------------------------------------------=!



  subroutine elec_fakekine( ekincm, ema0bg, emass, c0, cm, ngw, n, noff, delt )
    !
    !  This subroutine computes the CP(fake) wave functions kinetic energy
    
    use mp,                 only : mp_sum
    use mp_global,          only : intra_image_comm
    use reciprocal_vectors, only : gstart
    use wave_base,          only : wave_speed2
    !
    integer, intent(in)      :: ngw    !  number of plane wave coeff.
    integer, intent(in)      :: n      !  number of bands
    integer, intent(in)      :: noff   !  offset for band index
    real(DP), intent(out)    :: ekincm
    real(DP), intent(in)     :: ema0bg( ngw ), delt, emass
    complex(DP), intent(in)  :: c0( ngw, n ), cm( ngw, n )
    !
    real(DP), allocatable :: emainv(:)
    real(DP) :: ftmp
    integer  :: i

    ALLOCATE( emainv( ngw ) )
    emainv = 1.0d0 / ema0bg
    ftmp = 1.0d0
    if( gstart == 2 ) ftmp = 0.5d0

    ekincm=0.0d0
    do i = noff, n + noff - 1
      ekincm = ekincm + 2.0d0 * wave_speed2( c0(:,i), cm(:,i), emainv, ftmp )
    end do
    ekincm = ekincm * emass / ( delt * delt )

    CALL mp_sum( ekincm, intra_image_comm )
    DEALLOCATE( emainv )

    return
  end subroutine elec_fakekine

!=----------------------------------------------------------------------------=!
!=----------------------------------------------------------------------------=!

   SUBROUTINE update_wave_functions(cm, c0, cp, cdesc)

      USE energies, ONLY: dft_energy_type
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: force_pairing

      IMPLICIT NONE

      COMPLEX(DP), INTENT(IN) :: cp(:,:,:)
      COMPLEX(DP), INTENT(INOUT) :: c0(:,:,:)
      COMPLEX(DP), INTENT(OUT) :: cm(:,:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc

      INTEGER :: ispin, nspin

      nspin = cdesc%nspin
      IF( force_pairing ) nspin = 1
      
      DO ispin = 1, nspin
         cm(:,:,ispin) = c0(:,:,ispin)
         c0(:,:,ispin) = cp(:,:,ispin)
      END DO

      RETURN
   END SUBROUTINE update_wave_functions

!=----------------------------------------------------------------------------=!

   SUBROUTINE crot_gamma ( c0, ngwl, nx, lambda, nrl, eig )

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
!  of 1, ( row 1 to PE 1, row 2 to PE 2, .. row nproc_image+1 to PE 1 and
!  so on).
!  nrl = local number of rows
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_bcast
      USE mp_global, ONLY: nproc_image, me_image, intra_image_comm
      USE wave_types, ONLY: wave_descriptor
      USE parallel_toolkit, ONLY: pdspev_drv, dspev_drv

      IMPLICIT NONE

! ... declare subroutine arguments
      INTEGER, INTENT(IN) :: ngwl, nx, nrl
      COMPLEX(DP), INTENT(INOUT) :: c0(:,:)
      REAL(DP) :: lambda(:,:)
      REAL(DP) :: eig(:)

! ... declare other variables
      COMPLEX(DP), ALLOCATABLE :: c0rot(:,:)
      REAL(DP), ALLOCATABLE :: uu(:,:), vv(:,:), ap(:)
      INTEGER   :: i, j, k, ip
      INTEGER   :: jl, nrl_ip

! ... end of declarations
!  ----------------------------------------------

      IF( nx < 1 ) THEN
        RETURN
      END IF

      ALLOCATE( vv( nrl, nx ) )
      ALLOCATE( c0rot( ngwl, nx ) )

      c0rot = 0.0d0

      IF( nrl /= nx ) THEN

         ! Distributed lambda

         ALLOCATE( uu( nrl, nx ) )

         uu    = lambda

         CALL pdspev_drv( 'V', uu, nrl, eig, vv, nrl, nrl, nx, nproc_image, me_image)

         DEALLOCATE(uu)

         DO ip = 1, nproc_image

            nrl_ip = nx/nproc_image
            IF((ip-1).LT.mod(nx,nproc_image)) THEN
              nrl_ip = nrl_ip + 1
            END IF
 
            ALLOCATE(uu(nrl_ip,nx))
            IF(me_image.EQ.(ip-1)) THEN
              uu = vv
            END IF
            CALL mp_bcast(uu, (ip-1), intra_image_comm)
 
            j      = ip
            DO jl = 1, nrl_ip
              DO i = 1, nx
                CALL DAXPY(2*ngwl,uu(jl,i),c0(1,j),1,c0rot(1,i),1)
              END DO
              j = j + nproc_image
            END DO
            DEALLOCATE(uu)
 
         END DO

      ELSE

         ! NON distributed lambda

         ALLOCATE( ap( nx * ( nx + 1 ) / 2 ) )

         K = 0
         DO J = 1, nx
            DO I = J, nx
               K = K + 1
               ap( k ) = lambda( i, j )
            END DO
          END DO

         CALL dspev_drv( 'V', 'L', nx, ap, eig, vv, nx )

         DEALLOCATE( ap )

         DO j = 1, nrl
            DO i = 1, nx
               CALL DAXPY( 2*ngwl, vv(j,i), c0(1,j), 1, c0rot(1,i), 1 )
            END DO
         END DO

      END IF

      c0(:,:) = c0rot(:,:)

      DEALLOCATE( vv )
      DEALLOCATE( c0rot )

      RETURN
   END SUBROUTINE crot_gamma


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
!  of 1, ( row 1 to PE 1, row 2 to PE 2, .. row nproc_image+1 to PE 1 and so on).
!  ----------------------------------------------

! ...   declare modules
        USE mp_global, ONLY: nproc_image,me_image,intra_image_comm
        USE wave_types, ONLY: wave_descriptor
        USE wave_base, ONLY: dotp

        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(DP), INTENT(INOUT) :: a(:,:), b(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: adesc, bdesc
        REAL(DP), OPTIONAL :: lambda(:,:)
        INTEGER, INTENT( IN ) :: ispin

! ...   declare other variables
        REAL(DP), ALLOCATABLE :: ee(:)
        INTEGER :: i, j, ngwc, jl
        INTEGER :: nstate_a, nstate_b
        COMPLEX(DP) :: alp

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
            IF( MOD( (i-1), nproc_image ) == me_image ) THEN
              DO j = 1, MIN( SIZE( lambda, 2 ), SIZE( ee ) )
                lambda( (i-1) / nproc_image + 1, j ) = ee(j)
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
        USE mp_global, ONLY: nproc_image,me_image,intra_image_comm
        USE wave_types, ONLY: wave_descriptor
        USE wave_base, ONLY: dotp

        IMPLICIT NONE

! ...   declare subroutine arguments
        COMPLEX(DP), INTENT(INOUT) :: a(:,:), b(:,:), c(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: adesc, bdesc, cdesc
        INTEGER, INTENT( IN ) :: ispin

! ...   declare other variables
        COMPLEX(DP), ALLOCATABLE :: ee(:)
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



   SUBROUTINE wave_rand_init( cm )

!  this routine sets the initial wavefunctions at random
!  ----------------------------------------------

! ... declare modules
      USE mp, ONLY: mp_sum
      USE mp_wave, ONLY: splitwf
      USE mp_global, ONLY: me_image, nproc_image, root_image, intra_image_comm
      USE reciprocal_vectors, ONLY: ig_l2g, ngw, ngwt, gzero
      USE io_global, ONLY: stdout
      USE random_numbers, ONLY : rranf
      
      IMPLICIT NONE

! ... declare module-scope variables

! ... declare subroutine arguments 
      COMPLEX(DP), INTENT(OUT) :: cm(:,:)

! ... declare other variables
      INTEGER :: ntest, ig, ib
      REAL(DP) ::  rranf1, rranf2, ampre
      COMPLEX(DP), ALLOCATABLE :: pwt( : )

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
          pwt( ig ) = ampre * CMPLX(rranf1, rranf2)
        END DO
        CALL splitwf ( cm( :, ib ), pwt, ngw, ig_l2g, me_image, nproc_image, root_image, intra_image_comm )
      END DO
      IF ( gzero ) THEN
        cm( 1, : ) = (0.0d0, 0.0d0)
      END IF

      DEALLOCATE( pwt )

      RETURN
    END SUBROUTINE wave_rand_init



   SUBROUTINE kohn_sham(ispin, c, cdesc, eforces, nupdwn, nupdwnl )
        !
        ! ...   declare modules

        USE kinds
        USE wave_constrains,  ONLY: update_lambda
        USE wave_types,       ONLY: wave_descriptor

        IMPLICIT NONE

        ! ...   declare subroutine arguments
        COMPLEX(DP), INTENT(INOUT) ::  c(:,:)
        TYPE (wave_descriptor), INTENT(IN) :: cdesc
        INTEGER, INTENT(IN) :: ispin
        INTEGER, INTENT(IN) :: nupdwn(:)   ! number of upper and down states
        INTEGER, INTENT(IN) :: nupdwnl(:)  ! local (to the processor) number of up and down states
        COMPLEX(DP) :: eforces(:,:)

        ! ...   declare other variables
        INTEGER ::  ib, nb_g, nrl
        REAL(DP),    ALLOCATABLE :: gam(:,:)
        REAL(DP),    ALLOCATABLE :: eig(:)
        LOGICAL :: tortho = .TRUE.

        ! ...   end of declarations

        nb_g = nupdwn( ispin )
        nrl  = nupdwnl( ispin )

        IF( nb_g < 1 ) THEN

           eforces = 0.0d0

        ELSE

           ALLOCATE( eig( nb_g ) )
           ALLOCATE( gam( nrl, nb_g ) )

           DO ib = 1, nb_g
              CALL update_lambda( ib, gam, c(:,:), cdesc, eforces(:,ib) )
           END DO
           CALL crot( c(:,:), cdesc%ngwl, nupdwn(ispin), gam, nupdwnl(ispin), eig )

           DEALLOCATE( gam, eig )

        END IF

        RETURN
        ! ...
   END SUBROUTINE kohn_sham


!=----------------------------------------------------------------------------=!
   END MODULE wave_functions
!=----------------------------------------------------------------------------=!

