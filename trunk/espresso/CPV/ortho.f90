!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"

!=----------------------------------------------------------------------------=!
     MODULE orthogonalize
!=----------------------------------------------------------------------------=!

       USE kinds
       USE io_global, ONLY: ionode
       USE parallel_toolkit, ONLY: matmulp, cmatmulp, &
         pdspev_drv, dspev_drv, pzhpev_drv, zhpev_drv
       USE orthogonalize_base, ONLY: sqr_matmul, sigset, rhoset, diagonalize_rho, &
         BACKRHOSET, SIGRHOSET, BACKRHOSET2, SIGRHOSET2
       USE control_flags, ONLY: timing

       IMPLICIT NONE

       SAVE

       PRIVATE

       INTEGER :: ortho_tune = 16

       REAL(dbl) :: one, zero, two, mone, mtwo
       PARAMETER ( one = 1.0d0, zero = 0.0d0, two = 2.0d0, mone = -1.0d0 )
       PARAMETER ( mtwo = -2.0d0 )
       COMPLEX(dbl) :: cone, czero, mcone
       PARAMETER ( cone = (1.0d0, 0.0d0), czero = (0.0d0, 0.0d0) )
       PARAMETER ( mcone = (-1.0d0, 0.0d0) )
       REAL(dbl) :: small = 1.0d-14

       REAL(dbl) :: timrhos = 0.0d0
       REAL(dbl) :: timsigs = 0.0d0
       REAL(dbl) :: timdiag = 0.0d0
       REAL(dbl) :: timtras1 = 0.0d0
       REAL(dbl) :: timiter = 0.0d0
       REAL(dbl) :: timbtra = 0.0d0
       REAL(dbl) :: timtot = 0.0d0
       INTEGER   :: timcnt = 0

       REAL(dbl) :: cclock
       EXTERNAL  :: cclock

       INTERFACE ortho
         MODULE PROCEDURE ortho_s, ortho_v, ortho_m
       END INTERFACE

       PUBLIC :: ortho, orthogonalize_info
       PUBLIC :: print_ortho_time

!=----------------------------------------------------------------------------=!
     CONTAINS
!=----------------------------------------------------------------------------=!


       SUBROUTINE orthogonalize_info( unit )
         USE control_flags, ONLY: ortho_eps, ortho_max
         INTEGER, INTENT(IN) :: unit
           WRITE(unit,585)
           WRITE(unit,511) ortho_eps, ortho_max
         RETURN
  511    FORMAT(   3X,'Orthog. with lagrange multipliers : eps = ',E10.2 &
                  ,',  max = ',I3)
  585    FORMAT(   3X,'Eigenvalues calculated without the kinetic term ' &
                  ,'contribution')
       END SUBROUTINE

!=----------------------------------------------------------------------------=!

       SUBROUTINE ortho_s( ispin, c0, cp, cdesc, pmss, emass, success)

         USE control_flags, ONLY: ortho_eps, ortho_max
         USE wave_types, ONLY: wave_descriptor
         USE mp_global, ONLY: nproc

         COMPLEX(dbl), INTENT(INOUT) :: c0(:,:), cp(:,:)
         TYPE (wave_descriptor), INTENT(IN) :: cdesc
         REAL(dbl) :: pmss(:), emass
         LOGICAL, INTENT(OUT), OPTIONAL :: success
         INTEGER, INTENT(IN) :: ispin
         INTEGER :: iter

           IF( cdesc%gamma ) THEN
#if defined __SCALAPACK
             iter = ortho_scalapack( ispin, c0, cp, cdesc, pmss, emass)
#else
             IF( ( nproc > 1 ) .AND. ( ( cdesc%nbt( ispin ) / nproc ) >= ortho_tune ) ) THEN
               iter = ortho_gamma_p( ispin, c0, cp, cdesc, pmss, emass)
             ELSE
               iter = ortho_gamma( ispin, c0, cp, cdesc, pmss, emass)
             END IF
#endif
           ELSE
             iter = ortho_kp(c0, cp, pmss, emass)
           END IF

           IF( PRESENT( success ) ) THEN
             success = .TRUE.
           END IF
           IF ( iter > ortho_max ) THEN
             IF( PRESENT( success ) ) THEN
               success = .FALSE.
             ELSE
               call errore(' ortho ','  itermax ',iter)
             END IF
           END IF
         RETURN
       END SUBROUTINE ortho_s

!=----------------------------------------------------------------------------=!

       SUBROUTINE ortho_v( ispin, c0, cp, cdesc, pmss, emass)
         USE wave_types, ONLY: wave_descriptor
         COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:), cp(:,:,:)
         TYPE (wave_descriptor), INTENT(IN) :: cdesc
         REAL(dbl) :: pmss(:), emass
         INTEGER, INTENT(IN) :: ispin
         INTEGER :: ik
         DO ik = 1, cdesc%nkl
           CALL ortho_s( ispin, c0(:,:,ik), cp(:,:,ik), cdesc, pmss, emass)
         END DO
         RETURN
       END SUBROUTINE ortho_v

!=----------------------------------------------------------------------------=!

       SUBROUTINE ortho_m(c0, cp, cdesc, pmss, emass)
         USE wave_types, ONLY: wave_descriptor
         USE control_flags, ONLY: force_pairing
         COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:,:), cp(:,:,:,:)
         TYPE (wave_descriptor), INTENT(IN) :: cdesc
         REAL(dbl) :: pmss(:), emass
         INTEGER :: ik, ispin, nspin
         nspin = cdesc%nspin
         IF( force_pairing ) nspin = 1
         DO ispin = 1, nspin
           DO ik = 1, cdesc%nkl
             CALL ortho_s( ispin, c0(:,:, ik, ispin), cp(:,:,ik, ispin), cdesc, pmss, emass)
           END DO
         END DO
         RETURN
       END SUBROUTINE ortho_m


