!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE coarsegrained_vars
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : DP
  !
  IMPLICIT NONE
  !
  SAVE
  !
  INTEGER  :: fe_nstep
  INTEGER  :: shake_nstep
  !
  REAL(DP), ALLOCATABLE :: dfe_acc(:)
  REAL(DP), ALLOCATABLE :: fe_grad(:)
  REAL(DP), ALLOCATABLE :: new_target(:)
  REAL(DP), ALLOCATABLE :: to_target(:)
  !
  LOGICAL  :: to_new_target
  !
  ! ... Laio-Parrinello meta-dynamics
  !
  INTEGER  :: max_metadyn_iter
  !
  INTEGER, PARAMETER  :: gaussian_add_iter = 1
  !
  REAL(DP), ALLOCATABLE :: fe_step(:)
  !
  REAL(DP), ALLOCATABLE :: metadyn_history(:,:)
  LOGICAL,  ALLOCATABLE :: gaussian_add(:)
  !
  REAL(DP) :: g_amplitude
  REAL(DP) :: g_sigma
  !
  REAL(DP) :: g_sigma_sq
  REAL(DP) :: two_g_sigma_sq
  !
  INTEGER :: starting_metadyn_iter
  !
  CHARACTER(LEN=32) :: metadyn_fmt
  !
  CONTAINS
    !
    !------------------------------------------------------------------------
    SUBROUTINE init_coarsegrained_vars()
      !------------------------------------------------------------------------
      !
      USE input_parameters,   ONLY : g_amplitude_ => g_amplitude, &
                                     g_sigma_     => g_sigma, &
                                     fe_step_     => fe_step, &
                                     fe_nstep_    => fe_nstep, &
                                     shake_nstep_ => shake_nstep
      USE constraints_module, ONLY : nconstr
      USE control_flags,      ONLY : lmetadyn, nstep
      !
      IMPLICIT NONE
      !
      !
      ALLOCATE( fe_step(    nconstr ) )
      ALLOCATE( dfe_acc(    nconstr ) )
      ALLOCATE( fe_grad(    nconstr ) )
      ALLOCATE( new_target( nconstr ) )
      ALLOCATE( to_target(  nconstr ) )
      !
      IF ( lmetadyn ) THEN
         !
         ALLOCATE( metadyn_history( nconstr, nstep ) )
         ALLOCATE( gaussian_add( nstep ) )
         !
      END IF
      !
      fe_nstep    = fe_nstep_
      shake_nstep = shake_nstep_
      g_amplitude = g_amplitude_
      g_sigma     = g_sigma_
      fe_step(:)  = fe_step_(1:nconstr)
      !
      RETURN
      !
    END SUBROUTINE init_coarsegrained_vars
    !
    !------------------------------------------------------------------------
    SUBROUTINE deallocate_coarsegrained_vars()
      !------------------------------------------------------------------------
      !
      IF ( ALLOCATED( fe_step ) )          DEALLOCATE( fe_step )
      IF ( ALLOCATED( dfe_acc ) )          DEALLOCATE( dfe_acc )
      IF ( ALLOCATED( fe_grad ) )          DEALLOCATE( fe_grad )
      IF ( ALLOCATED( new_target ) )       DEALLOCATE( new_target )
      IF ( ALLOCATED( to_target ) )        DEALLOCATE( to_target )
      IF ( ALLOCATED( metadyn_history ) )  DEALLOCATE( metadyn_history )
      IF ( ALLOCATED( gaussian_add ) )     DEALLOCATE( gaussian_add )
      !
      RETURN
      !
    END SUBROUTINE deallocate_coarsegrained_vars
    !
