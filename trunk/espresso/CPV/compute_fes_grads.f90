!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
SUBROUTINE compute_fes_grads( N_in, N_fin, stat )
  !----------------------------------------------------------------------------
  !
  USE kinds,              ONLY : DP
  USE control_flags,      ONLY : program_name, nomore, ldamped, &
                                 trane, ampre, nbeg, tfor, taurdr, ndr
  USE cg_module,          ONLY : tcg
  USE coarsegrained_vars, ONLY : new_target, to_target, dfe_acc, &
                                 max_shake_iter, max_fe_iter, to_new_target
  USE path_variables,     ONLY : pos, pes, grad_pes, frozen, &
                                 num_of_images, istep_path, suspended_image
  USE constraints_module, ONLY : lagrange, target, init_constraint, &
                                 deallocate_constraint
  USE cell_base,          ONLY : alat, at
  USE cp_main_variables,  ONLY : nfi
  USE ions_base,          ONLY : nat, nsp, ityp, if_pos, &
                                 sort_tau, tau_srt, ind_srt
  USE path_formats,       ONLY : scf_fmt, scf_fmt_para
  USE io_files,           ONLY : prefix, outdir, scradir, iunpath, iunaxsf, &
                                 iunupdate, exit_file, iunexit
  USE parser,             ONLY : int_to_char, delete_if_present
  USE constants,          ONLY : bohr_radius_angs
  USE io_global,          ONLY : stdout, ionode, ionode_id, meta_ionode
  USE mp_global,          ONLY : inter_image_comm, intra_image_comm, &
                                 my_image_id, nimage, root
  USE mp,                 ONLY : mp_bcast, mp_barrier, mp_sum, mp_min
  USE check_stop,         ONLY : check_stop_now
  USE input,              ONLY : modules_setup
  USE xml_io_base,        ONLY : check_restartfile
  USE path_io_routines,   ONLY : new_image_init, get_new_image, &
                                 stop_other_images
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)   :: N_in, N_fin
  LOGICAL, INTENT(OUT)  :: stat
  INTEGER               :: image, iter
  CHARACTER (LEN=256)   :: outdir_saved, filename
  LOGICAL               :: file_exists, opnd, tstop
  REAL(DP)              :: tcpu
  REAL(DP), ALLOCATABLE :: tau(:,:)
  REAL(DP), ALLOCATABLE :: fion(:,:)
  REAL(DP)              :: etot
  REAL(DP), EXTERNAL    :: get_clock
  !
  !
  ALLOCATE( tau( 3, nat ), fion( 3, nat ) )
  !
  CALL flush_unit( iunpath )
  !
  IF ( ionode ) THEN
     !
     OPEN( UNIT = iunaxsf, FILE = TRIM( prefix ) // "_" // &
         & TRIM( int_to_char( istep_path + 1 ) ) // ".axsf", &
           STATUS = "UNKNOWN", ACTION = "WRITE" )
     !
     WRITE( UNIT = iunaxsf, FMT = '(" ANIMSTEPS ",I3)' ) num_of_images
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
  outdir_saved = outdir
  !
  ! ... vectors pes and grad_pes are initalized to zero for all images on
  ! ... all nodes: this is needed for the final mp_sum()
  !
  IF ( my_image_id == root ) THEN
     !
     FORALL( image = N_in:N_fin, .NOT. frozen(image)   )
        !
        grad_pes(:,image) = 0.D0
        !
     END FORALL     
     !
  ELSE
     !
     grad_pes(:,N_in:N_fin) = 0.D0
     !   
  END IF
  !
  ! ... only the first cpu initializes the file needed by parallelization 
  ! ... among images
  !
  IF ( meta_ionode ) CALL new_image_init( N_in, outdir_saved )
  !
  image = N_in + my_image_id
  !
  ! ... all processes are syncronized (needed to have an ordered output)
  !
  CALL mp_barrier()
  !
  fes_loop: DO
     !
     ! ... exit if available images are finished
     !
     IF ( image > N_fin ) EXIT fes_loop
     !     
     suspended_image = image
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
     ! ... free-energy gradient ( for non-frozen images only )
     !
     IF ( .NOT. frozen(image) ) THEN
        !
        tcpu = get_clock( program_name )
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
        outdir = TRIM( outdir_saved ) // "/" // TRIM( prefix ) // "_" // &
                 TRIM( int_to_char( image ) ) // "/"        
        !
        scradir = outdir
        !
        ! ... unit stdout is connected to the appropriate file
        !
        IF ( ionode ) THEN
           !
           INQUIRE( UNIT = stdout, OPENED = opnd )
           IF ( opnd ) CLOSE( UNIT = stdout )
           OPEN( UNIT = stdout, FILE = TRIM( outdir ) // 'CP.out', &
                 STATUS = 'UNKNOWN', POSITION = 'APPEND' )
           !
        END IF
        !
        ! ... initialization
        !
        CALL deallocate_modules_var()
        !
        CALL modules_setup()
        !
        CALL deallocate_constraint()
        !
        ! ... we read the previous positions for this image from a restart file
        !
        filename = TRIM( outdir ) // "thermodinamic_average.restart"
        !
        INQUIRE( FILE = filename, EXIST = file_exists )
        !
        IF ( file_exists ) THEN
           !
           OPEN( UNIT = 1000, FILE = filename )
           !
           READ( 1000, * ) tau
           !
           CLOSE( UNIT = 1000 )
           !
        END IF
        !
        CALL sort_tau( tau_srt, ind_srt, tau, ityp, nat, nsp )
        !
        ! ... first the wfc are taken to the ground state using CG algorithm
        !
        taurdr = .TRUE.
        nfi    = 1
        tcg    = .TRUE.
        tfor   = .FALSE.
        !
        IF ( check_restartfile( scradir, ndr ) ) THEN
           !
           WRITE( stdout, '(/,2X,"restarting calling readfile",/)' )
           !
           nbeg   = 0
           nomore = 100
           !
        ELSE
           !
           WRITE( stdout, '(/,2X,"restarting from scratch",/)' )
           !
           nbeg   = -1
           nomore = 500
           trane  = .TRUE.
           ampre  = 0.02D0
           !
        END IF
        !
        ! ... initialization of the CP-dynamics
        !
        CALL init_run()
        !
        ! ... the new value of the order-parameter is set here
        !
        CALL init_constraint( nat, tau, alat, ityp )
        !
        CALL cprmain( tau, fion, etot )
        !
        ! ... then the system is "adiabatically" moved to the new target
        !
        new_target(:) = pos(:,image)
        !
        to_target(:) = new_target(:) - target(:)
        !
        nfi    = 1
        nomore = max_shake_iter
        tcg    = .FALSE.
        tfor   = .TRUE.
        !
        to_new_target = .TRUE.
        !
        CALL cprmain( tau, fion, etot )
        !
        ! ... and finally the free energy gradients are computed
        !
        nfi    = 1
        nomore = max_fe_iter
        !
        to_new_target = .FALSE.
        !
        CALL cprmain( tau, fion, etot )
        !
        ! ... the averages are computed here
        !
        IF ( ldamped ) THEN
           !
           ! ... zero temperature
           !
           grad_pes(:,image) = - lagrange(:)
           !
           pes(image) = etot
           !
        ELSE
           !
           ! ... finite temperature
           !
           grad_pes(:,image) = dfe_acc(:) / DBLE( nomore )
           !
        END IF
        !
        IF ( ionode ) CALL write_config( image )
        !
        ! ... the restart file is written here
        !
        OPEN( UNIT = 1000, FILE = filename )
        !
        WRITE( 1000, * ) tau
        !
        CLOSE( UNIT = 1000 )
        !
     END IF
     !
     ! ... the new image is obtained (by ionode only)
     !
     CALL get_new_image( image, outdir_saved )
     !
     CALL mp_bcast( image, ionode_id, intra_image_comm )
     !
  END DO fes_loop
  !
  CLOSE( UNIT = iunaxsf )
  !
  DEALLOCATE( tau, fion )
  !
  outdir = outdir_saved
  !
  IF ( nimage > 1 ) THEN
     !
     ! ... grad_pes is communicated among "image" pools
     !
     CALL mp_sum( grad_pes(:,N_in:N_fin), inter_image_comm )
     !
  END IF
  !
  RETURN  
  !