!=----------------------------------------------------------------------------=!
!  BEGIN manual

      INTEGER FUNCTION ortho_gamma( ispin, c0, cp, cdesc, pmss, emass )

! INPUT:
!       C0 (ORTHONORMAL)
!       CP (NON-ORTHONORMAL)
! OUTPUT:
!       CP (ORTHONORMAL)
!
! Version for preconditioned equations of motion
! (following f.tassone, f.mauri and r.car ...)
! Replicated data parallel driver
!  ----------------------------------------------
!  END manual

#if defined __SHMEM

      USE shmem_include

#endif

      USE mp_global, ONLY: nproc, mpime
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: ortho_eps, ortho_max

      IMPLICIT  NONE

! ... Arguments
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:), cp(:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) ::  pmss(:), emass
      INTEGER, INTENT(IN) :: ispin
      
! ... Functions
      INTEGER :: IDAMAX 
  
! ... Locals

#if defined __SHMEM
      INTEGER         :: err
      REAL(dbl)       :: s(SIZE(c0,2), SIZE(c0,2)),                     &
     &                   sig(SIZE(c0,2), SIZE(c0,2)),                   &
     &                   rho(SIZE(c0,2), SIZE(c0,2)),                   &
     &                   tmass(SIZE(c0,2), SIZE(c0,2)),                 &
     &                   temp(SIZE(c0,2), SIZE(c0,2))
      POINTER            (p_source,s), (p_sig,sig), (p_rho,rho),        &
     &                   (p_tmass,tmass), (p_target,TEMP)
      COMMON /sym_heap3/ p_source, p_sig, p_rho, p_tmass, p_target
#else
      REAL(dbl),   ALLOCATABLE :: s(:,:), sig(:,:), rho(:,:), tmass(:,:), temp(:,:)
#endif
      REAL(dbl),   ALLOCATABLE :: x0(:,:), temp1(:,:)
      REAL(dbl),   ALLOCATABLE :: x1(:,:), rhoa(:,:)
      REAL(dbl),   ALLOCATABLE :: sigd(:), rhod(:), aux(:)
      REAL(dbl)                :: pwrk(1) 
      REAL(dbl) :: difgam, rhosigd
      REAL(dbl) :: s0, s1, s2, s3, s4, s5, s6, s7, s8, s9
      REAL(dbl) :: fact, one_by_emass, den
      INTEGER   :: nrl,is,jl, n, ngw, nx, naux, i, j, iopt, k, info, iter
      LOGICAL   :: gzero
      REAL(dbl) :: sqrtfact

! ...   Subroutine body

      IF(timing) s1 = cclock()

      n   = cdesc%nbl( ispin )
      nx  = cdesc%nbl( ispin )
      ngw = cdesc%ngwl

      IF( n < 1 ) THEN
        ortho_gamma = 0
        RETURN
      END IF

#if defined __SHMEM
      CALL shpalloc(p_source, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' allocation of source failed ', 0)
      END IF
      CALL shpalloc(p_sig, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' allocation of sig failed ', 0)
      END IF
      CALL shpalloc(p_rho, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' allocation of rho failed ', 0)
      END IF
      CALL shpalloc(p_tmass, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' allocation of tmass failed ', 0)
      END IF
      CALL shpalloc(p_target, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' allocation of target failed ', 0)
      END IF
#else
      ALLOCATE( s(n,n), sig(n,n), rho(n,n), tmass(n,n), temp(n,n), STAT = info )
#endif
      IF( info /= 0 ) CALL errore( ' ortho ', ' allocating matrixes ', 1 )
      ALLOCATE( x0(n,n), x1(n,n), rhoa(n,n), temp1(n,n), sigd(n), rhod(n), STAT = info )
      IF( info /= 0 ) CALL errore( ' ortho ', ' allocating matrixes ', 2 )

! ...   Scale wave functions

      ALLOCATE( aux( ngw ) )
      aux(:) = emass / pmss(:) 
      sqrtfact = 1.0d0 / SQRT( 2.0d0 )
      IF( cdesc%gzero ) THEN
        aux(1)    = aux(1)    * sqrtfact
        cp(1, 1:n ) = cp(1, 1:n ) * sqrtfact
      END IF
      DO i = 1, n
        c0(:,i) = c0(:,i) * aux(:)
      END DO
      DEALLOCATE( aux )

! ...   Initialize rho and sig

      !WRITE(6,*) 'ORTHO DEBUG c0= ', SUM( c0 )  ! DEBUG
      !WRITE(6,*) 'ORTHO DEBUG cp= ', SUM( cp )  ! DEBUG

      CALL rhoset( ngw, n, c0( :, : ) , cp( :, : ), rho, tmass, pwrk)
      IF(timing) s2 = cclock()
      CALL sigset( ngw, n, cp( :, : ), SIG, PWRK)
      IF(timing) S3 = cclock()


      call mytranspose(rho, nx, temp1, NX, N, N)
      DO j = 1, n
        DO i = 1, n
          rhoa(i,j) = 0.5d0*(rho(i,j)-temp1(i,j))
          temp(i,j) = 0.5d0*(rho(i,j)+temp1(i,j))
        ENDDO
      ENDDO

! ...   Diagonalize Matrix  symmetric part of rho
! ...   temp = ( rho(i,j) + rho(j,i) ) / 2

      !WRITE(6,*) 'ORTHO DEBUG temp= ', SUM( temp )  ! DEBUG

      CALL diagonalize_rho( temp, rhod, s, pwrk )

! ...   "s" is the matrix of eigenvectors, "rhod" is the array of eigenvalues

      IF(timing) S4 = cclock()

      ! WRITE(6,*) ' ORTHO RHOD ',  RHOD(1),RHOD(2) ! DEBUG
      ! WRITE(6,*) ' ORTHO S ',  SUM(S), SUM(RHOD) ! DEBUG
      ! WRITE(6,*) ' ORTHO SIG ',  SUM(SIG) ! DEBUG