END MODULE coarsegrained_vars
!
!----------------------------------------------------------------------------
MODULE coarsegrained_base
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : DP
  !
  IMPLICIT NONE
  !
  PRIVATE
  !
  PUBLIC :: set_target, &
            add_gaussians, &
            metadyn_init, &
            evolve_collective_vars, &
            write_axsf_file
  !
  CONTAINS
    !
    !------------------------------------------------------------------------
    SUBROUTINE set_target()
      !------------------------------------------------------------------------
      !
      USE coarsegrained_vars, ONLY : to_target, to_new_target, shake_nstep
      USE constraints_module, ONLY : target
      !
      !
      IF ( to_new_target ) THEN
         !
         target(:) = target(:) + to_target(:) / DBLE( shake_nstep )
         !
      END IF
      !
      RETURN
      !
    END SUBROUTINE set_target
    !
    !------------------------------------------------------------------------
    SUBROUTINE metadyn_init()
      !------------------------------------------------------------------------
      !
      USE kinds,              ONLY : DP
      USE input_parameters,   ONLY : restart_mode
      USE constraints_module, ONLY : nconstr, target
      USE control_flags,      ONLY : nstep
      USE constants,          ONLY : bohr_radius_angs
      USE cell_base,          ONLY : at, alat
      USE coarsegrained_vars, ONLY : fe_grad, g_amplitude, g_sigma,     &
                                     g_sigma_sq, two_g_sigma_sq,        &
                                     max_metadyn_iter, metadyn_history, &
                                     starting_metadyn_iter, metadyn_fmt
      USE parser,             ONLY : delete_if_present, int_to_char
      USE io_files,           ONLY : prefix, iunaxsf, iunmeta
      USE io_global,          ONLY : stdout, ionode, ionode_id
      USE mp,                 ONLY : mp_bcast
      !
      IMPLICIT NONE
      !
      INTEGER  :: idum, i
      REAL(DP) :: rdum
      LOGICAL  :: lstop, file_exists
      !
      !
      metadyn_fmt = "(I4," // &
                  & TRIM( int_to_char( 2*nconstr + 1 ) ) // "(2X,F12.8),1X,L)"
      !
      g_sigma_sq     = g_sigma**2
      two_g_sigma_sq = 2.D0 * g_sigma_sq
      !
      IF ( nstep < 1 ) CALL errore( 'metadyn_init', 'nstep < 1', 1 )
      !
      max_metadyn_iter = nstep
      !
      IF ( restart_mode == 'from_scratch' ) THEN
         !
         IF ( ionode ) THEN
            !
            OPEN( UNIT = iunaxsf, &
                  FILE = TRIM( prefix ) // ".axsf", STATUS = 'UNKNOWN' )
            !
            WRITE( UNIT = iunaxsf, &
                   FMT = '(" ANIMSTEPS ",I5)' ) max_metadyn_iter
            !
            WRITE( UNIT = iunaxsf, FMT = '(" CRYSTAL ")' )
            WRITE( UNIT = iunaxsf, FMT = '(" PRIMVEC ")' )
            WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
                at(1,1) * alat * bohr_radius_angs, &
                at(2,1) * alat * bohr_radius_angs, &
                at(3,1) * alat * bohr_radius_angs
            WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
                at(1,2) * alat * bohr_radius_angs, &
                at(2,2) * alat * bohr_radius_angs, &
                at(3,2) * alat * bohr_radius_angs
            WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
                at(1,3) * alat * bohr_radius_angs, &
                at(2,3) * alat * bohr_radius_angs, &
                at(3,3) * alat * bohr_radius_angs
            !
         END IF
         !
         CALL delete_if_present( TRIM( prefix ) // '.metadyn' )
         !
         IF ( ionode ) THEN
            !
            OPEN( UNIT = iunmeta, &
                  FILE = TRIM( prefix ) // '.metadyn', STATUS = 'NEW' )
            !
            WRITE( iunmeta, '(2(2X,I5))' ) nconstr, max_metadyn_iter
            WRITE( iunmeta, '(2(2X,F12.8))' ) g_amplitude, g_sigma
            !
         END IF
         !
         starting_metadyn_iter = 0
         !
      ELSE
         !
         IF ( ionode ) &
            INQUIRE( FILE = TRIM( prefix ) // '.metadyn', EXIST = file_exists )
         !
         CALL mp_bcast( file_exists, ionode_id )
         !
         IF ( .NOT. file_exists ) &
            CALL errore( 'metadyn_init', 'restart file  ' // &
                       & TRIM( prefix ) // '.metadyn  does not exist', 1 )
         !
         IF ( ionode ) THEN
            !
            OPEN( UNIT = iunaxsf, FILE = TRIM( prefix ) // ".axsf", &
                  STATUS = 'UNKNOWN', ACTION = 'WRITE', POSITION = 'APPEND' )
            !
            OPEN( UNIT = iunmeta, FILE = TRIM( prefix ) // '.metadyn', &
                  ACTION = 'READ', STATUS = 'UNKNOWN' )
            !
            READ( iunmeta, * ) nconstr
            READ( iunmeta, * )
            !
            DO i = 1, max_metadyn_iter
               !
               READ( iunmeta, *, END = 100 ) &
                  starting_metadyn_iter, metadyn_history(:,i), rdum, fe_grad(:)
               !
            END DO
            !
100         IF ( starting_metadyn_iter == max_metadyn_iter ) THEN
               !
               WRITE( stdout, '(/,5X,"Simulation already completed",/)' )
               !
               CLOSE( UNIT = iunmeta, STATUS = 'KEEP' )
               !
               lstop = .TRUE.
               !
            ELSE
               !
               lstop = .FALSE.
               !
               target(:) = metadyn_history(:,starting_metadyn_iter)
               !
               CLOSE( UNIT = iunmeta, STATUS = 'KEEP' )
               !
               OPEN( UNIT = iunmeta, FILE = TRIM( prefix ) // '.metadyn', &
                     STATUS = 'UNKNOWN', ACTION = 'WRITE', POSITION = 'APPEND' )
               !
            END IF
            !
         END IF
         !
         CALL mp_bcast( lstop, ionode_id )
         !
         IF ( lstop ) CALL stop_run( .FALSE. )
         !
         CALL mp_bcast( starting_metadyn_iter, ionode_id )
         CALL mp_bcast( metadyn_history,       ionode_id )
         CALL mp_bcast( target,                ionode_id )
         CALL mp_bcast( fe_grad,               ionode_id )
         !
      END IF
      !
      RETURN
      !
    END SUBROUTINE metadyn_init
    !
    !------------------------------------------------------------------------
    SUBROUTINE add_gaussians( iter )
      !------------------------------------------------------------------------
      !
      USE constraints_module, ONLY : nconstr
      USE coarsegrained_vars, ONLY : metadyn_history, gaussian_add, &
                                     fe_grad, dfe_acc
      USE coarsegrained_vars, ONLY : g_amplitude, g_sigma_sq, two_g_sigma_sq
      USE basic_algebra_routines
      !
      IMPLICIT NONE
      !
      INTEGER, INTENT(IN) :: iter
      !
      INTEGER               :: i
      REAL(DP), ALLOCATABLE :: delta(:)
      !
      !
      ! ... history dependent term
      !
      IF ( iter == 1 ) RETURN
      !
      ALLOCATE( delta( nconstr ) )
      !
      dfe_acc = 0.D0
      !
      DO i = 1, iter - 1
         !
         IF ( .NOT. gaussian_add(i) ) CYCLE
         !
         delta = metadyn_history(:,i) - metadyn_history(:,iter)
         !
         dfe_acc(:) = dfe_acc(:) + delta(:) * &
                      EXP( - ( delta(:) .dot. delta(:) ) / two_g_sigma_sq )
         !
      END DO
      !
      fe_grad(:) = fe_grad(:) + g_amplitude / g_sigma_sq * dfe_acc(:)
      !
      DEALLOCATE( delta )
      !
      RETURN
      !
    END SUBROUTINE add_gaussians
    !
    !------------------------------------------------------------------------
    SUBROUTINE evolve_collective_vars( norm_fe_grad )
      !------------------------------------------------------------------------
      !
      USE constraints_module, ONLY : nconstr, constr_type, target, dmax
      USE coarsegrained_vars, ONLY : fe_grad, fe_step, new_target, to_target
      !
      IMPLICIT NONE
      !
      REAL(DP), INTENT(IN) :: norm_fe_grad
      !
      INTEGER :: i
      !
      !
      fe_grad(:) = fe_grad(:) / norm_fe_grad
      !
      DO i = 1, nconstr
         !
         new_target(i) = target(i) - fe_step(i) * fe_grad(i)
         !
      !   IF ( constr_type(i) == 3 ) THEN
      !      !
      !      ! ... for constraints on distances we must use the minimum 
      !      ! ... image convenction
      !      !
      !      PRINT *, "TG: ",new_target(i), dmax, MAX( 0.D0, new_target(i) - dmax )
      !      new_target(i) = new_target(i) - MAX( 0.D0, new_target(i) - dmax )
      !      !
      !   END IF
         !
      END DO
      !
      to_target(:) = new_target(:) - target(:)
      !
    END SUBROUTINE evolve_collective_vars
    !
    !------------------------------------------------------------------------
    SUBROUTINE write_axsf_file( image )
      !------------------------------------------------------------------------
      !
      USE input_parameters, ONLY : atom_label
      USE io_files,         ONLY : iunaxsf
      USE constants,        ONLY : bohr_radius_angs
      USE ions_base,        ONLY : nat, tau, ityp
      USE cell_base,        ONLY : alat
      !
      IMPLICIT NONE
      !
      INTEGER, INTENT(IN) :: image
      INTEGER             :: atom
      !
      !
      WRITE( UNIT = iunaxsf, FMT = '(" PRIMCOORD ",I5)' ) image
      WRITE( UNIT = iunaxsf, FMT = '(I5,"  1")' ) nat
      !
      DO atom = 1, nat
         !
         WRITE( UNIT = iunaxsf, FMT = '(A2,3(2X,F18.10))' ) &
                TRIM( atom_label(ityp(atom)) ), &
             tau(1,atom) * alat * bohr_radius_angs, &
             tau(2,atom) * alat * bohr_radius_angs, &
             tau(3,atom) * alat * bohr_radius_angs
         !
      END DO
      !
      RETURN
      !
    END SUBROUTINE write_axsf_file
    !
END MODULE coarsegrained_base
