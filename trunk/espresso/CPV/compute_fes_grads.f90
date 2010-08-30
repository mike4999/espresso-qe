!
! Copyright (C) 2002-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE compute_fes_grads( fii, lii, stat )
  !----------------------------------------------------------------------------
  !
  USE kinds,              ONLY : DP
  USE input_parameters,   ONLY : electron_damping, ekin_conv_thr, etot_conv_thr
  USE wave_base,          ONLY : frice
  USE control_flags,      ONLY : nomore, ldamped, tconvthrs, trane, ampre, &
                                 nbeg, tfor, taurdr, tnosep, ndr, isave
  USE metadyn_vars,       ONLY : ncolvar, new_target, to_target, dfe_acc, &
                                 sw_nstep, fe_nstep, eq_nstep, to_new_target
  USE path_variables_pre,     ONLY : pos, grad_fes => grad_pes, &
                                 num_of_images, istep_path, pending_image
  USE constraints_module, ONLY : lagrange, constr_target, &
                                 init_constraint, deallocate_constraint
  USE cell_base,          ONLY : alat, at
  USE cp_main_variables,  ONLY : nfi
  USE ions_base,          ONLY : tau, nat, nsp, ityp, if_pos, sort_tau, &
                                 tau_srt, ind_srt
  USE path_formats_pre,       ONLY : scf_fmt, scf_fmt_para
  USE io_files,           ONLY : prefix, tmp_dir, iunpath, iunaxsf, &
                                 iunupdate, exit_file, iunexit
  USE constants,          ONLY : bohr_radius_angs
  USE io_global,          ONLY : stdout, ionode, ionode_id, meta_ionode
  USE mp_global,          ONLY : inter_image_comm, intra_image_comm, &
                                 my_image_id, nimage, root_image
  USE mp,                 ONLY : mp_bcast, mp_barrier, mp_sum, mp_min
  USE check_stop,         ONLY : check_stop_now
  USE input,              ONLY : modules_setup
  USE xml_io_base,        ONLY : check_restartfile
  USE path_io_routines_pre,   ONLY : new_image_init, get_new_image, &
                                 stop_other_images
  USE metadyn_base,       ONLY : add_domain_potential
  USE metadyn_io,         ONLY : write_axsf_file
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)   :: fii, lii
  LOGICAL, INTENT(OUT)  :: stat
  INTEGER               :: image, iter
  CHARACTER(LEN=256)    :: tmp_dir_saved, filename
  LOGICAL               :: file_exists, opnd
  LOGICAL               :: tnosep_saved
  REAL(DP)              :: tcpu
  REAL(DP), ALLOCATABLE :: tauout(:,:), fion(:,:)
  REAL(DP)              :: etot
  CHARACTER(LEN=10)     :: stage
  INTEGER               :: fe_step0, sw_step0
  !
  CHARACTER(LEN=6), EXTERNAL :: int_to_char
  REAL(DP),         EXTERNAL :: get_clock
  !
  !
  stat = .TRUE.
  !
  ALLOCATE( tauout( 3, nat ), fion( 3, nat ) )
  !
  ! ... out positions are initialised to the input ones
  !
  tauout(:,:) = tau(:,:)
  !
  CALL flush_unit( iunpath )
  !
  tmp_dir_saved = tmp_dir
  tnosep_saved = tnosep
  !
  ! ... vectors pes and grad_pes are initalized to zero for all images on
  ! ... all nodes: this is needed for the final mp_sum()
  !
  IF ( my_image_id == root_image ) THEN
     !
     grad_fes(:,:) = 0.D0
     !
  ELSE
     !
     grad_fes(:,fii:lii) = 0.D0
     !
  END IF
  !
  ! ... only the first cpu initializes the file needed by parallelization 
  ! ... among images
  !
  IF ( meta_ionode ) CALL new_image_init( fii, tmp_dir_saved )
  !
  image = fii + my_image_id
  !
  ! ... all processes are syncronized (needed to have an ordered output)
  !
  CALL mp_barrier()
  !
  fes_loop: DO
     !
     ! ... exit if available images are finished
     !
     IF ( image > lii ) EXIT fes_loop
     !
     pending_image = image
     !
     IF ( check_stop_now( iunpath ) ) THEN
        !
        stat = .FALSE.
        !
        ! ... in case of parallelization on images a stop signal
        ! ... is sent via the "EXIT" file
        !
        IF ( nimage > 1 ) CALL stop_other_images()
        !
        EXIT fes_loop
        !
     END IF
     !
     ! ... calculation of the mean-force
     !
     tcpu = get_clock( 'CP' )
     !
     IF ( nimage > 1 ) THEN
        !
        WRITE( UNIT = iunpath, FMT = scf_fmt_para ) my_image_id, tcpu, image
        !
     ELSE
        !
        WRITE( UNIT = iunpath, FMT = scf_fmt ) tcpu, image
        !
     END IF
     !
     tmp_dir= TRIM(tmp_dir_saved ) // "/" // TRIM( prefix ) // &
            & "_" // TRIM( int_to_char( image ) ) // "/"
     !
     ! ... unit stdout is connected to the appropriate file
     !
     IF ( ionode ) THEN
        !
        INQUIRE( UNIT = stdout, OPENED = opnd )
        IF ( opnd ) CLOSE( UNIT = stdout )
        OPEN( UNIT = stdout, FILE = TRIM( tmp_dir) // 'CP.out', &
              STATUS = 'UNKNOWN', POSITION = 'APPEND' )
        !
     END IF
     !
     ! ... initialization
     !
     CALL deallocate_modules_var()
     CALL deallocate_constraint()
     !
     CALL modules_setup()
     !
     filename = TRIM( tmp_dir) // "therm_average.restart"
     !
     INQUIRE( FILE = filename, EXIST = file_exists )
     !
     IF ( file_exists ) THEN
        !
        ! ... we read the previous positions, the value of the accumulators,
        ! ... and the number of steps already performed for this image from
        ! ... a restart file
        !
        IF ( ionode ) THEN
           !
           OPEN( UNIT = 1000, FILE = filename )
           !
           READ( 1000, * ) stage
           READ( 1000, * ) tau(:,:)
           READ( 1000, * ) nomore
           READ( 1000, * ) to_target
           READ( 1000, * ) dfe_acc
           !
           CLOSE( UNIT = 1000 )
           !
        END IF
        !
        CALL mp_bcast( stage,     ionode_id )
        CALL mp_bcast( tau,       ionode_id )
        CALL mp_bcast( nomore,    ionode_id )
        CALL mp_bcast( to_target, ionode_id )
        CALL mp_bcast( dfe_acc,   ionode_id )
        !
     ELSE
        !
        ! ... otherwise we use the output positions from the previous image
        !
        tau(:,:) = tauout(:,:)
        !
        stage = 'tobedone'
        !
     END IF
     !
     CALL sort_tau( tau_srt, ind_srt, tau, ityp, nat, nsp )
     !
     CALL init_constraint( nat, tau, ityp, 1.D0 )
     !
     fe_step0 = 0
     sw_step0 = 0
     !
     SELECT CASE( stage )
     CASE( 'done' )
        !
        ! ... do nothing and recompute the average quantities
        !
     CASE( 'tobedone' )
        !
        new_target(:) = pos(:,image)
        !
        to_target(:) = ( new_target(:) - &
                         constr_target(1:ncolvar) ) / DBLE( sw_nstep )
        !
        stage = 'switch'
        !
        dfe_acc = 0.D0
        !
     CASE( 'switch' )
        !
        dfe_acc = 0.D0
        !
        sw_step0 = nomore
        !
     CASE( 'mean-force' )
        !
        fe_step0 = nomore
        !
     CASE DEFAULT
        !
        CALL errore( 'compute_fes_grads', &
                     'stage ' // TRIM( stage ) // ' unknown', 1 )
        !
     END SELECT
     !
     IF ( stage /= 'done' ) THEN
        !
        ! ... first we do a wavefunctions optimisation to bring the system
        ! ... on the BO surface
        !
        tconvthrs%ekin  = ekin_conv_thr
        tconvthrs%derho = etot_conv_thr
        !
        taurdr = .TRUE.
        nfi    = 0
        tnosep = .FALSE.
        tfor   = .FALSE.
        !
        frice = electron_damping
        !
        tconvthrs%active = .TRUE.
        !
        IF ( check_restartfile(tmp_dir, ndr ) ) THEN
           !
           WRITE( stdout, '(/,3X,"restarting from file",/)' )
           !
           nbeg   = 0
           nomore = 50
           !
        ELSE
           !
           WRITE( stdout, '(/,3X,"restarting from scratch",/)' )
           !
           nbeg   = -1
           nomore = 100
           trane  = .TRUE.
           ampre  = 0.02D0
           !
        END IF
        !
        isave = nomore
        !
        CALL init_run()
        !
        CALL cprmain( tauout, fion, etot )
        !
        tfor   = .TRUE.
        tnosep = tnosep_saved
        !
     END IF
     !
     IF ( stage == 'switch' ) THEN
        !
        ! ... first the collective variables are "adiabatically" changed to
        ! ... the new vales by using MD without damping
        !
        WRITE( stdout, '(/,5X,"adiabatic switch of the system ", &
                            & "to the new coarse-grained positions",/)' )
        !
        nfi    = sw_step0
        nomore = sw_nstep
        isave  = sw_nstep
        !
        frice = electron_damping
        !
        tconvthrs%active = .FALSE.
        to_new_target    = .TRUE.
        !
        IF ( ldamped ) CALL reset_vel()
        !
        CALL cprmain( tauout, fion, etot )
        !
        stage = 'mean-force'
        !
        CALL write_restart( 'mean-force', 0 )
        !
     END IF
     !
     IF ( stage == 'mean-force' ) THEN
        !
        ! ... then the free energy gradients are computed
        !
        WRITE( stdout, '(/,5X,"calculation of the mean force",/)' )
        !
        nfi    = fe_step0
        nomore = fe_nstep
        isave  = fe_nstep
        !
        IF ( ldamped ) THEN
           !
           frice = electron_damping
           !
           tconvthrs%active = .TRUE.
           !
           CALL reset_vel()
           !
        ELSE
           !
           frice = 0.D0
           !
           tconvthrs%active = .FALSE.
           !
        END IF
        !
        to_new_target = .FALSE.
        !
        CALL cprmain( tauout, fion, etot )
        !
     END IF
     !
     ! ... the averages are computed here
     !
     IF ( ldamped ) THEN
        !
        ! ... zero temperature case
        !
        grad_fes(:,image) = - lagrange(1:ncolvar)
        !
     ELSE
        !
        ! ... finite temperature case
        !
        grad_fes(:,image) = dfe_acc(:) / DBLE( fe_nstep - eq_nstep )
        !
     END IF
     !
     ! ... notice that grad_fes(:,image) have been computed, so far, by
     ! ... ionode only: here we broadcast to all the other cpus
     !
     CALL mp_bcast( grad_fes(:,image), ionode_id, intra_image_comm )
     !
     IF ( ionode ) THEN
        !
        ! ... the restart file is written here
        !
        CALL write_restart( 'done', 0 )
        !
        CALL write_axsf_file( image, tauout, 1.D0 )
        !
     END IF
     !
     ! ... the new image is obtained
     !
     CALL get_new_image( image,tmp_dir_saved )
     !
     CALL mp_bcast( image, ionode_id, intra_image_comm )
     !
  END DO fes_loop
  !
  CALL mp_barrier()
  !
  IF ( meta_ionode ) THEN
     !
     ! ... when all the images are done the stage is changed from
     ! ... 'done' to 'tobedone'
     !
     DO image = fii, lii
        !
        tmp_dir= TRIM(tmp_dir_saved ) // TRIM( prefix ) // &
               & "_" // TRIM( int_to_char( image ) ) // "/"
        !
        filename = TRIM( tmp_dir ) // "therm_average.restart"
        !
        OPEN( UNIT = 1000, FILE = filename )
        !
        READ( 1000, * ) stage
        READ( 1000, * ) tauout(:,:)
        READ( 1000, * ) nomore
        READ( 1000, * ) to_target
        READ( 1000, * ) dfe_acc
        !
        CLOSE( UNIT = 1000 )
        !
        CALL write_restart( 'tobedone', 0 )
        !
     END DO
     !
     ! ... here the meta_ionode writes the axsf file for this iteration
     ! ... by reading the postions from the restart-file
     !
     filename = TRIM( prefix ) // "_" // &
              & TRIM( int_to_char( istep_path + 1 ) ) // ".axsf"
     !
     OPEN( UNIT = iunaxsf, FILE = filename, ACTION = "WRITE" )
     !
     WRITE( UNIT = iunaxsf, FMT = '(" ANIMSTEPS ",I5)' ) num_of_images
     WRITE( UNIT = iunaxsf, FMT = '(" CRYSTAL ")' )
     WRITE( UNIT = iunaxsf, FMT = '(" PRIMVEC ")' )
     WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
          at(1,1)*alat*bohr_radius_angs, &
          at(2,1)*alat*bohr_radius_angs, &
          at(3,1)*alat*bohr_radius_angs
     WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
          at(1,2)*alat*bohr_radius_angs, &
          at(2,2)*alat*bohr_radius_angs, &
          at(3,2)*alat*bohr_radius_angs
     WRITE( UNIT = iunaxsf, FMT = '(3F14.10)' ) &
          at(1,3)*alat*bohr_radius_angs, &
          at(2,3)*alat*bohr_radius_angs, &
          at(3,3)*alat*bohr_radius_angs
     !
     DO image = 1, num_of_images
        !
        tmp_dir = TRIM( tmp_dir_saved ) // TRIM( prefix ) // &
               & "_" // TRIM( int_to_char( image ) ) // "/"
        !
        filename = TRIM( tmp_dir ) // "therm_average.restart"
        !
        OPEN( UNIT = 1000, FILE = filename )
        !
        READ( 1000, * ) stage
        READ( 1000, * ) tauout(:,:)
        !
        CLOSE( UNIT = 1000 )
        !
        CALL write_axsf_file( image, tauout, 1.D0 )
        !
     END DO
     !
     CLOSE( UNIT = iunaxsf )
     !
  END IF
  !
  CALL add_domain_potential()
  !
  DEALLOCATE( tauout, fion )
  !
  tmp_dir= tmp_dir_saved
  tnosep = tnosep_saved
  !
  IF ( nimage > 1 ) THEN
     !
     ! ... grad_fes is communicated among "image" pools
     !
     CALL mp_sum( grad_fes(:,fii:lii), inter_image_comm )
     !
  END IF
  !
  pending_image = 0
  !
  RETURN
  !
  CONTAINS
    !
    !------------------------------------------------------------------------
    SUBROUTINE write_restart( stage, nstep )
      !------------------------------------------------------------------------
      !
      CHARACTER(LEN=*), INTENT(IN) :: stage
      INTEGER,          INTENT(IN) :: nstep
      !
      OPEN( UNIT = 1000, FILE = filename )
      !
      WRITE( 1000, * ) TRIM( stage )
      WRITE( 1000, * ) tauout(:,:)
      WRITE( 1000, * ) nstep
      WRITE( 1000, * ) to_target
      WRITE( 1000, * ) dfe_acc
      !
      CLOSE( UNIT = 1000 )
      !
    END SUBROUTINE write_restart
    !
END SUBROUTINE compute_fes_grads
!
!------------------------------------------------------------------------
SUBROUTINE reset_vel()
  !------------------------------------------------------------------------
  !
  USE ions_positions, ONLY : tau0, taum, taus, tausm
  !
  IMPLICIT NONE
  !
  !
  taum(:,:)  = tau0(:,:)
  tausm(:,:) = taus(:,:)
  !
  RETURN
  !
END SUBROUTINE reset_vel