!
! ...   Transform "sig", "rhoa" and "tmass" in the new basis through matrix "s"
!
      CALL sqr_matmul( 'N', 'N', SIG, S, TEMP )
      CALL sqr_matmul( 'T', 'N', S, TEMP, SIG )
      CALL sqr_matmul( 'N', 'N', RHOA, S, TEMP )
      CALL sqr_matmul( 'T', 'N', S, TEMP, RHOA )
      CALL sqr_matmul( 'N', 'N', TMASS, S, TEMP )
      CALL sqr_matmul( 'T', 'N', S, TEMP, TMASS )

      IF(timing) S5 = cclock()
!
! ...   Initialize x0
!
      DO J = 1, N
        DO I = 1, N
          den = (RHOD(I)+RHOD(J))
          IF( ABS( den ) <= small ) den = SIGN( small, den )
          X0(I,J) = SIG(I,J) / den
        ENDDO
      ENDDO

      !WRITE(6,*) ' ORTHO X0 ',  SUM(X0) ! DEBUG
!
! ...   Starting iteration
!

      ITERATIVE_LOOP: DO iter = 0, ortho_max

        ! WRITE(6,*) ' ORTHO LOOP 1 ', SUM(X0) ! DEBUG

        CALL sqr_matmul( 'N', 'N', X0, RHOA, TEMP1 )
        call mytranspose( TEMP1, NX, TEMP, NX, N, N )
        DO J=1,N
          DO I=1,N
            TEMP1(I,J) = TEMP1(I,J) + TEMP(I,J)
          ENDDO
        ENDDO
!
        CALL sqr_matmul( 'T', 'N', TMASS, X0, TEMP )
        DO I = 1, N
          SIGD(I)   =  TEMP(I,I)
          TEMP(I,I) = -SIGD(I)
        ENDDO

        CALL sqr_matmul( 'T', 'N', X0, TEMP, X1 )
        call mytranspose( X1, NX, TEMP, NX, N, N )

! ...     X1   = SIG - TEMP1 - 0.5d0 * ( X1 + X1^t )

        difgam = zero
        DO j = 1, n
          DO i = 1, n        
            den = (rhod(i)+sigd(i)+rhod(j)+sigd(j))
            IF( ABS( den ) <= small ) den = SIGN( small, den )
            x1(i,j) = sig(i,j) - temp1(i,j) - 0.5_dbl * (x1(i,j)+temp(i,j))
            x1(i,j) = x1(i,j) / den
            difgam = MAX( ABS(x1(i,j)-x0(i,j)), difgam )
          END DO
        END DO      

        IF( difgam < ortho_eps ) EXIT ITERATIVE_LOOP
        x0 = x1

      END DO ITERATIVE_LOOP


      IF(timing) S6 = cclock()
!
! ...   Transform x1 back to the original basis

      CALL sqr_matmul( 'N', 'N', S, X1, TEMP )
      CALL sqr_matmul( 'N', 'T', S, TEMP, X1 )

      !WRITE(6,*) ' ORTHO CP a  ',  SUM(CP) ! DEBUG
!
      CALL DGEMM( 'N', 'N', 2*ngw, n, n, one, c0(1,1), 2*SIZE(c0,1), x1(1,1), n, &
        one, cp(1,1), 2*SIZE(cp,1) )

      !WRITE(6,*) ' ORTHO CP b  ',  SUM(CP) ! DEBUG
!
! ...   Restore wave functions
!
      ALLOCATE( aux( ngw ) )
      aux(:)   = pmss(:) / emass
      sqrtfact = SQRT( 2.0d0 )
      IF( cdesc%gzero ) THEN
        aux(1)    = aux(1)    * sqrtfact
        cp(1, 1:n ) = cp(1, 1:n ) * sqrtfact
      END IF
      DO i = 1, n
        c0(:,i) = c0(:,i) * aux(:)
      END DO
      DEALLOCATE( aux )

      DEALLOCATE(x0, x1, rhoa, temp1, sigd, rhod)
#if defined __SHMEM
      CALL shpdeallc(p_source, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' deallocation of source failed ', 0)
      END IF
      CALL shpdeallc(p_sig, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' deallocation of sig failed ', 0)
      END IF
      CALL shpdeallc(p_rho, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' deallocation of rho failed ', 0)
      END IF
      CALL shpdeallc(p_tmass, 2*n*n, err, -1)
      IF (err .NE. 0) THEN
         CALL errore( ' ortho ', ' deallocation of tmass failed ', 0)
      END IF
      CALL shpdeallc(p_target, 2*n*n, err, -1)
      IF (err .NE. 0) THEN 
         CALL errore( ' ortho ', ' deallocation of target failed ', 0)
      END IF
#else
      DEALLOCATE(s, sig, rho, tmass, temp )
#endif

      IF(timing) THEN
        S7 = cclock()
        timrhos  = (s2 - s1) + timrhos
        timsigs  = (s3 - s2) + timsigs
        timdiag  = (s4 - s3) + timdiag
        timtras1 = (s5 - s4) + timtras1
        timiter  = (s6 - s5) + timiter
        timbtra  = (s7 - s6) + timbtra
        timtot   = (s7 - s1) + timtot
        timcnt = timcnt + 1
      END IF


      ortho_gamma = iter
      RETURN
      END FUNCTION

!=----------------------------------------------------------------------------=!
!  BEGIN manual

      INTEGER FUNCTION ortho_gamma_p( ispin, c0, cp, cdesc, pmss, emass )

