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
                                 max_shake_iter, max_fe_iter, num_acc, &
                                 fe_grad_thr, to_new_target
  USE path_variables,     ONLY : pos, pes, grad_pes, frozen, &
                                 num_of_images, istep_path, suspended_image
  USE constraints_module, ONLY : lagrange, target, init_constraint, &
                                 deallocate_constraint
  USE cell_base,          ONLY : alat, at, bg
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
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)         :: N_in, N_fin
  LOGICAL, INTENT(OUT)        :: stat
  INTEGER                     :: image, iter, counter
  CHARACTER (LEN=256)         :: outdir_saved, filename
  LOGICAL                     :: file_exists, opnd, tstop
  REAL (KIND=DP)              :: tcpu
  REAL (KIND=DP), ALLOCATABLE :: tau(:,:)
  REAL (KIND=DP), ALLOCATABLE :: fion(:,:)
  REAL (KIND=DP)              :: etot
  REAL (KIND=DP), EXTERNAL    :: get_clock
  !
  !
  ALLOCATE( tau( 3, nat ), fion( 3, nat ) )
  !
  CALL flush_unit( iunpath )
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
  outdir_saved = outdir
  !
  ! ... vectors pes and grad_pes are initalized to zero for all images on
  ! ... all nodes: this is needed for the final mp_sum()
  !
  IF ( my_image_id == root ) THEN
     !
     FORALL( image = N_in : N_fin, .NOT. frozen(image)   )
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
  IF ( meta_ionode ) CALL new_image_init()
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
           dfe_acc(:,:) = 0.D0
           !
           OPEN( UNIT = 1000, FILE = filename )
           !
           READ( 1000, * ) tau
           READ( 1000, * ) dfe_acc(:,2:num_acc)
           READ( 1000, * ) counter
           !
           CLOSE( UNIT = 1000 )
           !
           counter = MIN( counter + 1, num_acc )
           !
        ELSE
           !
           dfe_acc(:,:) = 0.D0
           !
           counter = 1
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
        CALL cprmain( tau, fion, etot )
        !
        ! ... the new value of the order-parameter is set here
        !
        CALL init_constraint( nat, tau, alat, ityp )
        !
        new_target(:) = pos(:,image)
        !
        ! ... initialization of the CP-dynamics
        !
        CALL init_run()
        !
        ! ... first the system is "adiabatically" moved to the new target
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
        ! ... then the free energy gradients are computed
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
           dfe_acc(:,1) = dfe_acc(:,1) / DBLE( nomore )
           !
           grad_pes(:,image) = 0.D0
           !
           DO iter = 1, counter
              !
              grad_pes(:,image) = grad_pes(:,image) + dfe_acc(:,iter)
              !
           END DO
           !
           grad_pes(:,image) = grad_pes(:,image) / DBLE( counter )
           !
        END IF
        !
        CALL write_config( image )
        !
        ! ... the restart file is written here
        !
        OPEN( UNIT = 1000, FILE = filename )
        !
        WRITE( 1000, * ) tau
        WRITE( 1000, * ) dfe_acc(:,1:num_acc-1)
        WRITE( 1000, * ) counter
        !
        CLOSE( UNIT = 1000 )
        !
     END IF
     !
     ! ... the new image is obtained (by ionode only)
     !
     CALL get_new_image( image )
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
  CONTAINS
     !
     ! ... internal procedures
     !
     !-----------------------------------------------------------------------
     SUBROUTINE new_image_init()
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine initializes the file needed for the 
       ! ... parallelization among images
       !
       USE io_files,       ONLY : iunnewimage
       USE path_variables, ONLY : tune_load_balance
       !
       IMPLICIT NONE       
       !
       IF ( nimage == 1 .OR. .NOT. tune_load_balance ) RETURN
       !
       OPEN( UNIT = iunnewimage, FILE = TRIM( outdir_saved ) // &
           & TRIM( prefix ) // '.newimage' , STATUS = 'UNKNOWN' )
       !
       WRITE( iunnewimage, * ) N_in + nimage
       ! 
       CLOSE( UNIT = iunnewimage, STATUS = 'KEEP' )       
       !
       RETURN
       !
     END SUBROUTINE new_image_init
     !
     !-----------------------------------------------------------------------
     SUBROUTINE get_new_image( image )
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine is used to get the new image to work on
       ! ... the "prefix.BLOCK" file is needed to avoid (when present) that 
       ! ... other jobs try to read/write on file "prefix.newimage" 
       !
       USE io_files,       ONLY : iunnewimage, iunblock
       USE io_global,      ONLY : ionode
       USE path_variables, ONLY : tune_load_balance
       !
       IMPLICIT NONE
       !
       INTEGER, INTENT(INOUT) :: image
       INTEGER                :: ioerr
       CHARACTER (LEN=256)    :: filename
       LOGICAL                :: opened, exists
       !
       !
       IF ( .NOT. ionode ) RETURN
       !
       IF ( nimage > 1 ) THEN
          !
          IF ( tune_load_balance ) THEN
             !
             filename = TRIM( outdir_saved ) // TRIM( prefix ) // '.BLOCK'
             !
             open_loop: DO
                !          
                OPEN( UNIT = iunblock, FILE = TRIM( filename ), &
                    & IOSTAT = ioerr, STATUS = 'NEW' )
                !
                IF ( ioerr > 0 ) CYCLE open_loop
                !
                INQUIRE( UNIT = iunnewimage, OPENED = opened )
                !
                IF ( .NOT. opened ) THEN
                   !
                   OPEN( UNIT = iunnewimage, FILE = TRIM( outdir_saved ) // &
                       & TRIM( prefix ) // '.newimage' , STATUS = 'OLD' )
                   !
                   READ( iunnewimage, * ) image
                   !
                   CLOSE( UNIT = iunnewimage, STATUS = 'DELETE' )
                   !
                   OPEN( UNIT = iunnewimage, FILE = TRIM( outdir_saved ) // &
                       & TRIM( prefix ) // '.newimage' , STATUS = 'NEW' )
                   !
                   WRITE( iunnewimage, * ) image + 1
                   ! 
                   CLOSE( UNIT = iunnewimage, STATUS = 'KEEP' )
                   !
                   EXIT open_loop
                   !
                END IF
                !
             END DO open_loop
             !
             CLOSE( UNIT = iunblock, STATUS = 'DELETE' )
             !
          ELSE
             !
             image = image + nimage
             !
          END IF
          !
       ELSE
          !
          image = image + 1
          !
       END IF      
       !
       RETURN
       !
     END SUBROUTINE get_new_image
     !
     !-----------------------------------------------------------------------
     SUBROUTINE stop_other_images()
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine is used to send a stop signal to other images
       ! ... this is done by creating the exit_file on the working directory
       !
       USE io_files,  ONLY : iunexit, exit_file
       USE io_global, ONLY : ionode
       !
       IMPLICIT NONE
       !
       !
       IF ( .NOT. ionode ) RETURN
       !
       OPEN( UNIT = iunexit, FILE = TRIM( exit_file ) )
       CLOSE( UNIT = iunexit, STATUS = 'KEEP' )               
       !
       RETURN       
       !
     END SUBROUTINE stop_other_images
     !
END SUBROUTINE compute_fes_grads
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