END SUBROUTINE compute_fes_grads
!
!------------------------------------------------------------------------
SUBROUTINE metadyn()
  !------------------------------------------------------------------------
  !
  USE kinds,              ONLY : DP
  USE constraints_module, ONLY : nconstr, target, lagrange
  USE cell_base,          ONLY : at, alat
  USE cp_main_variables,  ONLY : nfi
  USE control_flags,      ONLY : program_name, nomore, ldamped, tconvthrs, &
                                 trane, ampre, nbeg, tfor, taurdr, ndr
  USE cg_module,          ONLY : tcg
  USE ions_base,          ONLY : nat, nsp, ityp, if_pos, &
                                 sort_tau, tau_srt, ind_srt
  USE io_global,          ONLY : stdout
  USE io_files,           ONLY : prefix, iunaxsf, scradir
  USE constants,          ONLY : bohr_radius_angs
  USE coarsegrained_vars, ONLY : max_fe_iter, max_shake_iter, fe_grad, &
                                 new_target, to_target, to_new_target, &
                                 fe_step, dfe_acc, metadyn_history,    &
                                 max_metadyn_iter, A, sigma
  USE coarsegrained_vars, ONLY : allocate_coarsegrained_vars, &
                                 deallocate_coarsegrained_vars
  USE coarsegrained_base, ONLY : add_gaussians
  USE parser,             ONLY : delete_if_present
  USE io_global,          ONLY : ionode
  USE xml_io_base,        ONLY : check_restartfile
  USE basic_algebra_routines
  !
  IMPLICIT NONE
  !
  INTEGER               :: iter
  REAL(DP), ALLOCATABLE :: tau(:,:)
  REAL(DP), ALLOCATABLE :: fion(:,:)
  REAL(DP)              :: etot
  !
  !
  ALLOCATE( tau( 3, nat ), fion( 3, nat ) )
  !
  CALL allocate_coarsegrained_vars( nconstr, max_metadyn_iter )
  !
  IF ( ionode ) THEN
     !
     OPEN( UNIT = iunaxsf, FILE = TRIM( prefix ) // ".axsf", &
           STATUS = "UNKNOWN", ACTION = "WRITE" )
     !
     WRITE( UNIT = iunaxsf, FMT = '(" ANIMSTEPS ",I3)' ) max_metadyn_iter
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
     OPEN( UNIT = 999, FILE = TRIM( prefix ) // '.metadyn', STATUS = 'NEW' )
     !
     WRITE( 999, '(2(2X,I5))' ) nconstr, max_metadyn_iter
     WRITE( 999, '(2(2X,F12.8))' ) A, sigma
     !
  END IF
  !
  ! ... first the wfc are taken to the ground state
  !
  taurdr = .TRUE.
  nfi    = 0
  tfor   = .FALSE.
  !
  IF ( check_restartfile( scradir, ndr ) ) THEN
     !
     WRITE( stdout, '(/,2X,"restarting calling readfile",/)' )
     !
     nbeg   = 0
     nomore = 100
     !
  ELSE
     !
     WRITE( stdout, '(/,2X,"restarting from scratch",/)' )
     !
     nbeg   = -1
     nomore = 500
     trane  = .TRUE.
     ampre  = 0.02D0
     !
  END IF
  !
  CALL init_run()
  !
  CALL cprmain( tau, fion, etot )
  !
  tfor = .TRUE.
  !
  DO iter = 1, max_metadyn_iter
     !
     metadyn_history(:,iter) = target(:)
     !
     IF ( ionode ) CALL write_config( iter )
     !
     nfi    = 0
     nomore = max_fe_iter
     !
     tconvthrs%active = .TRUE.
     !
     to_new_target = .FALSE.
     !
     CALL cprmain( tau, fion, etot )
     !
     ! ... the averages are computed here
     !
     IF ( ldamped ) THEN
        !
        ! ... zero temperature
        !
        fe_grad(:) = - lagrange(:)
        !
     ELSE
        !
        ! ... finite temperature
        !
        fe_grad(:) = dfe_acc(:) / DBLE( nomore )
        !
     END IF
     !
     IF ( ionode ) &
        WRITE( 999, '(I4,5(2X,F12.8))' ) iter, target(:), etot, fe_grad(:)
     !
     CALL add_gaussians( iter )
     !
     new_target(:) = target(:) - fe_step * fe_grad(:) / norm( fe_grad )
     !
     ! ... the system is "adiabatically" moved to the new target
     !
     to_target(:) = new_target(:) - target(:)
     !
     nfi    = 0
     nomore = max_shake_iter
     !
     tconvthrs%active = .FALSE.
     !
     to_new_target = .TRUE.
     !
     CALL cprmain( tau, fion, etot )
     !
     IF ( ionode ) CALL flush_unit( 999 )
     !
  END DO
  !
  IF ( ionode ) THEN
     !
     CALL write_config( iter )
     !
     CLOSE( UNIT = iunaxsf )
     CLOSE( UNIT = 999 )
     !
  END IF
  !
  DEALLOCATE( tau, fion )
  !
  CALL deallocate_coarsegrained_vars()
  !
  RETURN
  !
END SUBROUTINE metadyn
!
!----------------------------------------------------------------------------
SUBROUTINE write_config( image )
  !----------------------------------------------------------------------------
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
  WRITE( UNIT = iunaxsf, FMT = '(" PRIMCOORD ",I3)' ) image
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
END SUBROUTINE write_config