! INPUT:
!       C0 (ORTHONORMAL)
!       CP (NON-ORTHONORMAL)
! OUTPUT:
!       CP (ORTHONORMAL)
!
! Version for preconditioned equations of motion
! (following f.tassone, f.mauri and r.car ...)
! Distributed data parallel driver
!  ----------------------------------------------
!  END manual

      USE parallel_types, ONLY: processors_grid, descriptor, &
       real_parallel_matrix, parallel_allocate, parallel_deallocate, &
       BLOCK_CYCLIC_SHAPE, CYCLIC_SHAPE, REPLICATED_DATA_SHAPE
      USE descriptors_module, ONLY: desc_init
      USE processors_grid_module, ONLY: grid_init
      USE mp_global, ONLY: nproc, mpime, group
      USE mp, ONLY: mp_sum
      USE wave_types, ONLY: wave_descriptor
      USE control_flags, ONLY: ortho_eps, ortho_max

      IMPLICIT  NONE

! ... Arguments
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:), cp(:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL(dbl), INTENT(IN) ::  pmss(:), emass
      INTEGER, INTENT(IN) :: ispin
      
! ... Functions
      INTEGER IDAMAX 
  
! ... Locals

      REAL(dbl), ALLOCATABLE :: S(:,:), TEMP(:,:)
      REAL(dbl), ALLOCATABLE :: x0(:,:), temp1(:,:)
      REAL(dbl), ALLOCATABLE :: x1(:,:), rhoa(:,:)
      REAL(dbl), ALLOCATABLE :: sigd(:), rhod(:), aux(:)
      REAL(dbl) :: DIFGAM, RHOSIGD
      REAL(dbl) :: s0, s1, s2, s3, s4, s5, s6, s7, s8, s9
      REAL(dbl) :: fact, den
      integer   :: nrl, n, ngw, I, ii, J, K, ITER

      TYPE (real_parallel_matrix) :: sigt, rhot, tmasst
      TYPE (processors_grid) :: grid
      TYPE (descriptor), POINTER :: desc

! ... Subroutine body

      IF(timing) s1 = cclock()

      n   = cdesc%nbl( ispin )

      IF( n < 1 ) THEN
        ortho_gamma_p = 0
        RETURN
      END IF

      ngw = cdesc%ngwl
      nrl = n/nproc
      IF( mpime < MOD(n,nproc) ) THEN
        nrl = nrl + 1
      end if

      ALLOCATE( desc )

      CALL grid_init(grid, group, nproc , mpime, nproc, 1, 1, mpime, 0, 0)
      CALL desc_init(desc, 1, n, n, 1, n, 0, 0, grid, CYCLIC_SHAPE, REPLICATED_DATA_SHAPE, nrl)

      ALLOCATE( s(nrl, n), temp(nrl, n), x0(nrl, n), temp1(nrl, n), x1(nrl, n), rhoa(nrl, n) )
      ALLOCATE( rhod(n), sigd(n) )

      CALL parallel_allocate(sigt, desc)
      CALL parallel_allocate(tmasst, desc)
      CALL parallel_allocate(rhot, desc)

!.....INITIALIZE RHO AND SIG

      CALL SIGRHOSET2( ngw, n, CP(:,:), C0(:,:), SIGT, RHOT, TMASST, PMSS, EMASS, cdesc%gzero)
      IF(timing) s2 = cclock()
      CALL mytrasp_dati(rhot%m, SIZE(rhot%m,1), 'R', temp1, nrl, 'R', n, mpime, nproc)
      IF(timing) s3 = cclock()

      DO j = 1, N
        DO i = 1, nrl
          rhoa(i,j)  = 0.5d0*(rhot%m(i,j)-temp1(i,j))
          temp(i,j)  = 0.5d0*(rhot%m(i,j)+temp1(i,j))
        ENDDO
      ENDDO

      CALL pdspev_drv( 'V', temp, nrl, rhod, s, nrl, nrl, n, nproc, mpime)

      IF(timing) S4 = cclock()
!
! ... TRANSFORM SIG, RHOA AND TMASS IN THE NEW BASIS THROUGH MATRIX S
!
      CALL mymatmul(sigt%m, nrl, 'N', 'R', s, nrl, 'N', 'R', temp, nrl, 'R', n, mpime, nproc)
      CALL mymatmul(s, nrl, 'T', 'R', temp, nrl, 'N', 'R', sigt%m, nrl, 'R', n, mpime, nproc)

      CALL mymatmul(rhoa, nrl, 'N', 'R', s, nrl, 'N', 'R', temp, nrl, 'R', n, mpime, nproc)
      CALL mymatmul(s, nrl, 'T', 'R', temp, nrl, 'N', 'R', rhoa, nrl, 'R', n, mpime, nproc)

      CALL mymatmul(tmasst%m, nrl, 'N', 'R', s, nrl, 'N', 'R', temp, nrl, 'R', n, mpime, nproc)
      CALL mymatmul(s, nrl, 'T', 'R', temp, nrl, 'N', 'R', tmasst%m, nrl, 'R', n, mpime, nproc)

      IF(timing) S5 = cclock()
!
! ... INITIALIZE X0
!
      DO J = 1, N
        ii = mpime + 1
        DO I = 1, nrl
          den = (RHOD(ii)+RHOD(j))
          IF( ABS( den ) <= small ) den = SIGN( small, den )
          X0(I,J) = SIGT%M(I,J) / den
          ii = ii + nproc
        ENDDO
      ENDDO

      !WRITE(6,*) ' ORTHO X0 ',  SUM(X0) ! DEBUG
!
! ... STARTING ITERATION
!

      ITERATIVE_LOOP: DO iter = 0, ortho_max

        CALL mymatmul(x0, nrl, 'N', 'R', rhoa, nrl, 'N', 'R', temp1, nrl, 'R', n, mpime, nproc)
        CALL mytrasp_dati(temp1, nrl, 'R', temp, nrl, 'R', n, mpime, nproc)
        DO J=1,N
          DO I=1,nrl
            TEMP1(I,J) = TEMP1(I,J) + TEMP(I,J)
          ENDDO
        ENDDO
!
        CALL mymatmul(tmasst%m, nrl, 'T', 'R', x0, nrl, 'N', 'R', temp, nrl, 'R', n, mpime, nproc)
        sigd = 0.0d0
        ii = mpime + 1
        DO I=1,nrl
          SIGD(ii)   =  TEMP(i,ii)
          TEMP(i,ii) = -SIGD(ii)
          ii = ii + nproc
        ENDDO
        CALL mp_sum(sigd)

        CALL mymatmul(x0, nrl, 'T', 'R', temp, nrl, 'N', 'R', x1, nrl, 'R', n, mpime, nproc)
        CALL mytrasp_dati(x1, nrl, 'R', temp, nrl, 'R', n, mpime, nproc)

! ...   X1   = SIG - TEMP1 - 0.5d0 * ( X1 + X1^t )

        difgam = zero
        DO j = 1, n
          ii = mpime + 1
          DO i = 1, nrl
            den = (rhod(ii)+sigd(ii)+rhod(j)+sigd(j))
            IF( ABS( den ) <= small ) den = SIGN( small, den )
            x1(i,j) = sigt%m(i,j) - temp1(i,j) - 0.5_dbl * (x1(i,j)+temp(i,j))
            x1(i,j) = x1(i,j) / den
            difgam = MAX( ABS(x1(i,j)-x0(i,j)), difgam )
            ii = ii + nproc
          END DO
        END DO      

        CALL mp_sum(difgam)

        IF(difgam .LE. ortho_eps) EXIT ITERATIVE_LOOP
        x0 = x1

      END DO ITERATIVE_LOOP


      IF(timing) S6 = cclock()
!
! ... TRANSFORM X1 BACK TO THE ORIGINAL BASIS

      CALL mymatmul(s, nrl, 'N', 'R', x1, nrl, 'N', 'R', temp, nrl, 'R', n, mpime, nproc)
      CALL mymatmul(s, nrl, 'N', 'R', temp, nrl, 'T', 'R', sigt%m, nrl, 'R', n, mpime, nproc)

      !WRITE(6,*) ' ORTHO CP a  ',  SUM(CP) ! DEBUG

!.....RESTORE C0
!
      CALL backrhoset2( ngw, n, CP(:,:), C0(:,:), sigt, PMSS, EMASS)
!
      !WRITE(6,*) ' ORTHO CP c  ',  SUM(CP) ! DEBUG

      DEALLOCATE( s, temp, x0, temp1, x1, rhoa, rhod, sigd )
      CALL parallel_deallocate(sigt)
      CALL parallel_deallocate(tmasst)
      CALL parallel_deallocate(rhot)
      DEALLOCATE( desc )

      IF(timing) THEN
        S7 = cclock()
        timrhos  = (s2 - s1) + timrhos
        timsigs  = (s3 - s2) + timsigs
        timdiag  = (s4 - s3) + timdiag
        timtras1 = (s5 - s4) + timtras1
        timiter  = (s6 - s5) + timiter
        timbtra  = (s7 - s6) + timbtra
        timtot   = (s7 - s1) + timtot
        timcnt = timcnt + 1
      END IF

      ortho_gamma_p = iter
      RETURN
      END FUNCTION


!=----------------------------------------------------------------------------=!
!  BEGIN manual

      INTEGER FUNCTION ortho_kp(C0,CP,PMSS,EMASS)

! INPUT:
!       C0 (ORTHONORMAL)
!       CP (NON-ORTHONORMAL)
! OUTPUT:
!       X1 = DT2/EMASS * LAMBDA
!       CP (ORTHONORMAL)
!
! Version for preconditioned equations of motion
! (following f.tassone, f.mauri and r.car ...)
! Replicated data parallel driver for complex wave functions
!----------------------------------------------------------------------!
!  END manual

#if defined __SHMEM

      USE shmem_include

#endif

      USE control_flags, ONLY: ortho_eps, ortho_max
 
      IMPLICIT  NONE


! ... Arguments
      COMPLEX(dbl) ::  C0(:,:), CP(:,:)
      REAL(dbl)    ::  PMSS(:), EMASS
      
  
! ... Locals

#if defined __SHMEM

      pointer (p_source,S)
      COMPLEX(dbl) S( SIZE(c0,2), SIZE(c0,2))
      pointer (p_sig,sig)
      COMPLEX(dbl) SIG( SIZE(c0,2), SIZE(c0,2))
      pointer (p_rho,rho)
      COMPLEX(dbl) RHO( SIZE(c0,2), SIZE(c0,2))
      pointer (p_tmass,tmass)
      COMPLEX(dbl) TMASS( SIZE(c0,2), SIZE(c0,2))
      pointer (p_target,TEMP)
      COMPLEX(dbl) TEMP( SIZE(c0,2), SIZE(c0,2))
      integer err
      pointer (p_pWrk,pWrk)
      COMPLEX(dbl)  pWrk(1) 

#else

      COMPLEX(dbl) SIG( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl) RHO( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl) S( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl) TEMP( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl) TMASS( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl) pWrk(1) 

#endif

      COMPLEX(dbl)    X0( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl)    TEMP1( SIZE(c0,2),MAX( SIZE(c0,2),4))
      COMPLEX(dbl)    BLAM( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl)    CLAM( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl)    X1( SIZE(c0,2), SIZE(c0,2))
      COMPLEX(dbl)    RHOA( SIZE(c0,2), SIZE(c0,2))
      REAL(dbl)        SIGD( SIZE(c0,2))
      REAL(dbl)        RHOD( SIZE(c0,2))
      COMPLEX(dbl),   ALLOCATABLE :: AUX(:)
      COMPLEX(dbl),   ALLOCATABLE :: DIAG(:,:)
      COMPLEX(dbl),   ALLOCATABLE :: vv(:,:)
      COMPLEX(dbl),   ALLOCATABLE :: sd(:)
       
      INTEGER ::  IDAMAX 
      INTEGER ::  N, NGW, NX, I, J, K, ITER
      REAL(dbl)  DIFGAM,RHOSIGD
      REAL(dbl)  S1,S2,S3,S4,s5,s6,s7,s8

! ... Subroutine body

      IF(timing) S1 = cclock()

      N   = SIZE( c0, 2 )
      NX  = SIZE( c0, 2 )
      NGW = SIZE( c0, 1 )

#if defined __SHMEM
      CALL SHPALLOC(p_pWrk, MAX(2*nx*nx,SHMEM_REDUCE_MIN_WRKDATA_SIZE), err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF PWRK FAILED ' ,0)
      END IF
      CALL SHPALLOC(p_sig, 2*nx*nx , err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF TMASS FAILED ' ,0)
      END IF
      CALL SHPALLOC(p_tmass, 2*nx*nx , err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF TMASS FAILED ' ,0)
      END IF
      CALL SHPALLOC(p_rho, 2*nx*nx , err, 0)
      WRITE(*,*)'SHPALLOC RHO done.', 2*nx*nx
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF RHO FAILED ' ,0)
      END IF
      CALL SHPALLOC(p_source, 2*nx*nx , err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF SOURCE FAILED ' ,0)
      END IF
      CALL SHPALLOC(p_target, 2*nx*nx , err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' ALLOC OF TARGET FAILED ' ,0)
      END IF
#endif


!.....INITIALIZE RHO AND SIG

      ALLOCATE(AUX(NGW))
      AUX(:) = CMPLX( EMASS / PMSS(:), 0.0_dbl)
      DO I=1,N
        C0(:,I) = C0(:,I) * AUX(:)
      END DO
      DEALLOCATE(AUX)

      CALL rhoset( ngw, nx, C0, CP, RHO, TMASS, PWRK )
      IF(timing) S2 = cclock()
      CALL sigset( ngw, nx, CP, SIG, PWRK )
      IF(timing) S3 = cclock()

      DO J=1,N
        DO I=1,N
! ...     Antisymmetric rho
          RHOA(I,J) = 0.5D0*(RHO(I,J) - CONJG(RHO(J,I)))
! ...     Symmetric rho
          temp(i,j) = rhoa(i,j) + CONJG(rho(j,i))
        ENDDO
      ENDDO

!.....DIAGONALIZATION OF RHOS

      CALL diagonalize_rho(temp,rhod,s)

      IF(timing) S4 = cclock()
!
! ... TRANSFORM SIG, RHOA AND TMASS IN THE NEW BASIS THROUGH MATRIX S
!
      CALL sqr_matmul('N','N',SIG,S,TEMP)
      CALL sqr_matmul('C','N',S,TEMP,SIG)
      CALL sqr_matmul('N','N',RHOA,S,TEMP)
      CALL sqr_matmul('C','N',S,TEMP,RHOA)
      CALL sqr_matmul('N','N',TMASS,S,TEMP)
      CALL sqr_matmul('C','N',S,TEMP,TMASS)

      IF(timing) S5 = cclock()
!
! ... INITIALIZE X0
!
      DO J=1,N
        DO I=1,N
          X0(I,J) = SIG(I,J)/(RHOD(I)+RHOD(J))
        ENDDO
      ENDDO

!----------------------------------------------------------------------
!
      ITERATIVE_LOOP: DO iter = 0, ortho_max

        CALL sqr_matmul('N','N',X0,RHOA,TEMP)
        CALL sqr_matmul('C','N',RHOA,X0,TEMP1)
!
        DO J=1,N
          DO I=1,N
            BLAM(I,J) =  TEMP(I,J) + TEMP1(I,J)
          ENDDO
        ENDDO
!
        CALL sqr_matmul('N','N',TMASS,X0,TEMP)

        !DO I=1,N
        !  SIGD(I)   =  REAL(TEMP(I,I))
        !  TEMP(I,I) = -REAL(TEMP(I,I))
        !ENDDO

        CALL sqr_matmul('N','N',X0,TEMP,CLAM)
!
!        X1   = SIG - BLAM - CLAM
!        X1   = 1 - A - L Ba - Ba' L - L C L
!
        difgam = 0.0d0
        DO J=1,N
          DO I=1,N        
            X1(I,J) = SIG(I,J) - BLAM(I,J) - CLAM(I,J)
            X1(I,J) = X1(I,J) / ( RHOD(I)+RHOD(J) ) ! +SIGD(I)+SIGD(J))
            difgam=max(abs(REAL(X1(I,J))-REAL(X0(I,J))),difgam)
            difgam=max(abs(aimag(X1(I,J))-aimag(X0(I,J))),difgam)
          ENDDO
        ENDDO      

        IF( difgam .LE. ortho_eps  ) EXIT ITERATIVE_LOOP
        x0 = x1

      END DO ITERATIVE_LOOP

      IF(timing) S6 = cclock()
!
! ... TRANSFORM X1 BACK TO THE ORIGINAL BASIS
!
      CALL sqr_matmul('N','N',S,X1,TEMP)
      CALL sqr_matmul('N','C',S,TEMP,X1)
!
      CALL ZGEMM('N','N',NGW,N,N,cone,C0,SIZE(c0,1),X1,N,cone,CP,SIZE(cp,1))
!
!.....RESTORE C0
!
      ALLOCATE(AUX(NGW))
      AUX(:) = CMPLX( PMSS(:) / EMASS ,0.0d0)
      DO I=1,N
        C0(:,I) = C0(:,I) * AUX(:)
      END DO
      DEALLOCATE(AUX)

#if defined __SHMEM
      call shmem_barrier_all
      CALL SHPDEALLC(p_pwrk, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF PWRK FAILED ' ,0)
      END IF
      CALL SHPDEALLC(p_sig, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF TMASS FAILED ' ,0)
      END IF
      CALL SHPDEALLC(p_tmass, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF TMASS FAILED ' ,0)
      END IF
      CALL SHPDEALLC(p_rho, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF RHO FAILED ' ,0)
      END IF
      CALL SHPDEALLC(p_source, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF SOURCE FAILED ' ,0)
      END IF
      CALL SHPDEALLC(p_target, err, 0)
      IF(ERR.NE.0) THEN
         CALL errore(' ORTHO ',' DEALLOC OF TARGET FAILED ' ,0)
      END IF
#endif

      IF(timing) THEN
        S7 = cclock()
        timrhos  = (s2 - s1) + timrhos
        timsigs  = (s3 - s2) + timsigs
        timdiag  = (s4 - s3) + timdiag
        timtras1 = (s5 - s4) + timtras1
        timiter  = (s6 - s5) + timiter
        timbtra  = (s7 - s6) + timbtra
        timtot   = (s7 - s1) + timtot
        timcnt = timcnt + 1
      END IF

      ortho_kp = iter
      RETURN
      END FUNCTION


!=----------------------------------------------------------------------------=!
!  BEGIN manual

      INTEGER FUNCTION ortho_scalapack( ispin, C0, CP, cdesc, PMSS, EMASS )

! INPUT:
!       C0 (ORTHONORMAL)
!       CP (NON-ORTHONORMAL)
! OUTPUT:
!       X1 = DT2/EMASS * LAMBDA
!       CP (ORTHONORMAL)
!
! Version for preconditioned equations of motion
! (following f.tassone, f.mauri and r.car ...)
! Scalapack driver
!----------------------------------------------------------------------!
!  END manual

      USE wave_types, ONLY: wave_descriptor
      USE parallel_types, ONLY: processors_grid, descriptor, &
       real_parallel_matrix, parallel_allocate, parallel_deallocate 
      USE descriptors_module, ONLY: desc_init_blacs, local_dimension
      USE processors_grid_module, ONLY: get_blacs_grid, free_blacs_grid, &
       get_grid_coor, get_grid_dims
      USE blacs, ONLY: start_blacs, stop_blacs
      USE scalapack
      USE mp, ONLY: mp_sum, mp_max
      USE control_flags, ONLY: ortho_eps, ortho_max
      

      IMPLICIT  NONE

! ... Arguments
      COMPLEX(dbl), INTENT(INOUT) :: c0(:,:), cp(:,:)
      TYPE (wave_descriptor), INTENT(IN) :: cdesc
      REAL (dbl)  :: PMSS(:), EMASS
      INTEGER, INTENT(IN) :: ispin
      
  
! ... Locals

      TYPE (processors_grid) :: grid
      TYPE (descriptor), POINTER :: desc
       
      INTEGER IDAMAX 
      INTEGER I,J,K,II,JJ,IP,JP
      INTEGER ITER
      REAL (dbl)  ::  S1,S2,S3,S4,S5,S6,S7,S8
      REAL (dbl)  ::  fact,ONE_BY_EMASS

!     .. Local Scalars ..
      INTEGER :: MYCOL, MYROW, NB, NPCOL, NPROW, NRL, NCL, RSRC, CSRC, N
      INTEGER :: npz, mez, ngw
      INTEGER :: INDXG2L, INDXL2G, INDXG2P
      LOGICAL :: gzero
!     .. 
!     .. Local Arrays ..

      TYPE (real_parallel_matrix) :: st, sigt, rhoat, tmasst, tempt, &
        temp1t, x0t, x1t

      REAL (dbl)  :: SIGD( SIZE( c0, 2 ) )
      REAL (dbl)  :: RHOD( SIZE( c0, 2 ) )
      REAL (dbl)  :: DIFGAM



! ... Subroutine body

      IF (timing) S1 = cclock()

      n   = cdesc%nbl( ispin )
      ngw = cdesc%ngwl
      
      IF( n < 1 ) THEN
        ortho_scalapack = 0
        RETURN
      END IF
        

! ... Initialize the BLACS
!      CALL start_blacs()

      CALL get_blacs_grid(grid)
      CALL get_grid_dims(grid, nprow, npcol, npz)
      CALL get_grid_coor(grid, myrow, mycol, mez)
      CALL blockset( NB, 0, N, nprow, npcol)

      ALLOCATE( desc )
      CALL desc_init_blacs(desc, 1, N, N, NB, NB, 0, 0, grid)

      RSRC  = desc%ipexs
      CSRC  = desc%ipeys
!
!.....INITIALIZE RHO AND SIG
!
      CALL parallel_allocate(sigt,desc)
      CALL parallel_allocate(tmasst,desc)
      CALL parallel_allocate(st,desc)
      CALL parallel_allocate(rhoat,desc)
      CALL parallel_allocate(tempt,desc)
      CALL parallel_allocate(temp1t,desc)
      CALL parallel_allocate(x0t,desc)
      CALL parallel_allocate(x1t,desc)


      CALL SIGRHOSET( ngw, n, CP(:,:), C0(:,:), SIGT, RHOAT, TMASST, PMSS, EMASS, cdesc%gzero)

      IF (timing) S2 = cclock()

!.....DIAGONALIZATION OF RHOS

      IF (timing) S3 = cclock()

      NRL = local_dimension( desc, 'R' )
      NCL = local_dimension( desc, 'C' )

!     TEMP = (RHOA(i,j)+RHOA(j,i))/2  SYMMETRIC PART
!     RHOA = (RHOA(i,j)-RHOA(j,i))/2  ANTISYMMETRIC PART
 
      CALL ptranspose(rhoat, tempt)
      DO J = 1, NCL
        DO I = 1, NRL
          TEMPT%m(i,j) = 0.5_dbl * ( rhoat%m(i,j) + tempt%m(i,j) ) 
          rhoat%m(i,j) = rhoat%m(i,j) - tempt%m(i,j)
        END DO
      END DO


      CALL pdiagonalize('U',tempt,rhod,st)

      IF (timing) S4 = cclock()

      ! ... TRANSFORM SIG, RHOA AND TMASS IN THE NEW BASIS THROUGH MATRIX S

      CALL pmatmul(sigt,st,tempt,'n','n')
      CALL pmatmul(st,tempt,sigt,'t','n')
      CALL pmatmul(rhoat,st,tempt,'n','n')
      CALL pmatmul(st,tempt,rhoat,'t','n')
      CALL pmatmul(tmasst,st,tempt,'n','n')
      CALL pmatmul(st,tempt,tmasst,'t','n')

      ! ... INITIALIZE X0

      DO J=1,NCL
        DO I=1,NRL
          II = INDXL2G( I, NB, MYROW, 0, NPROW )
          JJ = INDXL2G( J, NB, MYCOL, 0, NPCOL ) 
          X0T%m(I,J) = SIGT%m(I,J) / (RHOD(II)+RHOD(JJ))
        ENDDO
      ENDDO

      !

      IF (timing) S5 = cclock()

      ITERATIVE_LOOP: DO iter = 0, ortho_max

        CALL pmatmul(x0t,rhoat,tempt,'n','n')

        ! ...   TEMP1(i,j) = TEMP(i,j) + TEMP(j,i)

        CALL ptranspose(tempt,temp1t)
        DO J=1,NCL
          DO I=1,NRL
            TEMP1T%m(I,J) =  TEMP1T%m(I,J) +  TEMPT%m(I,J)
          ENDDO
        ENDDO
!
        CALL pmatmul(tmasst,x0t,tempt,'t','n')

        DO I=1,N
          SIGD(I)  = 0.0_dbl
          II = INDXG2L( I, NB, MYROW, 0, NPROW )
          JJ = INDXG2L( I, NB, MYCOL, 0, NPCOL )
          IP = INDXG2P( I, NB, MYROW, 0, NPROW )
          JP = INDXG2P( I, NB, MYCOL, 0, NPCOL )
          IF( ( IP .eq. MYROW ) .and. ( JP .eq. MYCOL ) ) THEN
            SIGD(I)        =  TEMPT%m(II,JJ)
            TEMPT%m(II,JJ) = -TEMPT%m(II,JJ)
          END IF
        ENDDO
        CALL mp_sum( SIGD )

        CALL pmatmul(x0t,tempt,x1t,'t','n')
        call ptranspose(x1t,tempt) 

        ! ...   X1   = SIG - TEMP1 - 0.5d0 * ( X1 + TEMP)

        difgam = 0.0d0
        DO J=1,NCL
          DO I=1,NRL 
            II = INDXL2G( I, NB, MYROW, 0, NPROW )
            JJ = INDXL2G( J, NB, MYCOL, 0, NPCOL )
            X1T%m(I,J) = 0.5d0 * (X1T%m(I,J) + TEMPT%m(I,J))
            X1T%m(I,J) = SIGT%m(I,J) - TEMP1T%m(I,J) - X1T%m(I,J)
            X1T%m(I,J) = X1T%m(I,J) / (RHOD(II)+SIGD(II)+RHOD(JJ)+SIGD(JJ))
            difgam = max(abs(X1T%m(I,J)-X0T%m(I,J)),difgam)
          ENDDO
        ENDDO      
        call mp_max( difgam )

        IF( difgam .LE. ortho_eps ) EXIT ITERATIVE_LOOP
        x0t%m = x1t%m

      END DO ITERATIVE_LOOP


      IF (timing) S6 = cclock()

      ! ... TRANSFORM X1 BACK TO THE ORIGINAL BASIS

      CALL pmatmul(st,x1t,tempt,'n','n')
      CALL pmatmul(st,tempt,x1t,'n','t')

      CALL backrhoset( ngw, n, CP(:,:), C0(:,:), X1T, PMSS, EMASS )

      CALL parallel_deallocate(st)
      CALL parallel_deallocate(sigt)
      CALL parallel_deallocate(rhoat)
      CALL parallel_deallocate(tmasst)
      CALL parallel_deallocate(tempt)
      CALL parallel_deallocate(temp1t)
      CALL parallel_deallocate(x0t)
      CALL parallel_deallocate(x1t)

      DEALLOCATE( desc )

      CALL free_blacs_grid(grid)


      IF(timing) THEN
        S7 = cclock()
        timrhos  = (s2 - s1) + timrhos
        timsigs  = (s3 - s2) + timsigs
        timdiag  = (s4 - s3) + timdiag
        timtras1 = (s5 - s4) + timtras1
        timiter  = (s6 - s5) + timiter
        timbtra  = (s7 - s6) + timbtra
        timtot   = (s7 - s1) + timtot
        timcnt = timcnt + 1
      END IF

      ortho_scalapack = iter
      RETURN
      END FUNCTION ortho_scalapack
!

!=----------------------------------------------------------------------------=!

      SUBROUTINE print_ortho_time( iunit )
        USE io_global, ONLY: ionode
        INTEGER, INTENT(IN) :: iunit
        IF( timing .AND. timcnt > 0 ) THEN
          timrhos  = timrhos/timcnt
          timsigs  = timsigs/timcnt
          timdiag  = timdiag/timcnt
          timtras1 = timtras1/timcnt
          timiter  = timiter/timcnt
          timbtra  = timbtra/timcnt
          timtot   = timtot/timcnt
          IF(ionode) THEN
            WRITE( iunit, 999 ) TIMRHOS, TIMSIGS, TIMDIAG, TIMTRAS1, TIMITER, TIMBTRA, TIMTOT
          END IF
        END IF
        timrhos = 0.0d0
        timsigs = 0.0d0
        timdiag = 0.0d0
        timtras1 = 0.0d0
        timiter = 0.0d0
        timbtra = 0.0d0
        timtot = 0.0d0
        timcnt = 0
999     FORMAT(1X,7(1X,F9.3))
        RETURN
      END SUBROUTINE


!=----------------------------------------------------------------------------=!
     END MODULE orthogonalize
!=----------------------------------------------------------------------------=!
